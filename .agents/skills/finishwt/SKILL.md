---
name: finishwt
description: Use when finishing a wtcraft worktree task — runs the declared verification, checks Scope/Off-limits, and does the re-plan checkpoint before any push or PR
---

# Finish a wtcraft worktree task

Read:

- `.agent-harness/finisher.md`
- `worktrees/<name>/.worktree-task.md` for the target worktree

Run the task's declared verification, check the changeset against Scope and
Off-limits, and report results. Then run the re-plan checkpoint from
`finisher.md`: challenge the task's premises (especially Scope, Off-limits, and
the task boundary) and get explicit user confirmation before any push or PR.
