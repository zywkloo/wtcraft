# ADR: Rust for the extracted wtcraft core

## Status

Accepted. Recorded 2026-06-13.

Supersedes the deferred language decision in
[003-rust-migration.md](003-rust-migration.md).

## Context

`wtcraft` is growing from a Bash helper into a governance core consumed by
multiple frontends, beginning with `wtflow`. The core must remain stable while
external clients launch and observe multiple agent sessions across worktrees.

The language choice is no longer primarily about performance or native Windows
support. It is about making protocol, lifecycle, process identity, recovery,
and concurrency rules explicit enough that the core behaves predictably under
long-running multi-session use.

Go and Rust were considered:

- Go would produce a process supervisor or observer quickly and has a simple
  deployment story.
- Rust provides stronger typed models for protocol versions, lifecycle
  transitions, process identity, and error handling, with no runtime dependency.

## Decision

The extracted cross-platform wtcraft core will be implemented in **Rust**.

This is a language decision, not authorization for an immediate rewrite. The
current Bash implementation remains authoritative until the contracts it
implements are stable and covered by compatibility tests.

Rust extraction begins only after these v1 contracts are clear:

1. [Machine Protocol v1](../protocol/machine-protocol-v1.md)
2. [Session Model v1](../protocol/session-model-v1.md)
3. [Task State Machine v1](../protocol/task-state-machine-v1.md)

## Core boundary

The Rust core may own:

- repository and worktree discovery
- task-contract parsing and validation
- lifecycle transition validation
- scope and off-limits checks
- verification execution and structured results
- session-state parsing, validation, and reconciliation
- stable JSON protocol and exit-code behavior

The Rust core does not own:

- a terminal emulator
- agent-specific conversation history
- GUI layout or rendering
- vendor-specific TUI output parsing as a source of truth
- Git hosting workflows such as PR review or merge policy

## Migration strategy

Migration is incremental and contract-first:

1. Freeze the v1 protocol documents and add fixtures/contract tests.
2. Implement typed Rust models and parsers behind tests without changing the
   installed CLI behavior.
3. Port pure validation and reconciliation logic first.
4. Port process execution and Git operations only after behavioral parity.
5. Replace the Bash entrypoint only when all supported commands pass the same
   compatibility suite.

The public `wtcraft` and `wtc` command names remain stable. A Rust implementation
must preserve existing human output where practical and the documented machine
protocol exactly.

## Why Rust

- Lifecycle transitions and protocol variants become typed enums rather than
  loosely coordinated strings.
- Session identity and reconciliation failures can be modeled explicitly.
- A single native binary works across macOS, Linux, and Windows.
- The same core can serve a CLI, a future daemon, and GUI integrations without
  moving governance truth into any one frontend.
- Rust's stricter failure handling supports the goal of a stable multi-session
  observer better than adding more implicit shell conventions.

The [`observe` reconciliation surface](../protocol/machine-protocol-v1.md)
makes the boundary concrete. Bash ships `observe --json` as a one-shot,
level-triggered command (pull). Edge-triggered push — continuous liveness plus
transitions streamed over SSE — needs the persistent process, filesystem and
process event subscriptions, and concurrency that are awkward or simply absent
in shell. The Rust core adds that delivery *behind* `capabilities --json`
without changing the `observe --json` output schema clients already bind to: the
contract is permanent, only the transport is added. This is the extraction's
clearest motivating case, and it is additive — it does not invalidate the Bash
one-shot.

## Consequences

- Rust is the committed long-term core language.
- Bash remains the shipping implementation for now.
- Protocol changes require documentation and contract-test updates before Rust
  implementation work.
- GUI clients integrate through the machine protocol and local state files, not
  through Rust-specific APIs.
- A daemon remains optional; choosing Rust does not imply that wtcraft must
  become a background service.

## Rejected alternatives

### Go core

Go remains a strong choice for quickly building a daemon, but speed of initial
implementation is less important than a strict long-lived governance model.
Choosing Go now would not remove the need to stabilize the same contracts first.

### Immediate big-bang rewrite

Rejected because the existing behavior is still defining the protocol. Rewriting
before the contracts settle would move ambiguity into Rust rather than remove it.

### Keep Bash permanently

Bash remains useful as the reference implementation, but typed parsing,
cross-platform process identity, and lifecycle reconciliation are increasingly
awkward to evolve safely in shell.
