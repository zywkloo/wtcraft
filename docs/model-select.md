# `wtcraft model-select` — Role-to-CLI Routing Command

> Status: spec — implementation planned for a follow-up PR after role-models v2 lands.

## What It Is

A CLI command that turns `.agent-harness/role-models.yml` from documentation into an executable contract. Given a role and the CLIs available on this machine, it answers: **"which CLI and model should this role use right now?"**

```bash
wtcraft model-select --role executor --available-cli "claude,gemini"
# codex unavailable → falls back in order → prints:
# claude "Claude Sonnet 5"
```

## Why (the three levels)

| Level | What it is | Status |
|---|---|---|
| 1 — Doc contract | Agents read role-models.yml and self-select | Works today |
| 2 — CLI tool | `wtcraft model-select` resolves routing programmatically | **This spec** |
| 3 — Orchestrator | Auto-routes tasks to CLIs via headless calls | Phase 5 (roadmap) |

Level 2 is the function Level 3 will call, exposed as a CLI first. Headless invocation of agent CLIs is already possible (`claude -p`, `codex exec`, etc.), so an orchestrator can compose `model-select` output directly into a dispatch call.

## Behavior

1. Parse `.agent-harness/role-models.yml` (flat schema — one `key: value` per field)
2. Take the role's `cli` as primary choice; if unavailable, walk `fallback` left to right
3. Apply matching rules from the `matching:` block:
   - **fuzzy**: normalize spaces/dashes/underscores/case before comparing model names
   - **freshness_tolerance**: within a model family, a version within the tolerance
     of the requested one counts as a hit (4.8 requested → 4.7 hits at 0.2 tolerance)
4. Print `cli "Model Name"` — or exit non-zero if nothing is available

`--available-cli` may be omitted; then availability = `command -v claude/codex/gemini`.

## Subscription Reality

Most solo-dev users run subscription CLIs (Claude Pro, ChatGPT Plus), not API keys. Subscriptions cannot be programmatically queried for quota and offer limited model switching. Therefore:

- **`cli` is the routing key** — what binary gets invoked
- **`model` is a hint** — honored when the CLI supports `--model` / API keys; otherwise ignored

## Quota-Aware Recommendation (recommended next step)

> Added 2026-06-10. The earlier premise "quota-aware routing is out of scope
> until providers expose usage APIs" no longer holds: tools like
> [ccusage](https://github.com/ryoppippi/ccusage) and
> [tokscale](https://github.com/junhoyeo/tokscale) compute remaining
> subscription-window usage from **local CLI session logs** — no provider API
> needed. tokscale covers multiple CLIs (Claude Code, Codex, Gemini, …),
> matching the solo-dev reality of 1–3 parallel subscriptions.

The target behavior: **wtcraft recommends which CLI/model the next task should
use, based on role, stage, and remaining token quota.**

```bash
wtcraft model-select --role executor
# codex (GPT-5.5) — claude window 87% used, codex 12% used
```

Resolution order:

1. Resolve role → `cli` + `fallback` chain from role-models.yml (unchanged)
2. For each candidate CLI, query remaining quota in the current subscription
   window by shelling out to a usage tool's JSON output
   (`ccusage blocks --json` / tokscale equivalent)
3. Walk the chain left to right; recommend the first CLI whose window has
   headroom above a configurable threshold
4. Usage tools are an **optional dependency**: when none is detected, degrade
   to availability-only routing (current spec behavior) — never block

Stage is already encoded in the role (planner/executor/verifier/finisher), so
no separate stage input is needed; the orchestrator calls `model-select` with
the role for the upcoming stage.

This stays consistent with the budget decoupling rule below: quota enters
`model-select` as an input (the `--budget-state` mechanism), not by merging
the commands.

## Scope Boundary with `wtcraft budget` (PR #12)

These two features are complementary and must stay decoupled:

| | `model-select` | `budget` |
|---|---|---|
| When | **Before** execution | **After** execution |
| Question | "which CLI/model should run this role?" | "what did the session cost?" |
| Input | role-models.yml + CLI availability | local session logs |
| Depends on headless calls? | No (Level 3 does) | No — log parsing works for interactive and headless sessions alike |

**Integration rule**: budget's "model recommendation" events should *call* `model-select`, not implement their own recommendation logic. One routing brain, one measurement brain.

A future feedback loop (budget data influencing routing, e.g. "burn rate high → prefer cheaper fallback") would connect them — but via `model-select` gaining a `--budget-state` input, not by merging the two commands.

## Implementation Notes

- The flat role-models.yml schema is deliberately one-line-per-field so the existing
  awk patterns in `scripts/wtcraft` (`extract_frontmatter` style) can parse it —
  no new runtime dependency required for a bash implementation
- If the Rust migration (see `docs/rust-migration.md`) proceeds, `model-select` is
  the natural first candidate: pure function, easily unit-tested, no git side effects
