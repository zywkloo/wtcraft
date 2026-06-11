# Stage state machine + unified progress view

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

Estimated ~0.5–1 day total. Template + live file pairs must stay in sync
(CLAUDE.md rule).

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
- Token telemetry in the progress view — feed from ccusage/tokscale later;
  see `model-select-quota.md` and `external-watchlist.md`

## Related

- `model-select-quota.md` — at each stage handoff, the orchestrator (human or
  agent) asks model-select which CLI/model the next role should use
- Roadmap Phase 4 lists "workmux session orchestration" and "dashboard-style
  status output" as intended integrations — this memo is the concrete shape
