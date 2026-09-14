# Protocol contracts

These documents define the implementation-independent boundary of the wtcraft
core:

- [Machine Protocol v1](machine-protocol-v1.md): CLI JSON, errors, exit codes,
  capability discovery, and explicit repository targeting
- [Session Model v1](session-model-v1.md): local runtime identity, liveness,
  ownership, transitions, and recovery
- [Task State Machine v1](task-state-machine-v1.md): declared governance
  lifecycle, legal writers, transitions, invariants, and observer alarms
- [Task State Sidecar v1](task-state-sidecar-v1.md): JSON lifecycle/result
  persistence, writers, compatibility, and evidence freshness
- [Contract Test Specification](contract-tests.md): shared fixture format,
  comparison rules, minimum coverage, and Bash/Rust compatibility gates

The Bash CLI is the current reference implementation. The future Rust core must
preserve these contracts rather than expose implementation-specific behavior to
clients.

## Relationship

```text
.worktree-task.md     .worktree-state.json       git facts
task specification   lifecycle + latest results actual changes
          \                    |                    /
           +---------- status/reconciliation ------+
                              |
                      machine protocol v1
                              |
                   CLI / future clients
```

The task specification describes what should be done. The sidecar records what
has happened. Both are advisory local files; neither is a protected policy or
sandbox. Session/process monitoring remains a separate proposed concern and is
not required by the shipped task-state path.

No source silently repairs another source. Reconciliation produces named,
rule-backed results for humans and clients to act on.

## Rust extraction readiness

Rust implementation work may begin incrementally now, but the Bash CLI remains
authoritative until these readiness items are complete:

- protocol fixtures cover success, gate failure, and fatal error shapes as
  defined by the [Contract Test Specification](contract-tests.md)
- session fixtures cover every state and identity-loss recovery
- state-machine tests cover every legal and illegal transition
- unknown fields/states have explicit compatibility behavior
- Bash and Rust implementations pass the same contract suite
- the installed `wtcraft` / `wtc` interface remains stable

See [ADR-006](../adr/006-rust-core-extraction.md) for the language and migration
decision.
