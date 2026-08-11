# Stage state machine + unified progress view

> Canonical lifecycle contract:
> [Task State Machine v1](../protocol/task-state-machine-v1.md). This backlog
> retains observer design notes and future enforcement work.

> Status: not scheduled. Recorded 2026-06-10. This is the pragmatic v1 of
> roadmap Phase 5's team architecture — human as orchestrator, files as truth.

## Goal

Make the role pipeline observable and resumable:

```
Orchestrator → Planner → Executor → [human: push/PR] → Verifier
     ▲                                                     │
     └────────────── re-plan loopback ──── [human: approve OR retry]
                                                           │
                                                           ▼ (approved)
                                                       Finisher
```

One unified progress view answers "which step is every task at" — regardless
of which terminal/multiplexer hosts the agents.

## Division of labor (the key decision)

- **wtcraft owns the loop state.** Truth lives in `.worktree-task.md`
  frontmatter, not in any window manager. The progress UI reads files.
- **workmux (or Zellij/WezTerm/plain tabs) hosts the agents.** Per-pane
  status icons (working/waiting/done), different CLI per role, prompt
  injection. It has no stage concept and never needs one.

This keeps the multiplexer swappable and the progress view working even with
no multiplexer at all.

## What's missing (the actual work)

1. **`stage:` frontmatter field** with the lifecycle:
   `planned → executing → verifying → replan | approved → finishing → done`.
   `set_frontmatter` already exists (added 2026-06-10) — writing the field is
   trivial; the work is the convention.
2. **Handoff convention in role docs** — each `.agent-harness/*.md` role doc
   instructs the agent to update `stage` when taking over / handing off.
   Verifier on fail writes `stage: replan` (the loopback signal Planner picks
   up).
3. **`wtcraft status` stage column** — plus the dashboard story:
   `watch -n5 wtcraft status` in one pane is the unified progress bar.
   A dedicated `--watch` flag is optional polish.
4. **`wtcraft status --json`** — machine-readable state so any external UI
   (TUI, web page, even a Vibe-Kanban-style board) can render the pipeline
   without wtcraft owning a frontend. Turns truth-in-files into composability;
   ~0.5 day extra.
