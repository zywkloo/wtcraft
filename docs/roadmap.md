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

Status: in progress on `main`, unreleased. The schema, reference evaluator,
Git adapter, adversarial fixtures, and the `init-ci` enforcement point exist.
What a passing verdict is allowed to claim is still narrower than it looks; see
the remaining items below.

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

- [x] document the threat model and policy-authority boundary —
      [threat model](security/threat-model.md), [ADR-009](adr/009-policy-authority.md)
- [x] define a reviewed policy-envelope schema separate from mutable local task state —
      [policy-envelope-v1](protocol/policy-envelope-v1.md)
- [x] bind local worktree state to a policy identity and base revision —
      `scripts/policy_git_adapter.py`
- [ ] teach the existing JSON verifier to emit policy provenance and evidence —
      partial: the standalone adapter emits provenance-bearing evidence, but
      `scripts/wtcraft` itself has no policy awareness and `verify --json` is
      unchanged. The two are not yet one surface.
- [x] add `wtcraft init-ci` for a required GitHub Actions check —
      installs the workflow plus the vendored evaluator it runs; the adapter
      ships in the repository because the privileged job must not install
      anything at check time
- [x] document the repository ruleset needed to make that check merge-blocking —
      [GitHub Actions integration](security/github-actions-integration.md)
- [ ] add optional local hook installation for fast feedback, explicitly documented as bypassable —
      not started
- [x] add adversarial tests for policy widening, stale base revisions, and missing authorization —
      ten contract cases under `tests/contracts/policy-envelope/`, plus the
      rename-bypass integration test

Remaining before v0.5:

1. **The CLI still does not know about policy.** `scripts/wtcraft` has no
   policy code path; `verify --json` is unchanged, and provenance-bearing
   evidence comes only from the standalone adapter. Deciding whether these
   become one surface, or stay deliberately separate so the trusted evaluator
   keeps no dependency on the local task contract, is the open question.
2. **Local hooks are not installed.** Fast local feedback, documented as
   bypassable, is still unbuilt.
3. **Verification is authorized but never executed.** Evidence reports the
   reviewed plan with `"status": "not_executed"`.
   [ADR-011](adr/011-verification-execution-least-privilege.md) settles why: a
   sandbox cannot make a command the adversary wrote report truthfully, so
   execution is only evidence once the reviewed policy also pins the plan's
   inputs. The ADR records the precondition and the two constraints on any
   implementation; it does not schedule the work.

Until item 3 lands, a passing check proves the changeset was authorized and
says nothing about whether the tests passed. Every surface that shows the
verdict is expected to say so.

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

The evidence this phase is ordered by does not exist yet. The nearest source is
the deterministic-oracle experiment in
[agent-capability-eval.md](backlogs/agent-capability-eval.md), whose contract
arm measures whether a task contract changes verified outcomes at all. It runs
in `wteval` and reports back here; wtcraft takes the result, not the code. A
null result would be worth knowing before building anything below.

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
