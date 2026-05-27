# wtcraft Roadmap

This roadmap is intentionally public-first.
It avoids private assumptions and keeps all tradeoffs explicit.

## Scope Statement

`wtcraft` is a local harness for git worktree task orchestration.
It does not try to replace coding agents, editors, CI, or hosting platforms.
It provides a contract and guardrail layer for parallel task execution.

## Phase 0: Bootstrap (Done)

- Create public repository structure
- Publish vision and constraints
- Publish implementation roadmap

## Phase 1: MVP (Target: 1-3 hours)

Status: completed

Goal: usable with near-zero setup, no package manager install.

Deliverables:
- [x] `scripts/wtcraft` shell entrypoint
- [x] `wtcraft init`: scaffold harness files into a target repo
- [x] `wtcraft status`: list active worktree task files and statuses
- [x] `wtcraft check <worktree>`: compare changed files against Scope and Off-limits
- [x] `.agent-harness/` starter docs and templates

Out of scope:
- npm or Homebrew packaging
- automated PR creation
- cross-platform hardening

## Phase 2: Practical Solo-Dev Tooling (Target: half day)

Status: in progress

Goal: good day-to-day workflow for a single developer using multiple agents.

Deliverables:
- [x] `wtcraft new <type/name>`: create worktree from base branch + seed task contract
- [x] `wtcraft verify <worktree>`: run verification commands from task contract
- [x] cleaner parser for task sections
- [x] minimal test fixtures for parser and scope checks
- [x] docs for Claude/Codex role split:
  - planner
  - executor
  - finisher

Next in Phase 2:
- [ ] `check` matching improvements for scoped patterns
- [ ] richer `verify` output for easier CI diagnostics

## Phase 3: Public Package (Target: 1-2 days)

Status: in progress

Goal: easy install and repeatable behavior across machines.

Deliverables:
- package distribution (`npm` first)
- semantic versioning and changelog
- [x] CI checks (lint + tests)
- command help and error messages
- migration notes for existing repos
- [x] optional routing-stub injection for existing `CLAUDE.md` / `AGENTS.md`

Routing-stub policy:
- default: do not modify `CLAUDE.md` or `AGENTS.md`
- opt-in only: `--patch-agent-files`
- append-only managed block with markers for safe rollback
- never overwrite existing agent instructions

## Phase 4: Integrations (Target: incremental)

Goal: stay composable with existing tools.

Possible integrations:
- `workmux` session orchestration
- GitHub PR template generation
- local dashboard-style status output

Non-goals:
- replacing native git
- replacing agent CLIs
- creating a hosted control plane

## Design Constraints

- Git-native first
- Local-first first
- Public-docs first
- Bounded automation over opaque autonomy
- Explicit ownership over implicit behavior

## Naming and Branding

Working name: `wtcraft`.

Positioning:
- "craft bounded multi-agent workflows with git-native worktrees"

## Contributor Note

The first stable release should prioritize:
1. clear boundaries
2. trustworthy checks
3. minimal setup cost

Fancy orchestration should wait until those three are solid.
