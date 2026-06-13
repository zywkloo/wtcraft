# Worktree enumeration + default layout change

> Status: **step 1 shipped 2026-06-12** — `status`/`check`/`verify` now
> enumerate and resolve via `git worktree list --porcelain`
> (`list_worktrees` helper); uncontracted and zombie (prunable) worktrees
> are surfaced; layout is configuration, not contract. Step 2 (flip the
> default to a sibling dir) not scheduled. Originally recorded 2026-06-12,
> from the GitKraken trial findings in `external-watchlist.md`
> § GitKraken Agent Mode anatomy.

## Problem

wtcraft hardcodes the in-repo `worktrees/` layout (created by `wtcraft new`,
globbed by `status`/`check`). Three issues, in priority order:

1. **Glob enumeration can never be correct.** Layouts observed in the wild:
   wtcraft in-repo `worktrees/`, GitKraken sibling `<repo>.worktrees/`,
   and Codex creating worktrees at arbitrary paths outside the repo.
   Any directory-glob approach misses agent-created wild worktrees by
   construction.
2. **Watcher storm.** With worktrees inside the repo, any IDE / Git GUI
   watching the main repo recursively receives every file event from every
   agent working in every worktree. First victim: the SourceGit fork's own
   FileSystemWatcher (upstream already has Linux perf pain, #1992).
3. **Indexer pollution + clean footgun.** LSPs/Spotlight/backup tools index
   N copies of the codebase regardless of .gitignore. Verified 2026-06-12
   (dry-run): `git clean -fdx` *skips* nested worktrees (`.git` file is
   recognized), but `git clean -ffdx` **removes the whole `worktrees/`
   dir** including uncommitted agent work.

## Decision sketch

**Step 1 — enumeration via git, not glob (the real fix).**
`wtcraft status` / `check` (and the future `status --json`) enumerate via
`git worktree list --porcelain`, then probe each absolute path for
`.worktree-task.md`. Git's own `.git/worktrees/` metadata is the registry:
every `git worktree add` by any tool from any path is recorded — a
vendor-free mechanism (see `stage-state-machine.md` vendor-dependency
principle). Bonuses:

- Wild worktrees (no task file) become visible and are surfaced as
  **uncontracted** — work outside the contract system is a governance
  signal (bypass-adjacent), not a blind spot.
- `prunable` / `locked` markers come free (zombie-worktree detection).
- Boundary: agents that `git clone` instead of `worktree add` are separate
  repos — by definition out of scope.

After step 1, layout is configuration, not contract; old repos keep
working with zero migration.

**Step 2 — flip the default to sibling.**
`wtcraft new` creates `../<repo>.worktrees/<branch>` (GitKraken's
convention). `wtcraft init` stops appending `/worktrees/` to .gitignore
(the per-worktree `/.worktree-task.md` entry from ADR-001 stays).
Trade-off accepted: deleting the main repo dir now orphans the sibling
worktrees dir — finisher cleanup + `git worktree prune` is the backstop.

## Touch points

`scripts/wtcraft` (`cmd_new` path, `cmd_status`/`cmd_check` enumeration,
`cmd_init` gitignore), `.agent-harness/*.md` + `.claude/commands/*.md` docs
mentioning `worktrees/`, and their `templates/` twins (CLAUDE.md dual-write
rule). The SourceGit fork panel is unaffected — it already follows the
same enumerate-via-git rule (fork plan gotchas).

## Related

- `external-watchlist.md` § GitKraken Agent Mode anatomy — layout survey
- `../sourcegitfork/implementation-plan.md` — fork-side gotcha (same rule)
- `stage-state-machine.md` — vendor-free principle; `status --json` should
  ship after step 1 so the JSON is layout-agnostic from day one
