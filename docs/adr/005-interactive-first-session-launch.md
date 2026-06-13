# ADR: Interactive-first session launch

## Status

Accepted. Recorded 2026-06-13.

## Context

Future GUI clients such as `wtflow` may offer a one-shot flow:

1. user enters a prompt
2. user chooses an agent
3. the client runs `wtc new <task>`
4. a session starts immediately in the new worktree
5. the GUI monitors task and runtime state

There are two plausible launch modes:

- **interactive external TUI**: open a new terminal/tab/window in the worktree
  and launch `codex`, `claude`, `agy`, or another CLI directly
- **headless loop session**: start the agent in the background and let the GUI
  act as the main control surface

`wtcraft` is a governance core, not a terminal emulator or vendor-specific
agent runner. The choice here should optimize for transparency, recoverability,
and low vendor coupling.

## Decision

### 1. Default launch mode is interactive external TUI

The first-class path for GUI integrations is:

- create or select the worktree
- launch a normal terminal-hosted agent session in that worktree
- let the GUI observe and manage at arm's length

The GUI may open a new terminal tab/window, a terminal pane, or focus an
existing session, but the agent remains in its native interactive CLI.

### 2. `wtcraft` owns contracts and machine protocol, not the terminal

`wtcraft` remains responsible for the stable file and CLI surface:

- `.worktree-task.md` for declared task contract and lifecycle
- stable JSON / exit-code protocol for `status`, `check`, `verify`, and
  capability discovery
- deterministic repository and worktree targeting

Launchers or GUIs own volatile runtime state such as PID, terminal identity,
and recent activity through a local session sidecar (see related backlog and
SourceGit fork notes).

### 3. Headless is allowed later, but it is a secondary mode

Headless sessions are useful for automation, batch verification, and future
observer-driven orchestration, but they are not the default UX target.
Interactive launch ships first; headless can be added later as an optional
advanced mode once the machine protocol and session-state conventions are
stable.

## Rationale

### Why interactive-first

- **Transparency**: the user can see the agent's native output and behavior
  instead of trusting a background black box.
- **Human takeover**: when the agent stalls or needs intervention, the user is
  already in the right place to continue manually.
- **Vendor compatibility**: current agent CLIs are optimized for interactive
  use; headless support is uneven and more brittle across vendors.
- **Faster MVP**: GUI clients can launch useful sessions without building a
  terminal emulator, process broker, or log-streaming subsystem.

### Why not headless-first

Headless execution increases observability requirements immediately:

- reliable process-state tracking
- structured logs or summaries
- clearer failure and waiting states
- stronger guarantees around resume, cancel, and takeover

Those are good future capabilities, but they depend on protocol work that is
more important than inventing a runner.

## Consequences

- GUI clients should treat external TUI sessions as the primary runtime model.
- The next `wtcraft` investments are stable JSON, explicit targeting, session
  sidecar conventions, and capability discovery.
- `wtcraft` should not grow into a terminal multiplexer or GUI-owned terminal.
- A future `headless` mode remains compatible with this decision because both
  modes report through the same file/protocol surface.

## Related

- [../backlogs/session-runtime-protocol.md](../backlogs/session-runtime-protocol.md)
- [../backlogs/stage-state-machine.md](../backlogs/stage-state-machine.md)
- [../sourcegitfork/session-state.md](../sourcegitfork/session-state.md)
- [001-task-contract-local-state.md](001-task-contract-local-state.md)
