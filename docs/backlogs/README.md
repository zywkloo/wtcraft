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
- [model-select-quota.md](model-select-quota.md) — quota-aware model
  recommendation: "for the next executor task, use X"
- [subscription-fit.md](subscription-fit.md) — personal, rule-based "is my
  plan paying for itself" report (idea)
- [external-watchlist.md](external-watchlist.md) — upstream projects to watch
  or contribute to (tokscale, usage tooling, git GUI landscape)
- [../sourcegitfork/](../sourcegitfork/) — SourceGit fork research:
  architecture boundaries, implementation plan, upstream and release strategy
- [worktree-layout.md](worktree-layout.md) — enumerate worktrees via
  `git worktree list` instead of glob; flip default layout to sibling dir

*(Note: Completed designs, explicitly rejected ideas, and deferred architectures like the Rust migration have been moved to the `../adr/` directory.)*
