---
name: planwt
description: Use when starting a bounded wtcraft worktree task — orchestrates the planning workflow (infer a branch, write the .worktree-task.md contract, create the worktree via `wtcraft new`)
---

# Plan a wtcraft worktree task

You are the orchestrator for a bounded worktree task.

Read `.agent-harness/planner.md` before proceeding. If the repo has
`templates/worktrees/.worktree-task.md`, read it to confirm the expected
frontmatter fields and body sections.

## Steps (execute in order, no confirmation needed)

1. **Infer a branch name** from the task description.
   Format: `<type>/<short-slug>` (e.g. `feat/oauth-login`, `fix/null-check`, `docs/readme-update`).

2. **Write `.worktree-task.md`** in the repo root:
   - **Frontmatter**: `branch` (from step 1), `created` (today), `base`
     (default `develop`, or `main` when `WTCRAFT_BASE_BRANCH=main`), `agent`,
     `status: ready`, `priority`.
   - **Body**: Scope, Steps, Off-limits, Context, and Verification per
     `.agent-harness/planner.md`.

3. **Create the worktree**: run `wtcraft new <branch-name>`. It moves the
   `.worktree-task.md` you wrote into the new worktree automatically.

4. **Report** the worktree path and the next action for the executor.
