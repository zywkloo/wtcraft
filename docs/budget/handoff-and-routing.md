# Handoff & Routing — Forward-Looking Design Notes

> Status: **planning, layered on top of the current implementation.**
> The cost-observability layer is already implemented (see
> [`budget.md`](budget.md) for the spec and the existing `wtcraft cost`
> command). This doc captures the **next-layer** design decisions that
> emerged after that implementation landed: a vendor-agnostic baseline
> for usage reporting, and an explicit handoff/routing state machine
> on top of the existing tracker.

> ⚠️ **Maintenance required.** This doc contains concrete model identifiers
> (e.g. `claude-opus-4-7`, `codex-gpt-5.3`, `gemini-3.5-flash`) in the D5
> routing example. **Model names and tier mappings rot fast** — new variants
> ship every few months, old ones get renamed or retired. Any time you read
> this doc more than ~90 days after the last commit, **assume the example
> values are stale** and verify against current vendor naming before copying
> them into a contract. The long-term fix is the alias-resolution scheme
> proposed in D5 and tracked in the model-identifier Investigation TODO.

## Why a second doc

The current implementation (per [`budget.md`](budget.md)) answers
**"how much did this session cost?"** by parsing local CLI session logs
(`~/.claude/projects/`, Codex chat history, etc.). That works today and
gives users the dashboard they need.

This doc covers two things `budget.md` does not:

1. **Vendor-agnostic fallback** for agents whose log format breaks
   (vendor updates) or is unsupported (new agents).
2. **Handoff routing** based on remaining quota — moving from passive
   accounting to active orchestration that knows which agent to send
   the next task to when the preferred one is exhausted.

Both extend, not replace, what is already shipped.

## Decisions

Settled enough to implement against. Revisit with new evidence.

### D1 — Skill is the universal contract, log-parsing is one (preferred) implementation

Every agent emits one line at the end of a session in a fixed format:

```
WTCRAFT_USAGE_REPORT: tokens=<int>, model=<string>, source=<runtime|self_report|unavailable>
```

- `source=runtime` — extracted from a structured vendor stream
  (e.g. `codex exec --json`) or from local log parsing (the current
  `wtcraft cost` path). Highest confidence.
- `source=self_report` — agent introspected via `/usage`, `/status`, or
  equivalent and reported. Estimate; may drift.
- `source=unavailable` — agent could not get an authoritative number.
  **Must not fabricate.** Wtcraft treats this by falling back to
  wall-clock + handoff-count heuristics.

This means the existing `_budget.py` log-parsing path becomes "the
default `runtime` source for Claude / Codex / Gemini today," and the
skill is the cross-vendor protocol that future agents can satisfy
without wtcraft having to learn their log format.

### D2 — Vendor log formats and JSON streams are opt-in adapters

`codex exec --json` is one OpenAI release away from schema change.
`~/.claude/projects/*.jsonl` is one Anthropic release away from rename.
The current `wtcraft cost` implementation handles both — but should
treat them as **adapters that can fail**, not as core protocol.

```text
adapter chain (per agent, tried in order):
  1. vendor JSON stream     → source=runtime    (best precision)
  2. local log file parser  → source=runtime    (today's default for Claude/Codex)
  3. skill self-report      → source=self_report (universal fallback)
  4. wall-clock heuristic   → source=unavailable (last resort, log-only)
```

Adapters fail silently and degrade down the chain. The `WTCRAFT_USAGE_REPORT`
contract is what the rest of wtcraft consumes regardless of which adapter
produced it.

### D3 — Activation scope is the worktree boundary

Skills emit reports **only when the agent is running inside a
wtcraft-managed worktree.** Detection:

1. `WTCRAFT_WORKTREE` env var (set by `wtcraft handoff` when spawning), OR
2. `.worktree-task.md` exists in `cwd` or any parent

Outside a worktree → no skill report, no contract obligation. Keeps
normal interactive use noise-free. The existing `wtcraft cost` command
is already worktree-scoped via the working directory, so this is just
the symmetric rule for the skill side.

### D4 — `UNKNOWN` is acceptable; fabricated numbers are not

Skill instruction explicitly forbids estimation when no authoritative
source is available. Better to surface the gap than to record a
plausible-looking lie that pollutes the budget log.

### D5 — Roles are preferences with fallback, **at the model level, not the vendor level**

Vendor-name routing (`preferred: claude`) is too coarse to be useful.
Within one vendor family, Haiku / Sonnet / Opus differ by reasoning
depth, throughput, and price by an order of magnitude — putting them
in one bucket throws away the most important routing signal.

Contract frontmatter extends from a fixed role-to-agent map to
**model-level** preference + fallback:

