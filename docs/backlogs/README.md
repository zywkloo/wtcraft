# Backlogs

Working memos — smaller and more volatile than `../roadmap.md` (the phased
product plan). One file per theme. Items here are either not yet scheduled,
external things to watch, or explicit "decided not to do" records so the
reasoning isn't re-derived later.

Last reviewed: 2026-06-10.

## Focus — the three things that matter (2026-06-10)

All rule + config. No ML, no server, truth in local files/logs.

1. **Loop visibility — "where am I?"** → [stage-state-machine.md](stage-state-machine.md).
   Build: `stage:` field + handoff convention + `status` stage column. ~0.5–1 day.
2. **Realtime token view** → adopt, don't build: `ccusage blocks --live` /
   tokscale ([external-watchlist.md](external-watchlist.md)). Zero build today;
   a token column in `wtcraft status` is optional later polish.
3. **Model recommendation — "next stage, use X"** → [model-select-quota.md](model-select-quota.md),
   on top of role-models.yml + presets ([preset-codegen.md](preset-codegen.md), PR #22).
   Build: ~2–3 days.

## Queue (Priorities)

The single ordered work queue. When picking up wtcraft work, start at the top.
Narrative/rationale lives in the per-item memos.

| # | Item | Memo | Estimate | Why this position |
|---|------|------|----------|-------------------|
| P0 | Finish PR #22 — presets + gen-presets.py | [preset-codegen.md](preset-codegen.md) | already in progress | In flight on `feat/role-models-v2-codegen`; config base that P2 depends on; also fixes the dangling `presets/` reference in role-models.yml |
| P1 | Pivot to Governance Layer | [pivot-governance-layer.md](pivot-governance-layer.md) | 2–3 days | The new core identity of wtcraft. Replacing agent orchestration with strict Zero-Trust Worktree Containment and Budget Gating. |
| P2 | Stage state machine + progress view | [stage-state-machine.md](stage-state-machine.md) | 0.5–1 day (+0.5 for `--json`) | Smallest build with daily payoff; parts already landed 2026-06-10 (`set_frontmatter`, verify write-back, re-plan checkpoint) |
| P3 | Quota-aware model-select | [model-select-quota.md](model-select-quota.md) | 2–3 days | The differentiated kernel (no competitor serves subscription-CLI users); needs P0's config base |
| P4 | bats tests for awk parsing | — | ~1 day | Insurance for the 5 fragile parse functions; do opportunistically or when parsing next breaks |
| P5 | Subscription fit report in `wtcraft budget` | [subscription-fit.md](subscription-fit.md) | ~1 day | Slow-loop advice (monthly); wait until P3 proves the quota data path |
| P6 | Expose check/verify/status as MCP server | — | unsized | Trend-aligned composability; revisit after P2–P3 are in daily use |

## No work needed (adopt today)

- Realtime token view: `npx ccusage@latest blocks --live` (5h-window dashboard)
  and/or `npx tokscale@latest` (cross-CLI totals). See
  [external-watchlist.md](external-watchlist.md).

## Re-prioritize when

- PR #22 merges → P1 becomes the active item
- A usage tool changes its JSON output → check P3's parser assumptions
- tokscale merges Antigravity CLI support (PR #703) → consider Antigravity as
  a model-select candidate CLI
- Anyone shows up wanting Windows or Rust → see deferred section in
  `README.md` and `../rust-migration.md`
Competitive note (2026-06-10): item 1 is the *least* differentiated — Vibe
Kanban already ships kanban stages, per-task agent/model selection, and
plan-approval gates in a polished UI. (Maker Bloop AI shut down 2026-04-10 —
"thousands of daily users, vast majority free, no business model" — project
now Apache 2.0 community-maintained, migrating to fully-local architecture.
Confirms: this space doesn't fund companies, and local/files-first is where
even the funded player ended up.) Item 3 is the *most* differentiated:
quota-aware routing exists only in API-gateway form (Zuplo, Bifrost, Portkey —
API keys, proxies, pay-as-you-go); nobody serves subscription-CLI users from
local logs. wtcraft's durable edge is truth-in-git-files (greppable,
SSH-able, UI-agnostic) + contract gates (check/verify) + the replan loopback
having real control-flow semantics, not kanban swimlanes. Hence: keep
visualization minimal (`status` + `--json` for any external UI), invest in
the contract + quota kernel.

## Index

- [preset-codegen.md](preset-codegen.md) — preset system + gen-presets.py design decisions (PR #22 in progress)
- [pivot-governance-layer.md](pivot-governance-layer.md) — Zero-Trust containment & governance (new P1)
- [stage-state-machine.md](stage-state-machine.md) — `stage:` lifecycle in task
  frontmatter + unified progress view; pragmatic v1 of roadmap Phase 5
- [model-select-quota.md](model-select-quota.md) — quota-aware model
  recommendation: "for the next executor task, use X" (next up; the main
  candidate for new work)
- [subscription-fit.md](subscription-fit.md) — personal, rule-based "is my
  plan paying for itself" report (idea)
- [external-watchlist.md](external-watchlist.md) — upstream projects to watch
  or contribute to (tokscale, usage tooling)
- [not-doing.md](not-doing.md) — rejected directions, with reasons

## Deferred (open to contributors)

- **Rust migration** — not rejected, just not now; a contributor with interest
  is welcome to pick it up. Premises, scope, and the recommended starting
  module (model_policy: pure functions, zero IO) are documented in
  `../rust-migration.md`.

## Pending items from the roadmap

Tracked in `../roadmap.md`, not duplicated here:

- Phase 4 integrations (workmux session orchestration, PR template generation,
  dashboard-style status output)
- Phase 5 layered multi-agent orchestration (v0.4.0): orchestrator guides,
  dual-tier commands, context-gathering pipings, token telemetry

## Done recently (2026-06-10)

- `verify` writes `verify_result` / `verified` back into task frontmatter;
  `status` shows a Verified column (machine-verified state, not agent-claimed).
- `check` covers uncommitted edits and untracked files; `.worktree-task.md`
  itself is exempt (harness-managed).
- Finisher re-plan checkpoint: after verify/check pass and before push/PR, the
  agent must challenge task premises (boundary, Scope/Off-limits, Context
  contradictions) and get user confirmation. See `.agent-harness/finisher.md`.
- `docs/rust-migration.md` moved to deferred with full rationale.
- `docs/model-select.md` gained the Quota-Aware Recommendation section.
