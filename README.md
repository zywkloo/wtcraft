# wtcraft - Worktree Craft

`wtcraft` is a lightweight, git-native harness for solo developers orchestrating multiple coding agents on a limited budget.

The goal is simple:
- keep agent work isolated with `git worktree`
- make agent handoffs explicit with a task contract
- keep file and task boundaries easy to verify
- stay usable from CLI + any IDE

No hosted platform is required. No custom runtime is required.

## Why

Parallel agents are useful, but raw parallelism creates four common problems:
- unclear handoff between planner and executor agents
- context pollution across tasks
- file ownership collisions
- review overload from too many noisy PRs

`wtcraft` focuses on handoff, boundaries, and budget-aware sequencing, not maximum concurrency.

For the design story behind this project, read:
[Beyond Worktrees: A Budget-Aware Multi-Agent Coding Harness for Solo Developers](https://zywkloo.github.io/blog/beyond-worktrees-budget-aware-multi-agent-coding-harness/).

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
- CLI MVP available (`init`, `status`, `check`)

## Quick Start

Run directly from the repo:

```bash
chmod +x scripts/wtcraft
./scripts/wtcraft init
./scripts/wtcraft init --patch-agent-files
./scripts/wtcraft new feat/my-task
./scripts/wtcraft status
./scripts/wtcraft check <worktree-name-or-path>
./scripts/wtcraft verify <worktree-name-or-path>
```

What `init` scaffolds:
- `.agent-harness/planner.md`
- `.agent-harness/executor.md`
- `.agent-harness/finisher.md`
- `.claude/commands/planwt.md`
- `.claude/commands/finishwt.md`
- `.worktree-task.template.md`

`init` is non-destructive: existing files are not overwritten.
By default `init` does not modify `CLAUDE.md` or `AGENTS.md`.
Use `--patch-agent-files` to append managed routing stubs to existing files.

`new` defaults to base branch `develop`. Set `WTCRAFT_BASE_BRANCH=main` (or another branch) when needed.

## Docs

- [Roadmap](./docs/roadmap.md)
- [Principles](./docs/principles.md)

## Testing

```bash
chmod +x tests/smoke.sh
tests/smoke.sh
```

## License

Apache-2.0. See [LICENSE](./LICENSE).
