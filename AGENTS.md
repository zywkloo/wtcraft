<!-- wtcraft:agents:start -->
## wtcraft routing
If `.worktree-task.md` exists in the current worktree root, read `.agent-harness/executor.md` first and follow task Scope, Off-limits, and Verification.

## release guardrails
- Version tags must use `v<semver>` format (example: `v0.3.8`).
- Version tags must be created from `main` only.
- Never create or move version tags from feature/worktree branches.
<!-- wtcraft:agents:end -->
