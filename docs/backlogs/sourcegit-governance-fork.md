# SourceGit governance fork — customization plan

> Status: not scheduled (target: one weekend). Recorded 2026-06-11.
> This doc lives in wtcraft because wtcraft owns the contracts the panel
> consumes. When the fork repo exists, copy this plan into its docs and
> leave a pointer here.

## Goal

Fork [SourceGit](https://github.com/sourcegit-scm/sourcegit) (MIT,
C#/Avalonia, Win/macOS/Linux) and add a read-only **governance panel**: per
worktree, show the `.worktree-task.md` contract state (stage, role, agent,
verified) and breach indicators. The fork is the GUI half of the observer
design in `stage-state-machine.md` § Declared vs actual; landscape rationale
in `external-watchlist.md` § Worktree agent GUIs.

Read-only is a hard line for v0.1: the fork renders state, wtcraft and the
agents own all writes.

## Repo split

- **Fork repo** (separate, GitHub fork to keep the upstream merge path):
  all C#/AXAML work.
- **wtcraft repo**: contract specs (`.worktree-task.md` frontmatter,
  `wtcraft status --json`, `wtcraft check`), this plan until migration.

## Upstream facts (measured 2026-06-11, v2026.12)

- ~58k lines C# (479 files) + ~32k lines AXAML (160 files). Medium-sized,
  cleanly factored MVVM (CommunityToolkit.Mvvm source generators).
- The entire worktree feature is **794 lines / 14 files** — the unit price
  for a feature here. Pattern: `Models/Worktree.cs` (12 lines, dumb struct)
  → `Commands/Worktree.cs` (111 lines, shells out to git CLI, parses
  stdout) → `ViewModels/Worktree.cs` (112 lines, `ObservableObject`) →
  small dialog Views.
- Two god files to navigate, not rewrite: `ViewModels/Repository.cs`
  (1941 lines) and `Views/Repository.axaml` (947 lines).
- **All official releases ship unsigned on every platform** (no
  sign/notarize step in any workflow; README tells macOS users to
  `sudo xattr -cr`). Full CI exists: `build.yml`, `package.yml`,
  `release.yml`, plus `localization-check.yml` and `format-check.yml`.

## Mount points (exact, as of v2026.12)

- Sidebar worktree group: `Views/Repository.axaml` lines ~372–460 —
  `ToggleButton Classes="group_expander"` (Grid.Row 8) +
  `ListBox x:Name="WorktreeList"` (Grid.Row 9) with
  `DataTemplate DataType="vm:Worktree"` (row + rich tooltip).
- Data source: `ViewModels/Repository.cs` — `Worktrees` property (line
  ~184), `RefreshWorktrees()` (line ~1160):
  `Commands.Worktree(FullPath).ReadAllAsync()` → `Worktree.Build()` →
  dispatch to UI thread. Refresh is invoked from checkout/branch/watcher
  paths (~lines 640, 814, 850, 874, 883) — piggyback here, do not add a
  second watcher.

## Contract consumed

- `worktrees/**/.worktree-task.md` frontmatter: `branch / agent / status /
  created / priority / base`, plus `stage:`, `role:`, `last_active:` once
  stage-state-machine items 1+5 land. **Gitignored by design (ADR-001)** —
  the panel must read the filesystem, never git.
- Frontmatter is STOT: single-line `key: value` scalars only. Parse with
  `---` delimiters + `Split(':', 2)`; **no YAML library dependency**
  (~40 lines of C#).
- `wtcraft check <worktree>` for breach detection (shell out, reuse the
  `Commands/` pattern). `wtcraft status --json` replaces direct file
  parsing once it exists — keep the parser behind an interface so the swap
  is one class.

## v0.1 implementation (weekend scope)

### Phase A — Saturday: badges on existing rows

1. New `Models/WorktreeTask.cs` — frontmatter struct + parser (~60 lines).
2. Extend `ViewModels/Worktree.cs` — nullable `Task` property + derived
   display strings.
3. Hook `RefreshWorktrees()` — after `Worktree.Build()`, probe each
   worktree path for `.worktree-task.md` and attach.
4. `Views/Repository.axaml` worktree `DataTemplate` — stage badge
   (colored dot + text) on the row; task fields appended to the existing
   tooltip grid.

Deliverable: open repo → worktree list already answers "which stage is
every task at, run by which agent in which role".

### Phase B — Sunday: governance panel + release

1. New `ViewModels/GovernancePanel.cs` + `Views/GovernancePanel.axaml`
   (+`.axaml.cs`) — table: branch | stage | role | agent | verified |
   alarms. New files only.
2. Mount: clone the group_expander + ListBox pair as a new sidebar group
   below Worktrees (the parent Grid needs two more RowDefinitions).
3. Alarms v0.1: **breach** only, via `wtcraft check`. **stale** and
   **bypass** need the heartbeat/`last_active:` convention
   (stage-state-machine.md) — deferred.
4. Tag → `release.yml` → three-platform artifacts, unsigned like upstream.

### Gotchas (will cost time if hit blind)

- `localization-check.yml` fails the build if UI strings bypass the locale
  resources. Every new string needs a `Text.*` key in
  `src/Resources/Locales/en_US.axaml` (copy the
  `Text.Repository.Worktrees` pattern).
- `format-check.yml` — run `dotnet format` before pushing.
- App identity: the fork shares `~/Library/Application Support/SourceGit`
  (and equivalents) with upstream. Fine for v0.1 on a dev machine; rename
  the app-data folder before telling anyone else to install both.

### Cut list (explicitly not v0.1)

Write operations of any kind, stage transition editing, stale/bypass
alarms, token telemetry, app rename/rebrand, signed Windows builds.

## Fork hygiene

- Keep `main` tracking upstream `main`; all work on a `governance` branch;
  releases tagged from `governance`. Rebase onto upstream monthly —
  upstream is very active (96 releases), and the new-files-plus-minimal-
  hooks discipline is what keeps rebases near-trivial.
- License: upstream MIT; fork stays MIT with attribution intact.

## Signing / release policy

- v0.1: unsigned everywhere (upstream's own practice).
- Later, macOS: Developer ID + notarization via existing Apple Developer
  membership ($0 marginal) — a sign+notarize step in `package.yml`
  (secrets: cert + App Store Connect API key). The fork then ships a
  *better-signed* macOS build than upstream.
- Windows: stays unsigned (SmartScreen "More info → Run anyway" note in
  README). If ever signing: SignPath.io is free for OSS; paid OV certs
  (~$200–400/yr + hardware token) are not worth it at hobby scale.

## Related

- `stage-state-machine.md` — observer design (three-signal reconciliation,
  named alarms), `role:` field, `status --json`
- `external-watchlist.md` § Worktree agent GUIs — landscape, why SourceGit
- `adr/001-task-contract-local-state.md` — why `.worktree-task.md` is
  untracked (panel reads fs, not git)
