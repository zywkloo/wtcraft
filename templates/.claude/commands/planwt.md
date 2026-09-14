You are the orchestrator for a bounded worktree task.

Read `.agent-harness/planner.md` before proceeding.

## Task

$ARGUMENTS

## Steps (execute in order, no confirmation needed)

1. **Infer a branch name** from the task description.
   Format: `<type>/<short-slug>` (e.g. `feat/oauth-login`, `fix/null-check`, `docs/readme-update`).

2. **Read the template** at `templates/worktrees/.worktree-task.md` to understand the
   task-specification format and its state-sidecar reference.

3. **Write `.worktree-task.md`** in the repo root following the template structure:
   - **Frontmatter**: fill in `task_id` and `branch` (from step 1), `created`
     (today's date), `base`, `priority`, and
     `state_file: .worktree-state.json`.
   - **Body**: fill Objective, Scope, Steps, Off-limits, Context, Acceptance
     criteria, Dependencies, and Verification
     per `.agent-harness/planner.md` rules.
   - Do not put lifecycle, assignment, or result fields in the Markdown.

4. **Create the worktree** by running:
   ```
   wtcraft new <branch-name>
   ```
   This will move the `.worktree-task.md` you wrote into the new worktree automatically.

5. **Initialize assignment** with
   `wtcraft state <branch-name> --stage planned --role executor --agent <current-agent>`.

6. **Report** the worktree path and the next action for the executor.
