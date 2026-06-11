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

## Architecture: mechanism vs policy (decided 2026-06-11)

Two layers from the start (~+0.5 day over hardcoding wtcraft directly),
keeping the upstream-PR option open for Layer 1.

### Layer 1 — generic worktree metadata display (upstream-PR candidate)

Zero wtcraft coupling; shaped as something any SourceGit user could use
("which of my many worktrees is doing what").

a. **Config surface, kept minimal**: per-repo *metadata filename* (empty =
   feature off — off-by-default is a precondition for upstream acceptance)
   plus one *primary key* whose value shows as the row badge; all other
   keys tooltip-only. Reuse the existing per-repo settings persistence
   (the `_uiStates.IsWorktreeExpandedInSideBar` pattern in Repository.cs).
   No color mapping config, no multi-file, no templates.
b. **Parsing contract**: optional `---` frontmatter fence (no fence = read
   from top, stop at first non-matching line); per line `Split(':', 2)` +
   trim; skip blanks and `#` comments; silently ignore non-matching lines
   (no nesting/arrays/multiline — STOT generalized). Read first 4KB UTF-8
   only; any failure = silently no metadata, never a dialog. **No YAML
   library** — zero new NuGet deps is key to PR acceptance.
c. **Read timing**: piggyback `RefreshWorktrees()` (Repository.cs ~1160)
   background path — one `File.Exists` + small read per worktree. No new
   watcher, threads, or event sources; existing refresh triggers
   (checkout/branch/watcher paths) update metadata for free.
d. **Display**: primary-key value as a *neutral, uncolored* row badge —
   the mechanism layer assigns no semantics; all key:values appended to
   the existing tooltip Grid (Repository.axaml ~420), file order
   preserved. Optional context-menu "Open metadata file".
e. **Output**: `Dictionary<string,string>` on a nullable property of
   `ViewModels/Worktree.cs`. Whole layer ~150–200 lines — a
   one-screen-diff PR.

### Layer 2 — wtcraft policy (fork-only)

Interpreter interface (e.g. `IWorktreeMetadataInterpreter`) consuming the
fields dict → stage badge colors/FSM semantics, `role:` join against
`role-models.yml`, `wtcraft check` breach alarms, the governance panel.
The wtcraft interpreter is the first implementation.

If Layer 1 is ever accepted upstream (or reimplemented there), the fork's
largest mount point becomes upstream-owned and monthly rebases shrink to
near-zero.

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

1. New `Models/WorktreeMetadata.cs` — generic frontmatter parser per the
   Layer-1 contract above (no wtcraft knowledge), plus a thin wtcraft
   interpreter (Layer 2) mapping fields to governance meaning.
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
3. Alarms v0.1: **breach** only, via `wtcraft check`. **stale** (fs mtime
   based) and **bypass** (git status vs declared stage) are vendor-free
   and can follow soon after; CLI event hooks for finer liveness are
   deferred per the vendor-dependency principle (stage-state-machine.md).
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

Budget note: the two-layer split costs ~+0.5 day. If the weekend runs
short, Phase B item 3 (breach alarms via `wtcraft check`) moves to the cut
list before anything else.

### Cut list (explicitly not v0.1)

Write operations of any kind, stage transition editing, stale/bypass
alarms, token telemetry, app rename/rebrand, signed Windows builds,
upstream PR submission itself (post-v0.1 activity).

## Upstream relationship (intel gathered 2026-06-11)

- The fork owes upstream nothing (MIT; fork-and-diverge is normal).
- **No prior art**: searched issues/PRs (metadata, custom, note, badge,
  agent, AI × worktree) — nobody has requested per-worktree metadata
  display. Closest: #2158 (main-repo vs worktree indicator), #1761
  (worktree-linked branch indication) — git-native concepts only.
- **Maintainer profile (love-linger)**: "leo", Chengdu, China; 78% of all
  commits are his, low-profile (no bio/blog), project began Windows-only
  and went cross-platform via Avalonia (he maintains support forks of
  Avalonia/AvaloniaEdit). Ships worktree UI clarity fixes himself within
  days of issue discussion; hard filter on information density (rejected
  tooltip status as "completely repetitive and unhelpful"; declined
  ahead/behind tooltip explanation); external worktree feature PRs closed
  unmerged (#2346, #1983/#1982) — the pattern is discuss-in-issue → he
  implements it himself. Responds in Chinese.
- Therefore **issue-first is mandatory**, not optional. Pitch in Chinese,
  framed as "many worktrees are hard to tell apart" (his own acknowledged
  pain in #2158: "确实很难分得清楚") — NOT as an AI-agent feature. The
  best realistic outcome may be him reimplementing the mechanism himself,
  which is equally a win: the mount point becomes upstream-owned.
- Incidental PRs while working in the codebase (bugs hit, zh_CN
  localization fixes, small UX) keep the rebase relationship friendly.
- The two-layer architecture stands regardless of upstream outcome (fork
  cleanliness + small rebase surface).

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
