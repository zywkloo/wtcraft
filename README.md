# wtcraft

`wtcraft` is a git-native harness for bounded multi-agent coding in local repositories.

The goal is simple:
- keep agent work isolated with `git worktree`
- make task boundaries explicit with a task contract
- stay lightweight for solo developers who use CLI + any IDE

No hosted platform is required. No custom runtime is required.

## Why

Parallel agents are useful, but raw parallelism creates three common problems:
- context pollution across tasks
- file ownership collisions
- review overload from too many noisy PRs

`wtcraft` focuses on boundaries and sequencing, not maximum concurrency.

## Core Model

1. Planner defines a bounded task contract.
2. Executor works only inside that contract.
3. Verifier checks scope, off-limits, and completion gates.
4. Finisher handles push/PR/cleanup.

This supports a DAG workflow:
- merge shared foundation tasks first
- run file-disjoint tasks in parallel
- serialize tasks that touch shared files

## Project Status

Early public bootstrap.

Current scope:
- open documentation for workflow and roadmap
- starter contract and command specs
- CLI MVP to follow (`init`, `status`, `check`)

## Docs

- [Roadmap](./docs/roadmap.md)
- [Principles](./docs/principles.md)

## License

TBD
