# Backlog priorities

The single ordered work queue. When picking up wtcraft work, start at the top.
Narrative/rationale lives in `README.md` (Focus) and the per-item memos.

Last reviewed: 2026-06-10.

## Queue

| # | Item | Memo | Estimate | Why this position |
|---|------|------|----------|-------------------|
| P0 | Finish PR #22 — presets + gen-presets.py | [preset-codegen.md](preset-codegen.md) | already in progress | In flight on `feat/role-models-v2-codegen`; config base that P2 depends on; also fixes the dangling `presets/` reference in role-models.yml |
| P1 | Stage state machine + progress view | [stage-state-machine.md](stage-state-machine.md) | 0.5–1 day (+0.5 for `--json`) | Smallest build with daily payoff; parts already landed 2026-06-10 (`set_frontmatter`, verify write-back, re-plan checkpoint) |
| P2 | Quota-aware model-select | [model-select-quota.md](model-select-quota.md) | 2–3 days | The differentiated kernel (no competitor serves subscription-CLI users); needs P0's config base |
| P3 | bats tests for awk parsing | — | ~1 day | Insurance for the 5 fragile parse functions; do opportunistically or when parsing next breaks |
| P4 | Subscription fit report in `wtcraft budget` | [subscription-fit.md](subscription-fit.md) | ~1 day | Slow-loop advice (monthly); wait until P2 proves the quota data path |
| P5 | Expose check/verify/status as MCP server | — | unsized | Trend-aligned composability; revisit after P1–P2 are in daily use |

## No work needed (adopt today)

- Realtime token view: `npx ccusage@latest blocks --live` (5h-window dashboard)
  and/or `npx tokscale@latest` (cross-CLI totals). See
  [external-watchlist.md](external-watchlist.md).

## Re-prioritize when

- PR #22 merges → P1 becomes the active item
- A usage tool changes its JSON output → check P2's parser assumptions
- tokscale merges Antigravity CLI support (PR #703) → consider Antigravity as
  a model-select candidate CLI
- Anyone shows up wanting Windows or Rust → see deferred section in
  `README.md` and `../rust-migration.md`