```yaml
roles:
  planner:
    preferred: claude-opus-4-7          # strong reasoning, few calls — premium worth it
    fallback: [gpt-5.5, gemini-3.1-pro]
  executor:
    preferred: codex-gpt-5.3            # main workhorse; JSON event stream eases tracking
    fallback: [claude-sonnet-4-6, gemini-3.5-flash]
  verifier:
    preferred: gemini-3.5-flash         # long-context diff reading, cheapest tier
    fallback: [claude-sonnet-4-6]
  finisher:
    preferred: claude-opus-4-7          # commit message / PR body quality
    fallback: [gpt-5.5]
budget:
  rate_limit_strategy: route_to_available
```

This pattern is intentional: **the priciest model goes where call count
is lowest (planner, finisher); the cheapest model goes where bulk
reading happens (verifier).** Same-vendor fallback is also enabled
(Opus → Sonnet within Claude) — quota-aware routing matters as much
within a family as across families.

When `wtcraft handoff` is about to spawn a role, it checks recent
`wtcraft cost` data and 429 history for the preferred model. If the
model looks exhausted (heuristic: N handoffs within the current quota
window, or last call returned 429), it routes to the next fallback
in order and records the routing decision in the task's
`## Iteration Log`.

This is the real value of budget-aware orchestration over naive
role-bound spawning — and it is the next layer on top of the existing
cost tracker, which only observes, not routes.

**On model-identifier rot — alias resolution proposal.** Pinned ids like
`claude-opus-4-7` get stale within months. The contract should support
aliases the runtime resolves at handoff time:

```yaml
roles:
  planner:
    preferred: claude-opus-latest         # resolves at runtime
    fallback: [gpt-best-reasoning-latest, gemini-pro-latest]
```

`wtcraft` ships an updatable mapping table (e.g. `.wtcraft/models.yaml`,
refreshable via `wtcraft sync-models`) that maps semantic aliases
(`claude-opus-latest`, `*-best-reasoning-*`, `*-cheapest-fast-*`) to the
current canonical model id. Contracts stay readable across model
generations; the registry is the single point of maintenance instead of
every task file. See the model-identifier Investigation TODO below for
the open scoping questions.

### D6 — No daemon, no fs-watch

`wtcraft handoff` is called **explicitly** by the previous agent as its
last action. State transitions happen at handoff time only. Avoids
long-running watchers and makes pauses/interrupts trivial — just don't
call handoff.

The existing `wtcraft cost` already runs on demand; the same model
applies here.

## Relationship to current implementation

| Layer | Status | Owner |
|---|---|---|
| Cost observability (local log parsing) | ✅ shipped | [`budget.md`](budget.md) + `_budget.py` + `wtcraft cost` |
| `WTCRAFT_USAGE_REPORT` contract | 🟡 planned (this doc D1) | TBD — skill template + parser util |
| Skill template (universal fallback) | 🟡 planned (this doc) | TBD |
| Adapter degradation chain | 🟡 planned (this doc D2) | TBD — refactor `_budget.py` per-agent paths into adapters |
| `wtcraft handoff` command | 🟡 planned (this doc) | TBD — net-new command |
| Quota-aware routing | 🟡 planned (this doc D5) | TBD — depends on handoff command + cost data |
| Per-agent quota bucket model | 🔵 investigation | TBD — needs vendor TOS data first |

**Nothing in this doc is meant to remove or rewrite shipped behavior.**
Backward compat for `wtcraft cost` is non-negotiable.

## Investigation TODO

Open questions where actual data is needed before locking in.

- [ ] **Codex `exec --json` schema sample** — capture one full event
      stream against `codex-cli 0.130.0`, document which event types
      carry `token_count` and whether they are cumulative or per-turn.
      Feeds the per-agent adapter design.
- [ ] **Claude `-p` output shape** — does any combination of flags
      (`--debug`, `--verbose`, future additions) expose token counts?
      Likely no. If confirmed, lock in skill-only fallback for the
      Claude `-p` path (separate from the existing log-parsing path
      which is fine).
- [ ] **Gemini / Antigravity CLI status** — name reportedly changed;
      verify the current binary, `exec`-equivalent flag, and any JSON
      output.
- [ ] **Rate-limit windows per subscription tier** — Claude Pro ~5h,
      ChatGPT Plus GPT-4 ~3h, Codex CLI on Plus separate bucket.
      Confirm against current TOS and capture as a reference table in
      this doc.
- [ ] **Quota observation signals** — three known sources: 429
      responses (text varies), TUI display, vendor dashboard. None are
      machine-readable AND stable. Pick which to ingest and how.
