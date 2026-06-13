# Rust Core First Contribution

This guide assumes you know basic programming but may be new to Rust and new to
wtcraft.

## Your mental model

`wtcraft-core` is a decision library:

```text
facts in -> typed validation/reconciliation -> decisions and alarms out
```

It is intentionally boring about side effects. It does not run Git commands,
touch files, launch agents, or inspect the operating system. Adapters will do
those things later and pass facts into the core.

This boundary makes the core easy to test and safe for a new contributor to
change.

## Code map

```text
Cargo.toml
  Rust workspace definition and shared dependency versions

crates/wtcraft-core/src/lib.rs
  Public exports; start here to see the supported surface

crates/wtcraft-core/src/task.rs
  TaskStage, Role, legal task transitions, and transition writers

crates/wtcraft-core/src/session.rs
  SessionState, SessionRecord, transition rules, and record validation

crates/wtcraft-core/src/reconciliation.rs
  Converts task/session/Git facts into deterministic alarms
```

The corresponding contracts live in:

- `docs/protocol/task-state-machine-v1.md`
- `docs/protocol/session-model-v1.md`
- `docs/protocol/contract-tests.md`

When code and protocol disagree, do not guess which is right. Open a discussion
or PR note describing the mismatch.

## Tiny Rust glossary

You only need a small part of Rust for the first contribution:

| Rust term | Meaning here |
|---|---|
| `enum` | A closed set of protocol values such as task stages |
| `struct` | A group of named facts such as `SessionRecord` |
| `Option<T>` | A value that may be absent |
| `Result<T, E>` | Success value or an explicit error |
| `match` | Exhaustive branching over enum values |
| `derive` | Generates standard behavior such as equality or JSON parsing |
| `#[test]` | Marks a function as a unit test |
| `cargo test` | Compiles and runs Rust tests |
| `cargo fmt` | Applies/checks standard Rust formatting |
| `cargo clippy` | Reports suspicious or unidiomatic Rust |

Rust's compiler messages are part of the development loop. Read the first error,
make the smallest correction, and rerun the command.

## Recommended first task

**Complete the session transition matrix tests.**

Why this is a good first contribution:

- it requires reading the session protocol without designing new behavior
- it teaches enums, arrays, loops, `assert!`, and `assert_eq!`
- it catches protocol drift
- it changes tests only, so the blast radius is small

Scope:

```text
crates/wtcraft-core/src/session.rs
```

Add tests that prove:

1. every allowed transition in Session Model v1 returns `true`
2. representative rejected transitions return `false`
3. no terminal/lost state restarts without transitioning to `starting`
4. live states are exactly `starting`, `running`, `waiting`, and `idle`

Do not change `SessionState::allows_transition` unless a test exposes a real
disagreement with the protocol. If that happens, document the mismatch first.

## How to work

Create a branch from the Rust MVP:

```bash
git fetch origin
git switch -c test/rust-session-transition-matrix origin/feat/rust-core-mvp
```

Run the focused tests while editing:

```bash
cargo test -p wtcraft-core session
```

Before opening the PR, run:

```bash
cargo fmt --check
cargo test --workspace
cargo clippy --workspace --all-targets -- -D warnings
bash tests/run_all.sh
```

Open the PR against `feat/rust-core-mvp` while PR #34 remains stacked. Mention
which Session Model v1 rules the tests cover.

## What success looks like

A strong first PR is small:

- one behavioral area
- tests that name protocol rules clearly
- no new dependencies
- no unrelated formatting or refactors
- all Rust and Bash checks green

After that, good follow-up areas are shared JSON fixtures, session-record
validation cases, and reconciliation alarm fixtures.
