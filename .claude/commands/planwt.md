You are the orchestrator for a bounded worktree task.

Read `.agent-harness/planner.md` before proceeding.

## Task

$ARGUMENTS

## Steps (execute in order, no confirmation needed)

1. **Infer a branch name** from the task description.
   Format: `<type>/<short-slug>` (e.g. `feat/oauth-login`, `fix/null-check`, `docs/readme-update`).

2. **Read the template** at `templates/worktrees/.worktree-task.md` to understand the
   expected file format and frontmatter fields.

3. **Write `.worktree-task.md`** in the repo root following the template structure:
   - **Frontmatter**: fill in `branch` (from step 1), `created` (today's date),
     `base` (default `develop`, or `main` if `WTCRAFT_BASE_BRANCH=main`),
     `agent`, `status: ready`, and `priority`.
   - **Body**: fill Scope, Steps, Off-limits, Context, and Verification
     per `.agent-harness/planner.md` rules.

4. **Create the worktree** by running:
   ```
   wtcraft new <branch-name>
   ```
   This will move the `.worktree-task.md` you wrote into the new worktree automatically.

5. **Report** the worktree path and the next action for the executor.
