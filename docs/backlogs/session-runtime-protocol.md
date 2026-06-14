# Session runtime protocol + launch modes

> Status: not scheduled. Recorded 2026-06-13 from the `wtflow` launch-mode
> discussion and aligned with ADR-005.

## Goal

Support a GUI flow like:

1. enter prompt
2. choose agent
3. run `wtc new <task>`
4. launch a session in the new worktree
5. monitor state without depending on vendor-specific UI internals

ADR-005 chooses **interactive external TUI** as the default launch mode.
This memo tracks the protocol work that makes that model reliable, while
keeping an optional headless mode open later.

## What `wtcraft` should provide

### 1. Stable machine protocol

Machine-readable outputs should be stable enough that a GUI, TUI, or daemon can
integrate without scraping human text.

Priority items:

- `wtcraft status --json`
- `wtcraft check --json`
- `wtcraft verify --json`
- `wtcraft capabilities --json`
- explicit schema versioning
- stdout-only JSON in machine mode; diagnostics on stderr
- documented exit codes

### 2. Explicit targeting

Avoid accidental `cwd` coupling.

The machine surface should support explicit repository or worktree targeting so
an external launcher can inspect or verify any registered worktree without
having to `cd` into it first.

### 3. Session sidecar convention

Runtime state is not task-contract state.

Expected local file:

```text
.worktree-session.json
```

Expected contents:

- provider / CLI
- launch mode: `interactive` or `headless`
- running / waiting / idle / exited state
- PID plus process start time
- terminal application and terminal session identifier when interactive
- started, last-active, and exited timestamps
- exit code and optional short summary or log path

This file should stay clone-local and be ignored via Git metadata, not committed
into the repository history.

### 4. Validation rules

The observer should be able to name these failures cleanly:

- task says `executing`, but no live session is present
- session is running in an uncontracted worktree
- PID exists but process start time does not match
- session claims success, but `verify` failed
- headless session exists, but capability discovery says the selected agent or
  launcher cannot support it reliably

## Launch-mode stance

### Interactive first

Default path for GUI clients:

- launch a normal agent CLI in a new terminal/tab/window for the selected
  worktree
- monitor it through Git facts, task contract, and the session sidecar
- allow focus, stop, and retry actions without owning the terminal itself

### Task initialization is a Planner-lite step (deferred)

A tempting one-shot flow: the human types a freeform description, a short
headless call turns it into structured Scope / Off-limits / Steps inside
`.worktree-task.md`, then an interactive TUI takes over to execute. That init
call is the **Planner** role in the stage machine (Orchestrator → Planner →
Executor); the interactive session is the Executor.

It is sound, but it puts a headless dependency in the very first flow, which
ADR-005 defers. Phasing:

- **v1** — `wtcraft new` already copies the task template with `stage`/`role`/
  `agent` backfilled. Launch the interactive TUI directly; let the human or the
  agent's first turn fill Scope/Steps.
- **v2** — insert the headless Planner-lite init step ahead of the TUI.

Gating the TUI on the init step needs no vendor hooks: watch the
`.worktree-task.md` mtime/content plus the headless process exit code
(`exit 0` + expected sections present → launch the TUI). Same vendor-free
liveness signal the observer already relies on.

### Launch mode is a start-time toggle

The sidecar's `launch mode` (interactive | headless) is the GUI's start-time
choice, surfaced to the user, not a hidden setting:

- **interactive** (ships first) — external TUI, human drives, GUI observes.
- **headless / full-auto** (later) — one long `/loop` or `/goal` in auto mode
  until it hits an alarm, then parks for human review; the GUI surfaces only
  acceptance/verification, never keystrokes.

Both modes report through the same task contract + sidecar, so the toggle swaps
the runner, not the observer.

### Headless later

Headless is still attractive for:

- overnight loops
- automated verification
- observer-driven orchestration
- queue or batch execution

But it should be an opt-in mode after the machine protocol is stable. A GUI
that starts headless sessions before it can explain or recover them cleanly
will feel opaque and brittle.

## Non-goals

- embedding a terminal emulator into `wtcraft`
- making `wtcraft` the canonical log store for agent conversations
- forcing every client to become a process supervisor
- tying session monitoring to one vendor's hook or output format

## Related

- [../adr/005-interactive-first-session-launch.md](../adr/005-interactive-first-session-launch.md)
- [stage-state-machine.md](stage-state-machine.md)
- [worktree-layout.md](worktree-layout.md)
- [../sourcegitfork/session-state.md](../sourcegitfork/session-state.md)
