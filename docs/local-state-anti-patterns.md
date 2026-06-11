# ADR: Task Contract as Local Worktree State

## Status

Accepted — implemented in PR #25.

## Context

The `.worktree-task.md` task contract is generated per-worktree by `/planwt` and consumed by the executor agent inside the worktree sandbox. It is ephemeral, branch-specific state that should never be committed or merged into the base branch.

Previously, the contract was tracked in git (both in the wtcraft repo itself and in user repos). This led to noisy diffs, merge conflicts between worktrees, and leaked implementation state in the git history.

## Decision

### 1. Ignore via `.gitignore`, not `info/exclude`

We considered using `git info/exclude` to silently ignore `.worktree-task.md` per-worktree. This approach was **rejected** because:

- Git worktrees share the same core `.git` directory. `rev-parse --git-path info/exclude` resolves to the **main repository's** global `.git/info/exclude`, not a worktree-local path. Writing to it affects the main repo and all other worktrees.
- `info/exclude` is unversioned. Other developers who `git clone` the project would not inherit the rule, causing inconsistent tracking behavior across environments.

**Chosen approach:** `wtcraft init` appends `/.worktree-task.md` to the project's version-controlled `.gitignore`. This is explicit, portable, and consistent across all clones and worktrees.

### 2. `cmd_new` absorbs existing plans from the repo root

The `/planwt` orchestrator writes a `.worktree-task.md` plan to the repo root, then calls `wtcraft new <branch>` to create the worktree. If `cmd_new` unconditionally copies a blank template into the worktree, the generated plan is lost.

**Chosen approach:** `cmd_new` checks whether `repo_root/.worktree-task.md` already exists. If so, it moves (`mv`) the file into the new worktree. Otherwise it falls back to copying the blank template. This ensures the orchestrator workflow is seamless.

```bash
if [ -f "${repo_root}/.worktree-task.md" ]; then
  mv "${repo_root}/.worktree-task.md" "$task_file"
else
  cp "${TEMPLATE_DIR}/worktrees/.worktree-task.md" "$task_file"
fi
```

### 3. `cmd_check` guards against accidental commits

As defense-in-depth, `wtcraft check` now flags `.worktree-task.md` in the changed files list as a violation, regardless of Scope. This catches cases where an agent force-adds the contract despite the `.gitignore` rule.

## Consequences

- `.worktree-task.md` no longer appears in diffs or git history.
- `.worktree-task.template.md` (the root-level dogfooding copy) is removed; the canonical template lives at `templates/worktrees/.worktree-task.md`.
- The `/planwt` → `wtcraft new` workflow is now a single seamless step with no data loss.
