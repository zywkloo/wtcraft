# Implementation plan

## Upstream facts

Measured 2026-06-11 against SourceGit v2026.12:

- About 58k lines of C# across 479 files and 32k lines of AXAML across 160
  files. It is a medium-sized MVVM app using CommunityToolkit.Mvvm source
  generators.
- The entire worktree feature is 794 lines across 14 files:
  `Models/Worktree.cs` -> `Commands/Worktree.cs` -> `ViewModels/Worktree.cs`
  -> small dialog views.
- Two large files should be navigated, not rewritten:
  `ViewModels/Repository.cs` and `Views/Repository.axaml`.
- Official releases are unsigned on all platforms. CI includes build,
  package, release, localization, and format workflows.

## Exact mount points

As of v2026.12:

- Sidebar worktree group: `Views/Repository.axaml` lines roughly 372-460,
  containing the group expander, `WorktreeList`, row template, and tooltip.
- Data source: `ViewModels/Repository.cs`, especially the `Worktrees`
  property and `RefreshWorktrees()`.
- Existing refresh path:
  `Commands.Worktree(FullPath).ReadAllAsync()` -> `Worktree.Build()` -> UI
  dispatch. Piggyback this path; do not add a second watcher.

## Contract consumed

- `.worktree-task.md` scalar frontmatter: branch, agent, status, created,
  priority, base, stage, role, and last activity.
- The file is gitignored by design and must be read from the filesystem.
- `.worktree-session.json` is optional launcher-owned runtime state for the
  worktree's single active external TUI session. It is always clone-local
  through `.git/info/exclude`; see [Worktree session state](session-state.md).
- Frontmatter is STOT: single-line `key: value` scalars. Direct parsing is
  around 40 lines of C# and needs no YAML library.
- `wtcraft status --json` should replace direct file parsing behind an
  interface.
- `wtcraft check <worktree>` supplies breach detection through SourceGit's
  existing command execution pattern.

## v0.1 weekend scope

### Phase A — badges on existing rows

1. Add `Models/WorktreeMetadata.cs` with the generic parser and thin wtcraft
   interpreter.
2. Extend `ViewModels/Worktree.cs` with nullable task metadata and derived
   display values.
3. Attach metadata after `Worktree.Build()` during `RefreshWorktrees()`.
4. Add a stage badge and task fields to the existing worktree row and
   tooltip.

Deliverable: opening a repository immediately answers which stage each task
is in, and which agent and role own it.

### Phase B — governance panel and release

1. Add a governance panel view model and AXAML view showing branch, stage,
   role, agent, verification, and alarms.
2. Add the panel as a sidebar group below Worktrees.
3. Implement breach alarms through `wtcraft check`. Defer stale and bypass
   alarms if time runs short.
4. Tag and use SourceGit's existing release workflow for three-platform
   artifacts.

## Gotchas

- Every new UI string needs a locale resource or localization CI fails.
- Run `dotnet format` before pushing.
- The fork initially shares SourceGit's app-data directory. Rename it before
  asking users to install both applications.
- Never assume an in-repo `worktrees/` directory. Enumerate through Git and
  probe every registered worktree path.
- Keep new files plus minimal hooks to reduce recurring upstream rebase cost.

## Explicitly not v0.1

- write operations or stage-transition editing
- stale and bypass alarms if the weekend scope runs short
- token telemetry
- terminal emulation, multiplexing, or deep session runtime control
- app rename/rebrand
- signed Windows builds
- upstream PR submission
