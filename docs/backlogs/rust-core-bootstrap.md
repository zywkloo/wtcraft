# Rust core bootstrap

> Status: in progress. Started 2026-06-13 on `feat/rust-core-mvp`.

## Goal

Establish a small, reviewable Rust core that encodes wtcraft's protocol rules
without replacing the Bash CLI or introducing process and Git side effects.

## MVP deliverables

- [x] Cargo workspace with a pure `wtcraft-core` crate
- [x] typed task stage, responsible role, and transition-owner models
- [x] typed session state and transition validation
- [x] deterministic reconciliation alarms
- [x] unit tests for the first protocol invariants
- [x] CI formatting and test gate
- [ ] shared JSON fixtures from `docs/protocol/contract-tests.md`
- [ ] fixture runner usable by both Bash and Rust adapters

## Collaboration split

A new contributor should begin with the
[Rust Core First Contribution](../onboarding/rust-core-first-contribution.md)
guide.

A new contributor can work independently on one of these bounded areas:

1. Add pure JSON contract fixtures for task transitions and reconciliation.
2. Add `.worktree-task.md` parsing behind fixture tests.
3. Add session-record fixture coverage and validation errors.
4. Review protocol/model mismatches discovered by typed implementation.

Avoid starting Git execution, process supervision, a daemon, or CLI replacement
until shared fixtures cover the relevant behavior.

## Completion gate

The bootstrap phase is complete when:

- every legal task and session transition has a fixture
- representative illegal transitions have fixtures
- every named reconciliation alarm has a fixture
- Rust tests consume the shared fixture schema directly
- Bash remains the default installed implementation

After that, open a separate decision and implementation task for the first
side-effecting adapter.
