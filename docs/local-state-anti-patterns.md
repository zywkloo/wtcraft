# Anti-Patterns: Local Task State & Worktree Workflow

This document records the architectural and Git-level anti-patterns discovered during the implementation of the local task state guard (specifically around PR #25). These serve as a reference for why certain approaches were rejected and how to properly handle Git worktree state.

## 1. Global Side-Effects of Mutating `info/exclude`

### The Anti-Pattern
Attempting to dynamically ignore a file strictly within a worktree by appending it to `info/exclude` via a script (e.g., inside `wtcraft new`):

```bash
local exclude_file
exclude_file="$(git -C "$wt_path" rev-parse --git-path info/exclude)"
echo "/.worktree-task.md" >> "$exclude_file"
```

### Why it's Dangerous
1. **Global Scope**: Git worktrees share the same core `.git` directory. The path returned by `rev-parse --git-path info/exclude` resolves to the **main repository's global `.git/info/exclude`**.
2. **Unintended Collateral**: Appending `/.worktree-task.md` ignores the file not just in the newly created worktree, but also in the **main repository root** and **all other worktrees**.
3. **Environment Inconsistency**: `info/exclude` is a local, unversioned file. If other developers `git clone` the repository, they will not inherit this ignore rule until they run the specific script that mutates it. This causes inconsistent tracking behavior across the team.

### The Correct Approach
Do not use "magic" to silently modify local Git configuration. To ignore files like `.worktree-task.md`:
- Explicitly add the rule to the version-controlled `.gitignore`.
- If providing a tool for third-party repositories, have the initialization command (`wtcraft init`) append the rule to the user's `.gitignore` transparently.

---

## 2. The Orchestrator Workflow Disconnect (Data Loss)

### The Anti-Pattern
Designing an Agent workflow that splits file generation and environment setup without state transfer. For example, having the agent write a task contract to the root repository, then calling a scaffolding command (`wtcraft new`) that unconditionally writes an empty template over the target destination.

### Why it's Dangerous
1. **Plan Abandonment**: The Agent (`/planwt`) writes the carefully crafted `.worktree-task.md` to the `repo_root`.
2. **Destructive Scaffolding**: `wtcraft new <branch>` then executes, creating the worktree and blindly copying `templates/worktrees/.worktree-task.md` into the new worktree.
3. **Data Loss**: The worktree receives a blank template, while the actual generated plan is left abandoned in the `repo_root`.

### The Correct Approach
Scaffolding scripts (`wtcraft new`) must be state-aware and capable of absorbing preexisting artifacts.

```bash
local task_file="${wt_path}/.worktree-task.md"

# If a generated plan already exists in the root, absorb it
if [ -f "${repo_root}/.worktree-task.md" ]; then
  mv "${repo_root}/.worktree-task.md" "$task_file"
else
  # Otherwise, fallback to the blank template
  cp "${TEMPLATE_DIR}/worktrees/.worktree-task.md" "$task_file"
fi
```
This ensures the workflow from generation to scaffolding is continuous and preserves data.
