---
name: statuswt
description: Use when checking active wtcraft worktree tasks — joins task specifications with lifecycle/result sidecars
---

# wtcraft task status

Run `wtcraft status` and explain the output clearly to the user.

If the command is unavailable, pair each `.worktree-task.md` with its declared
`.worktree-state.json` sidecar. Summarize lifecycle/results from JSON and stable
task metadata from Markdown; use legacy task frontmatter only when no sidecar
exists.