- [ ] **`WTCRAFT_USAGE_REPORT` regex spec** — lock the exact regex
      (model-string alphabet, integer bounds, `UNKNOWN` sentinel).
      Publish as a small contract that the skill template references.
- [ ] **Model identifier scheme** — D5 routes at the model level
      (`claude-opus-4-7`, `codex-gpt-5.3`, `gemini-3.5-flash`, …) but
      there is no canonical wtcraft-side mapping from a CLI invocation
      to a model string yet. Open questions: who owns the mapping
      table (per-agent skill? central registry?), how to handle
      version aliases (`claude-opus-latest` → pinned id), how to detect
      and warn when a model name in a contract no longer exists, and
      whether to normalize across vendors (e.g. canonical
      `provider/family/variant/version` quadruple). Until this lands,
      routing examples in D5 are documentation-only.

## Implementation TODO

Suggested order. Skill template comes first because it is the contract
everything else depends on.

- [ ] **Skill templates** — write
      `templates/.claude/skills/usage-report.md` and
      `templates/.codex/skills/usage-report.md` implementing D1/D3/D4.
      Identical text, vendor-agnostic.
- [ ] **`wtcraft init` installs skill templates** — extend init to drop
      the skill into per-agent skills dirs with non-overwrite semantics
      matching the existing `CLAUDE.md` / `AGENTS.md` policy.
- [ ] **`WTCRAFT_USAGE_REPORT` parser util** — shared between
      `wtcraft handoff` and any future `wtcraft budget` upgrade.
- [ ] **`wtcraft handoff` command** — read `.worktree-task.md` state,
      spawn the next agent per `roles.preferred`, inject
      `WTCRAFT_WORKTREE` env, capture stdout, parse the report line,
      append to `.wtcraft/usage.log`.
- [ ] **`.wtcraft/usage.log`** — append-only JSONL: timestamp,
      worktree, agent, role, tokens, source, exit code, wall-clock.
      Sits next to whatever `wtcraft cost` already writes; consider
      unifying schemas in a follow-up.
- [ ] **Adapter degradation chain in `_budget.py`** — factor existing
      Claude/Codex log parsers into named adapters; add the skill
      fallback as the bottom of the chain; surface which adapter was
      used in cost output.
- [ ] **Quota-aware routing** — `wtcraft handoff` consults recent log
      to detect exhaustion of preferred agent, routes to fallback,
      records decision in the task file.
- [ ] **`wtcraft handoff --dry-run`** — print what would happen
      without spawning. Critical for the human-in-loop default.
- [ ] **Default safety** — `wtcraft handoff` is **single-step by
      default**. Full auto requires explicit `--auto` + a `--until`
      stop condition or budget cap.
- [ ] **Tests** — skill output parser fixtures, `UNKNOWN` handling,
      fallback routing, source-tag confidence propagation,
      adapter-chain ordering.

## Open design questions

Explicitly **not yet decided** — need follow-up discussion before
implementation locks in.

- [ ] Should the skill instruct agents to emit a report on **abnormal
      exit** (agent decided to stop mid-task)? If yes, how to detect it
      from the orchestrator side without a wrapper around every CLI?
- [ ] How does wtcraft surface a *"you are about to exhaust Claude Pro"*
      warning to the user mid-session, given no real-time token signal
      for most agents?
- [ ] When a fallback route is taken, should the contract record this
      in the worktree's task file's `## Iteration Log` automatically?
- [ ] If multiple worktrees share the same agent's quota pool, how is
      contention handled — first-come-first-served via the log, or
      explicit reservation?
- [ ] Should the existing `wtcraft cost` and the future
      `.wtcraft/usage.log` schemas be unified, or kept separate for
      backward compat?

## Non-goals

- Real-time token counting during a single handoff (only at completion).
- Per-character billing accuracy (vendor dashboards remain authoritative).
- Replacing vendor rate-limit logic — wtcraft mitigates, vendors enforce.
- Hosted budget service or remote telemetry export.
- Replacing or rewriting the shipped `wtcraft cost` behavior — this doc
  is strictly additive.

## Relationship to existing plans

- [`budget.md`](budget.md) — current implementation spec for cost
  tracking; **prerequisite reading** for this doc.
- [`token-budget.md`](token-budget.md) — market landscape and user
  narratives that justify the budget track overall.
- [`../roadmap.md`](../roadmap.md) — Phase 4 (Integrations & Budget
  Control) houses both `budget.md` and this doc.
- [`../principles.md`](../principles.md) — see
  [`#6 Budget-Aware by Design`](../principles.md#6-budget-aware-by-design).

---

_Living planning doc. Items move from "Open design questions" up into
"Decisions" as they are settled; implementation TODOs become commit
references as they ship._
