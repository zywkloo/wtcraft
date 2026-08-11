# wtcraft Roadmap

This roadmap is intentionally public-first.
It avoids private assumptions and keeps all tradeoffs explicit.

## Scope Statement

`wtcraft` is a local, Git-native verification harness for worktree tasks.
It does not try to replace coding agents, editors, CI, or hosting platforms.
It provides task contracts, deterministic changeset checks, lifecycle facts,
and evidence that other tools can consume.

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

## Phase 5: Governance Foundation (v0.4.0-v0.4.3)

Status: completed release line

Goal: establish a useful local verification core before adding enforcement or
automation.

Delivered:

- [x] `check` covers committed, staged, unstaged, and untracked changes
- [x] stable `check --json` and `verify --json` machine output
- [x] verification results written back to local task state
- [x] `stage:` / `role:` conventions and status visibility
- [x] `status --json`, `capabilities --json`, and machine protocol v1
- [x] role-model configuration and generated provider presets
- [x] language-policy scaffolding and LLM anti-pattern guidance
- [x] `doctor` / `migrate` and macOS Bash 3.2 portability fixes

The v0.4.x line does **not** provide runtime role routing, automatic agent
launching, token telemetry, immutable task authorization, Git-hook
enforcement, or a required CI merge gate. Role and model files are editable
guidance; stage and role fields are currently reported facts rather than a
security boundary.

## Phase 6: Trusted Change Authorization (target: v0.5.0)

Goal: bind a reviewed task authorization to a Git changeset and produce a
verifiable verdict at a protected merge boundary.

Trust model:

```text
local task working state
        |
        v
reviewed policy envelope
  task id + base SHA + allowed paths + verification + approver + digest
        |
        v
protected required check
        |
        v
merge verdict + evidence
```

Deliverables:

- [ ] document the threat model and policy-authority boundary
- [ ] define a reviewed policy-envelope schema separate from mutable local task state
- [ ] bind local worktree state to a policy identity and base revision
- [ ] teach the existing JSON verifier to emit policy provenance and evidence
- [ ] add `wtcraft init-ci` for a required GitHub Actions check
- [ ] document the repository ruleset needed to make that check merge-blocking
- [ ] add optional local hook installation for fast feedback, explicitly documented as bypassable
- [ ] add adversarial tests for policy widening, stale base revisions, and missing authorization

Acceptance criteria:

- an executor cannot silently widen its approved path set and still receive a passing protected-check verdict
- CI evaluates the PR changeset against an available, reviewed source of policy
- a passing result identifies the task, base revision, policy digest, changed paths, and verification outcome
- docs distinguish local feedback from remote merge enforcement

## Phase 7: Minimal Task Lifecycle (after v0.5.0)

Goal: validate lifecycle facts without becoming an agent orchestrator.

Possible deliverables:

- [ ] freeze the lifecycle vocabulary and keep `orchestrator` outside the task FSM
- [ ] `wtcraft stage <task> <new-stage>` with legal-transition validation
- [ ] derive `responsible_role` and report role mismatch
- [ ] `wtcraft next` returns allowed transitions, responsible role, and blockers only
- [ ] language-neutral contract fixtures for lifecycle behavior

Deferred until there is an active client:

- `fsm --json` as a standalone protocol surface
- GUI-specific state-machine APIs

## Phase 8: Composability and Team UX (evidence-driven)

Potential work, ordered by demonstrated users rather than novelty:

- MCP access to stable `check` / `verify` / status facts
- GitHub or GitLab integration around approval identity and evidence retention
- cross-repository audit and policy distribution
- dashboard or wtflow integration when an active client needs it

## Explicitly Deferred

- role-to-model recommendation and quota-aware model selection
- token-usage dashboards already served by dedicated tools
- automatic model routing, process launching, and agent scheduling
- hosted control plane
- Rust migration before distribution or performance requires it
- proprietary team features before external teams validate the open verifier


## Design Constraints

- Git-native first
- Local-first first
- Public-docs first
- Verified authorization over opaque autonomy
- Explicit ownership over implicit behavior

## Naming and Branding

Working name: `wtcraft`.

Positioning:
- "verify authorized agent changes at the Git boundary"

## Contributor Note

The next stable milestone should prioritize:
1. clear boundaries
2. trustworthy policy provenance
3. protected merge evidence
4. minimal setup cost

Orchestration and model routing remain outside the core until those properties
are solid and users demonstrate a need.
