# Architecture and boundaries

## SourceGit today

SourceGit is a cross-platform **.NET + Avalonia** desktop app with a standard
MVVM split (`Models/`, `ViewModels/`, `Views/`, `Commands/`, `Converters/`,
`Resources/`, `Native/`).

It is not a browser shell, daemon host, or reusable core with a thin GUI. It
depends on an external Git install and shells out for Git operations.
Credentials also live in the host Git environment rather than a
SourceGit-owned authentication layer.

## Mechanism vs policy

Use two layers from the start. The split costs roughly half a day over
hardcoding wtcraft directly, but keeps an upstream contribution path open.

### Layer 1 — generic worktree metadata display

This layer has zero wtcraft coupling and can be pitched upstream as a generic
answer to "which of my many worktrees is doing what?"

- **Config:** per-repo metadata filename, empty to disable; one primary key
  shown as the row badge; remaining keys appear in the tooltip. Reuse existing
  per-repo settings persistence.
- **Parsing:** optional `---` frontmatter; `Split(':', 2)` scalar lines; trim
  whitespace; skip blanks and comments; read at most the first 4KB UTF-8;
  silently ignore failures. Add no YAML dependency.
- **Refresh:** piggyback SourceGit's existing `RefreshWorktrees()` path. Add
  no watcher, thread, or event source.
- **Display:** neutral row badge, all fields in the existing tooltip, and an
  optional "Open metadata file" context action.
- **Model:** a nullable `Dictionary<string,string>` property on the worktree
  view model.

Expected size: roughly 150-200 lines.

### Layer 2 — wtcraft policy

A fork-only interpreter such as `IWorktreeMetadataInterpreter` consumes the
generic field dictionary and produces wtcraft semantics:

- stage badge colors and state-machine meaning
- `role:` joins against `role-models.yml`
- breach, stale, bypass, and zombie alarms
- governance panel rows and summaries

If Layer 1 lands upstream, the fork's largest mount point becomes
upstream-owned and monthly rebases become much smaller.

## Integration depths

### Depth A — UI-only overlay

Keep governance logic outside the app. The fork enumerates existing SourceGit
worktrees, reads `.worktree-task.md` or `wtcraft status --json`, renders
metadata, and optionally shells out to `wtcraft check`.

Use for research and the first prototype. It has the lowest rebase and
Windows cost.

### Depth B — app-owned governance interpreter

Keep external Git, but move policy interpretation into the fork:

- parse frontmatter or `status --json`
- map stage, role, and alarms
- filter, sort, group, and summarize worktrees

This is the natural first real fork release. Governance becomes a first-class
domain inside SourceGit while remaining repository/worktree-centered.

### Depth C — separate governance core

Extract the observer and policy engine into a standalone cross-platform core,
implemented as a Go, Rust, or .NET executable/library. SourceGit consumes its
stable JSON/events and becomes one GUI host rather than the source of truth.

The core owns:

- worktree enumeration and metadata normalization
- contract parsing and stage-state-machine evaluation
- alarm generation and status snapshots
- stable interfaces for SourceGit, terminal dashboards, and other clients

Choose this when the project grows beyond one GUI fork. It is also the
cleanest Windows answer because hard logic stops living in shell scripts.

## Multi-agent session boundary

SourceGit remains a strong base while every important session maps cleanly to
a repository worktree. The intended boundary is at most one active external
agent TUI per worktree. SourceGit may launch, index, focus, and report that
session, but does not implement a terminal emulator or own conversation logs.

It becomes a poor center once sessions may exist without worktrees, cross
repositories, run multiple agents per worktree, stream full logs, or require
deep pause/resume/intervention.

Use this decision rule:

- **Every session corresponds to one worktree:** deepen the SourceGit fork.
- **Sessions require runtime control or cross-repo aggregation:** build a
  separate dashboard over the shared core.
- **Uncertain:** keep the core/interface independent and use SourceGit as the
  first client.

Recommended evolution:

- research prototype: Depth A
- first useful fork: Depth B
- product line or multiple clients: Depth C

The concrete runtime state and ignore rules are specified in
[Worktree session state](session-state.md).
