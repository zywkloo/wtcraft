---
name: planwt
description: Use when starting a bounded wtcraft worktree task — writes the task specification, creates the worktree, and initializes its state sidecar
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
   - **Frontmatter**: `task_id` and `branch` (from step 1), `created` (today),
     `base` (default `develop`, or `main` when `WTCRAFT_BASE_BRANCH=main`),
     `priority`, and `state_file: .worktree-state.json`.
   - **Body**: Objective, Scope, Steps, Off-limits, Context, Acceptance
     criteria, Dependencies, and Verification per
     `.agent-harness/planner.md`.
   - State explicitly that lifecycle/results live in the sidecar. Do not put
     `stage`, `role`, `agent`, `status`, `verify_result`, or `verified` here.

3. **Create the worktree**: run `wtcraft new <branch-name>`. It moves the
   `.worktree-task.md` you wrote into the new worktree automatically.

4. **Initialize assignment**: run
   `wtcraft state <branch-name> --stage planned --role executor --agent <current-agent>`.

5. **Report** the worktree path and the next action for the executor.
