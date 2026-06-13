# SourceGit governance fork

> Status: research direction, not scheduled. Originally recorded 2026-06-11.
> This documentation lives in wtcraft because wtcraft owns the contracts the
> fork consumes. When the fork repo exists, copy the implementation-facing
> material there and leave pointers here.

## Goal

Fork [SourceGit](https://github.com/sourcegit-scm/sourcegit) (MIT,
C#/Avalonia, Windows/macOS/Linux) and add a read-only governance view over
Git worktrees. Per worktree, show `.worktree-task.md` state such as stage,
role, agent, verification, and breach indicators.

Read-only is a hard line for v0.1: the fork renders state; wtcraft and agents
own writes.

## Current conclusion (2026-06-13)

SourceGit is valuable when the primary object remains:

`repo -> worktree -> branch -> task contract -> changes -> verification`

It already supplies the expensive Git-client surface: cross-platform desktop
UI, repository/worktree management, diffs, history, Git command execution,
background refresh, settings, packaging, and release workflows.

Its value falls quickly when the primary object becomes:

`agent session -> prompt -> tool calls -> token/quota -> approvals -> logs`

SourceGit has no native session runtime, process lifecycle, streaming event
model, terminal multiplexer, provider adapter, or cross-repository session
home. Deeply embedding those concerns would turn the fork into a difficult
second product inside a repository-centered app.

The working strategy is therefore:

- use SourceGit first as a Git/worktree governance observer
- keep session state and policy interfaces independent of SourceGit
- introduce a separate cross-platform core if the observer grows beyond one
  GUI
- build a separate session dashboard only if real usage shows that sessions,
  rather than repositories/worktrees, should be the primary navigation model

Do not rebuild a Git GUI from scratch now, and do not make SourceGit own the
agent runtime.

## Repo split

- **SourceGit fork repo:** all C#/AXAML work.
- **wtcraft repo:** contract specs, `wtcraft status --json`, `wtcraft check`,
  and this research until the fork exists.

## Documents

- [Architecture and boundaries](architecture.md) — SourceGit's current
  architecture, mechanism/policy split, integration depths, and the session
  boundary.
- [Worktree session state](session-state.md) — one-TUI-per-worktree runtime
  model, state-file schema, ownership, and ignore policy.
- [Implementation plan](implementation-plan.md) — upstream facts, exact mount
  points, consumed contracts, weekend scope, and gotchas.
- [Upstream and release](upstream-and-release.md) — upstream strategy, fork
  hygiene, and signing/release policy.

## Related wtcraft documents

- [Stage state machine](../backlogs/stage-state-machine.md) — observer design,
  named alarms, `role:`, and `status --json`.
- [External watchlist](../backlogs/external-watchlist.md) — landscape and why
  SourceGit is the selected fork base.
- [Worktree layout](../backlogs/worktree-layout.md) — enumerate through Git,
  never through a hardcoded directory layout.
- [Task contract local state](../adr/001-task-contract-local-state.md) — why
  `.worktree-task.md` is untracked and read from the filesystem.
