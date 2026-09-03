# Backlogs

Working memos — smaller and more volatile than `../roadmap.md` (the phased
product plan). One file per theme. Items here are either not yet scheduled,
external things to watch, or explicit "decided not to do" records so the
reasoning isn't re-derived later.

## Index

- [stage-state-machine.md](stage-state-machine.md) — `stage:` lifecycle in task
  frontmatter + unified progress view
- [session-runtime-protocol.md](session-runtime-protocol.md) — GUI/session
  launch contract, machine protocol, and interactive-vs-headless follow-on work
- [worktree-layout.md](worktree-layout.md) — enumerate worktrees via
  `git worktree list` instead of glob; flip default layout to sibling dir
- [quota-aware-task-planning.md](quota-aware-task-planning.md) — classify
  prompts before execution, forecast token/subscription-quota ranges, recommend
  role/model tiers, and calibrate against deterministic verification outcomes
- [agent-capability-eval.md](agent-capability-eval.md) — measure agent task
  outcomes against `check`/`verify` as a deterministic oracle instead of a judge
  model; the harness lives in `wteval`, and wtcraft takes back the contract-arm
  result as Phase 8 evidence. Records why near-term migration semantic eval is
  deferred; the evidence-contract rejection moved to
  [ADR-012](../adr/012-evaluation-evidence-boundary.md).

*(Note: Completed designs, explicitly rejected ideas, and deferred architectures like the Rust migration have been moved to the `../adr/` directory.)*
