---
name: statuswt
description: Use when checking the status of active wtcraft worktree tasks — lists the task contracts and explains the status table
---

# wtcraft task status

Run `wtcraft status` and explain the output clearly to the user.

If the command is unavailable, fall back to listing `.worktree-task.md` files
under the repo's worktrees and summarizing their `status` and `branch`
frontmatter fields.
