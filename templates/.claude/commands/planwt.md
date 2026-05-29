You are the orchestrator for a bounded worktree task.

Read `.agent-harness/planner.md` before proceeding.

## Task

$ARGUMENTS

## Steps (execute in order, no confirmation needed)

1. **Infer a branch name** from the task description.
   Format: `<type>/<short-slug>` (e.g. `feat/oauth-login`, `fix/null-check`, `docs/readme-update`).

2. **Write `.worktree-task.md`** in the repo root with Scope, Steps, Off-limits, Context,
   and Verification sections filled in per `.agent-harness/planner.md` rules.

3. **Create the worktree** by running:
   ```
   wtcraft new <branch-name>
   ```

4. **Report** the worktree path and the next action for the executor.
