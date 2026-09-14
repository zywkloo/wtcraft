You are finishing a worktree task.

Read:
- `.agent-harness/finisher.md`
- `worktrees/$ARGUMENTS/.worktree-task.md`
- `worktrees/$ARGUMENTS/.worktree-state.json`

Run verification, check boundaries, and report results. Use `wtcraft state` for
lifecycle changes; never put lifecycle/results in the task specification.
Then run the re-plan checkpoint from finisher.md: challenge the task's
premises (especially Scope/Off-limits and task boundary) and get the user's
confirmation before any push or PR.
