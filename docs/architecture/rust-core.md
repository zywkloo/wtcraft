# Rust Core Architecture

## Purpose

The Rust core makes wtcraft's governance rules reusable and predictable without
moving frontend or process-supervision concerns into the core.

The Bash CLI remains the shipping reference implementation. Rust is introduced
incrementally behind the contracts in `docs/protocol/`.

## Dependency direction

```text
future CLI / daemon / wtflow adapter
                 |
          future integration crates
                 |
           wtcraft-core
      pure models and decisions
```

`wtcraft-core` is the innermost crate. It must not depend on a CLI, Git
subprocesses, terminal APIs, agent providers, or a GUI.

## MVP boundary

The first `wtcraft-core` crate owns:

- typed task stages, roles, and transition owners
- typed session states and transition validation
- session-record validation that does not inspect the operating system
- deterministic reconciliation of task, session, and Git facts into alarms

The MVP does not own:

- parsing `.worktree-task.md` frontmatter
- reading or writing `.worktree-session.json`
- discovering repositories or worktrees
- checking live process identity
- executing verification commands
- implementing the installed `wtcraft` / `wtc` CLI

Those capabilities require adapters around the pure core and must preserve the
machine protocol and shared contract fixtures.

## Modeling rules

- Distinguish the role currently responsible for a stage from the owner
  authorized to perform a transition.
- Treat human approval as a transition precondition; the finisher remains the
  single writer that records `verifying -> approved`.
- Represent unknown future protocol values as explicit compatibility outcomes;
  never silently map them to known variants.
- Reconciliation reports facts and alarms. It does not repair task, session, or
  Git state.
- Alarm order is deterministic because machine clients and contract fixtures
  consume it.
- Process identity requires PID plus process start time; PID alone is never
  accepted as exact identity.

## Crate evolution

Add a crate only when it creates a real ownership boundary:

```text
crates/
  wtcraft-core/       # pure models, validation, reconciliation
  wtcraft-git/        # future Git/worktree fact adapter
  wtcraft-cli/        # future machine-protocol adapter
```

The first extraction target after the MVP should be contract-fixture adapters,
not a replacement CLI.
