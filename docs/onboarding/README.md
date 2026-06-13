# Contributor Onboarding

Welcome to wtcraft. This page is the shortest path from a fresh clone to
understanding the project well enough to make a bounded contribution.

## What wtcraft is

wtcraft is a Git-native governance layer for worktree-based agent coding. It
keeps three kinds of facts separate:

1. **Task intent:** `.worktree-task.md` declares scope, off-limits files,
   verification commands, lifecycle stage, and the responsible role.
2. **Runtime observation:** `.worktree-session.json` describes a local agent
   process attached to a worktree.
3. **Repository facts:** Git reports the actual worktrees and changes.

wtcraft checks and reconciles those facts. It does not silently repair them,
own agent conversations, or replace Git.

The currently installed `wtcraft` / `wtc` command is implemented in Bash. A
small Rust core is being introduced incrementally to encode governance rules as
typed, reusable pure logic.

## Why Rust

The long-term core must behave predictably while several frontends and agent
sessions observe the same worktrees. Rust helps make protocol versions, state
transitions, process identity, and failure cases explicit.

Rust is not being used for a big-bang rewrite. The Bash CLI remains the
reference implementation until both implementations pass shared contract
fixtures.

Read [ADR-006](../adr/006-rust-core-extraction.md) for the full decision.

## Current workspace state

Development is currently stacked:

```text
main
  └── feat/machine-protocol-v1     PR #33: protocol contracts + Bash machine API
        └── feat/rust-core-mvp     PR #34: pure Rust governance core
```

PR #34 deliberately depends on PR #33. After #33 merges, #34 will be rebased or
retargeted to `main`.

The Rust MVP currently provides:

- typed task stages, roles, and transition owners
- typed session states and transition validation
- validation for session records
- deterministic reconciliation alarms
- Rust formatting, tests, and clippy in CI

It does **not** parse task frontmatter, execute Git, inspect live processes,
launch agents, implement a daemon, or replace the Bash CLI.

## Start here

Read these documents in order:

1. [Rust Core First Contribution](rust-core-first-contribution.md)
2. [Rust Core Architecture](../architecture/rust-core.md)
3. [Protocol Contracts](../protocol/README.md)
4. [Rust Core Bootstrap Backlog](../backlogs/rust-core-bootstrap.md)

The first two are enough before making a small test-only contribution.

## Local setup

Required tools:

- Git
- Bash
- Rust `1.82` or newer

Install Rust using [rustup](https://rustup.rs/) or your platform package
manager. Then verify the workspace:

```bash
rustc --version
cargo --version
cargo fmt --check
cargo test --workspace
cargo clippy --workspace --all-targets -- -D warnings
bash tests/run_all.sh
```

The Rust commands validate the new core. The Bash suite confirms that core work
has not changed the shipping CLI.

## Contribution workflow

While PR #34 is open, base Rust-core contributions on
`origin/feat/rust-core-mvp`:

```bash
git fetch origin
git switch -c test/rust-session-transition-matrix origin/feat/rust-core-mvp
```

Using a separate Git worktree is recommended but not required:

```bash
git worktree add ../wtcraft-session-tests \
  -b test/rust-session-transition-matrix \
  origin/feat/rust-core-mvp
```

Keep the first PR narrow. Run the Rust checks and Bash suite before pushing.

## Ask before expanding scope

Pause and discuss before adding:

- Git or operating-system process execution to `wtcraft-core`
- a new crate
- a daemon or background service
- changes to the public machine protocol
- changes to the installed Bash CLI
- automatic state repair

These are valid future directions, but each needs contract coverage and an
explicit ownership decision first.