5. **`role:` frontmatter field** — `agent:` records which CLI; `role:`
   records the pipeline role (planner/executor/verifier/finisher). Lets
   `status` and any UI join `role-models.yml`: show the expected cli/model/
   fallback for the role, and flag mismatches ("task declares verifier but
   agent is gemini; config routes verifier to claude"). One field buys a
   whole class of checks.

Estimated ~0.5–1 day total. Template + live file pairs must stay in sync
(CLAUDE.md rule).

> **Shipped 2026-06-12** (all five items): `.agent-harness/task-states.md`
> (lifecycle + transition table + single-writer rule), Stage Handoff
> sections in role docs, `stage:`/`role:` in the task template with
> `cmd_new` backfill, Stage/Role columns in `wtcraft status` (legacy
> `status:` fallback), and `wtcraft status --json`. Enumeration is
> layout-agnostic (worktree-layout.md step 1) — `uncontracted` and
> `zombie` worktrees are surfaced. Alarm *evaluation* (illegal-transition,
> bypass, stale…) remains future work for `check`/observer.

## Declared vs actual (observer design, recorded 2026-06-11)

Frontmatter is *declared* state only — an agent that crashes after writing
`stage: executing` leaves a stale claim behind; the file never corrects
itself. So the monitor's job is not rendering `.worktree-task.md`, it is
reconciling three independent signal sources:

| source              | tells you                                          |
|---------------------|----------------------------------------------------|
| `.worktree-task.md` | declared stage, role, Scope, Off-limits            |
| git                 | actual changes: diff vs Scope/Off-limits, commits (`wtcraft check` today) |
| fs mtime / heartbeat| liveness: is anything moving in that worktree      |

All three agree = green. Disagreements get names. Catalog principle
(recorded 2026-06-12): **every alarm must cite the declared rule it
violates** (TASK.md section, transition table, role-models.yml, ADR) —
no rule, no alarm. This is the line between contract checking and the
git-generic heuristics a GUI can compute on its own. Severity: violation
(red) / warning (yellow) / info (grey).

### Contract vs git facts (core governance)

| alarm | trigger | rule | status |
|---|---|---|---|
| **breach** (red) | diff touches Off-limits files | TASK.md `## Off-limits` | ✅ `check` |
| **scope-creep** (yellow) | changes outside Scope list | TASK.md `## Scope` | ✅ `check` |
| **bypass** (yellow) | declared pre-execution stage, but uncommitted changes exist | transition table | needs table |
| **uncontracted** (yellow) | worktree exists with no task file (agent-created wild worktree) | work-needs-a-contract principle | needs `worktree-layout.md` step 1 |
| **contract-tracked** (red) | `.worktree-task.md` added/committed | ADR-001 | ✅ `check` |
| **contract-tampered** (red) | live Scope/Off-limits differ from plan-time snapshot | snapshot (see integrity section) | needs snapshot |

### Contract vs lifecycle (FSM)

| alarm | trigger | rule | status |
|---|---|---|---|
| **illegal-transition** (red) | stage jumped a transition not in the table (e.g. ready → done without verify) | transition table | needs table |
| **stale** (yellow) | declared `executing`, no mtime activity for N minutes | liveness convention | mtime only |
| **rotting** (info) | `created:` old and never reached done | task freshness | free |
| **verification-unproven** (red) | declared done/needs_review but `verify_result` missing or failed | TASK.md `## Verification` | nearly free (`verify` writes back) |

### Contract vs config (role-models.yml)

| alarm | trigger | rule |
|---|---|---|
| **role-mismatch** (yellow) | `role:`'s expected cli ≠ `agent:`, and agent not in the fallback chain either | role routing + fuzzy matching rules |
| **model-drift** (info) | model in use outside `freshness_tolerance` | model is "hint only" per the yml — inform, never alarm |

### Contract self-consistency (free)

- **malformed-contract** (yellow) — missing required frontmatter keys /
  unparseable
- **branch-mismatch** (yellow) — frontmatter `branch:` ≠ actually
  checked-out branch
- **zombie** (info) — `prunable` flag from `git worktree list --porcelain`

Note the dependency concentration: half the catalog hangs on the
transition table (item 2 above) — it is the first domino.

A borderline case kept in scope: detecting that the declared `base:`
branch has moved / would conflict IS contract checking (the field is
declared); only the resolve actions (rebase/merge buttons) are
runner/Git-client territory — and the SourceGit fork host provides those
for free anyway.

## State file concurrency & integrity (recorded 2026-06-12)

Sharding is the design: each task file is written only by actors inside
its own worktree — no global hot file, no cross-worktree contention.
Centralizing files would not remove any race (races are per-file).
Remaining risks and their resolutions:

1. **Torn reads** (reader sees a half-written file): all writers follow
   write-temp-then-`mv` (atomic rename); readers parse tolerantly
   (failure = no metadata, self-heals next poll). Add the convention to
   each `.agent-harness/*.md` role doc.
2. **Lost updates** (hook vs agent whole-file rewrite): resolved by
   channel separation — liveness is mtime, not a file field (vendor-free
   principle), and `verify_result` may move to a sidecar file if it ever
   contends. Deeper: **the transition table doubles as the concurrency
   protocol** — each stage names exactly one owning role, so TASK.md has
   a single legal writer at any moment. No locks needed (single user,
   minute-scale write intervals; flock is YAGNI).
3. **Contract integrity — the real hole**: the contract lives in the
   sandbox of the party it constrains; an agent can rewrite its own
   Scope/Off-limits to legitimize a breach and `check` would pass.
   Fix: at `wtcraft new`, snapshot the contract to
   `.git/wtcraft/<branch>/contract.snapshot` (`.git` is the natural
   out-of-tree, untracked, per-repo anchor — git itself keeps worktree
   metadata there). `check` diffs live Scope/Off-limits against the
   snapshot → **contract-tampered**. Legitimate scope changes go through
   the planner reissuing the snapshot.
4. **Audit survival**: state dies with the worktree by design; the
   finisher archives the final task file (`.git/wtcraft/archive/` or
   simply the PR body) before removal. Archive, don't centralize.

**Rejected: central `wtFSMs/` hub + per-worktree symlinks.** Agent
sandboxes restrict writes by path — a symlink escaping the worktree root
breaks the agent's own status updates; Windows symlinks need elevated
privileges (fork targets all three platforms); editors' temp+rename
severs hardlinks; and same-OS-user means no real write isolation without
a broker CLI, which would break the agents-edit-files workflow. The only
real benefit (state survives worktree deletion) is had cheaper via
archive-on-finish.

Liveness should not depend on agents dutifully updating fields (they won't).

**Vendor-dependency principle (decided 2026-06-11):** defer anything that
depends on vendor surfaces (Claude Code hooks, Codex `notify`, TUI output
formats — they churn at vendor release pace and break silently, and any
per-CLI adapter list is closed by construction). Build on vendor-free
signals first:

- Liveness v1 = **fs mtime** of the worktree (POSIX-stable, works for any
  agent, any runner, zero setup). Minute-granularity is enough for
  task-level monitoring.
- CLI event hooks (Claude Code hooks / Codex notify writing `last_active:`
  or stage into the task file) are a **deferred precision upgrade** — and
  when added, they write through the same file interface, so the observer
  never depends on them. If a hook breaks, `last_active` goes stale and
  the stale alarm fires: the failure is visible and named, not silent.

Any GUI stays a thin renderer over `wtcraft status --json`. The design stance
is state-in-repo (files as truth) rather than state-in-app, and a read-only
*observer* rather than an agent *runner* — so it composes with any runner
instead of replacing one.

Items 4 (`--json`) and 5 (`role:`) above are the wtcraft-side dependencies any
such GUI needs.

## Already in place (as of 2026-06-10)

- `verify_result` / `verified` written back by `wtcraft verify`; Verified
  column in `status`
- Finisher re-plan checkpoint = the human approve/retry gate before push/PR
  (`.agent-harness/finisher.md`)
- `check` covers uncommitted/untracked files, so stage transitions can't hide
  out-of-scope work

## Human gates

The two `[human]` nodes stay manual on purpose (bounded automation over
opaque autonomy, per roadmap design constraints). In a multiplexer they
surface as panes in "waiting" state; in the progress view as tasks parked at
`verifying`/`replan`.

## Out of scope for v1

- Automated Orchestrator agent (spawning panes, dispatching subtasks,
  cross-repo coordination) — that's the full roadmap Phase 5
- Token telemetry in the progress view — feed from an external usage tool
  (ccusage/tokscale) later

## Related

- [../model-select.md](../model-select.md) — at each stage handoff, the
  orchestrator (human or agent) asks model-select which CLI/model the next
  role should use
- Roadmap Phase 4 lists session orchestration and dashboard-style status
  output as intended integrations — this memo is the concrete shape
