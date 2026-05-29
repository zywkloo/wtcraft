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

Status: completed

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
- [x] `check` matching improvements for scoped patterns (glob: `*.md`, `src/**/*.ts`)
- [x] richer `verify` output for easier CI diagnostics (timing, exit codes, summary table)

## Phase 3: Public Package (Target: 1-2 days)

Status: completed

Goal: easy install and repeatable behavior across machines.

Deliverables:
- [x] package distribution (`npm` first) — `package.json` with `bin` field
- [x] semantic versioning and changelog — `CHANGELOG.md` (keep-a-changelog format)
- [x] CI checks (lint + tests)
- [x] command help and error messages — `wtcraft help [command]`
- [x] migration notes for existing repos — `docs/migration.md`
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

## Phase 5: Layered Multi-Agent Orchestration (v0.4.0)

Goal: Enable high-efficiency, budget-aware multi-agent team hierarchies.

> [!IMPORTANT]
> **Milestone Status**:
> - **Gemini Support & Orchestrator Routing**: Not yet wired up in the current release. Slated for the next version (`v0.4.0`).
> - **Token Telemetry**: Currently incomplete/in-progress and pending implementation in the next release.

### The Team Architecture:
- **Orchestrator Agent (e.g., Gemini 3.5 Flash)**: Low-latency, tool-heavy, cross-repository status tracking, environment setup, and release management coordinator.
- **Planner Agent (e.g., Claude Opus / GPT-5.5)**: High-reasoning, session-based strategic task architect responsible for analyzing requirements and writing the task contract (`.worktree-task.md`).
- **Executor Agent (e.g., GPT-5.3-codex / Claude Sonnet)**: Highly focused, budget-friendly coder working strictly inside sandboxed worktrees under contract guardrails.
- **Finisher Agent (e.g., Gemini Flash / Claude Haiku)**: Verification and cleanup script runner.

### Deliverables:
- [ ] **Orchestrator Guides**: Prompt and configuration files for fast, cross-repo Orchestrator agents.
- [ ] **Dual-Tier Commands**: Clear division between *Strategic Actions* (Slash commands for high-level workflow orchestration) and *Tactical Actions* (direct atomic CLI commands).
- [ ] **Context-Gathering Pipings**: Tooling to easily extract cross-repo states gathered by the Orchestrator and present them cleanly to the high-reasoning Planner.


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
