# wtcraft Roadmap

This roadmap is intentionally public-first.
It avoids private assumptions and keeps all tradeoffs explicit.

Last reviewed: 2026-09-11. The latest local release tag is `v0.4.4`;
Phase 6 capabilities below are on `main` and unreleased. Registry publication
and external adoption were not checked in this review.

## Scope Statement

`wtcraft` is a local, Git-native verification harness for worktree tasks.
It does not try to replace coding agents, editors, CI, or hosting platforms.
It provides task specifications, deterministic changeset checks, lifecycle facts,
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
- [x] `wtcraft new <type/name>`: create worktree from base branch + seed task specification
- [x] `wtcraft verify <worktree>`: run verification commands from task specification
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
local task specification + state sidecar
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
- [x] bind Git changeset facts to reviewed policy identity and base revision —
      `scripts/policy_git_adapter.py`; mutable local task state is not authority
- [x] emit policy provenance and authorization evidence through the standalone
      Git adapter; `verify --json` remains the local verification surface
- [x] add `wtcraft init-ci` for a required GitHub Actions check —
      installs the workflow plus the vendored evaluator it runs; the adapter
      ships in the repository because the privileged job must not install
      anything at check time
- [x] document the repository ruleset needed to make that check merge-blocking —
      [GitHub Actions integration](security/github-actions-integration.md)
- [x] add adversarial tests for policy widening, stale base revisions, and missing authorization —
      ten contract cases under `tests/contracts/policy-envelope/`, plus the
      rename-bypass integration test

Remaining before v0.5, in priority order:

1. **P0 — demonstrate the protected authorization workflow.** Use one real
   dogfood repository to exercise reviewed policy creation, an authorized PR,
   an unauthorized PR, an off-limits rename, and a stale authorization. Confirm
   the required check actually blocks a failing merge. Record an older PR after
   its base branch advances as well, to distinguish a valid merge base from a
   stale policy. Preserve evidence for both approvals and denials.
2. **P1 — make setup and maintenance reproducible.** Validate installation from
   release artifacts, policy approval/update instructions, required-check setup,
   denial diagnostics, and vendored evaluator refresh. Follow the action-pinning
   and repository-protection requirements in the integration guide. Record setup
   time, false denials, and policy-maintenance friction.
3. **P1 — release a clearly bounded authorization feature.** Keep the trusted
   adapter and local `verify --json` separate for v0.5. Explain their entry
   points and claims consistently in help, README, release notes, and evidence.
   A shared CLI wrapper may follow a demonstrated usability need; it must not
   make mutable local task specifications authoritative.

A passing protected check proves changeset authorization. Ordinary CI continues
owning test, lint, and build outcomes. Evidence keeps the reviewed plan with
`"status": "not_executed"`, as required by
[ADR-011](adr/011-verification-execution-least-privilege.md).

**Not v0.5 release blockers:** local hooks, lifecycle/FSM commands, a unified
policy/verification CLI, or execution of the reviewed verification plan.
Verification execution remains deferred under ADR-011's pinned-input and
least-privilege constraints. Neither the capability experiment nor its result
is a v0.5 release dependency.

Acceptance criteria:

- an executor cannot silently widen its approved path set and still receive a passing protected-check verdict
- fresh CI evaluates the PR changeset against reviewed policy at a protected source
- a real required check blocks the unauthorized dogfood PR and permits the authorized one
- evidence identifies task, base/head revisions, policy provenance, changed paths, and explicit verification execution status
- setup, policy updates, denial diagnosis, and evaluator refresh are reproducible
- docs distinguish unreleased code, local verification, and protected authorization; an authorization pass never claims tests passed

## Phase 7: Minimal Task Lifecycle (after v0.5.0)

Goal: validate lifecycle facts without becoming an agent orchestrator.

This is not the automatic next implementation step. First address observed
policy creation/update friction, denial diagnostics, and local preflight needs.
Optional bypassable hooks and lifecycle commands follow repeated user demand.

Possible deliverables:

- [x] separate stable `.worktree-task.md` specifications from mutable
      `.worktree-state.json` lifecycle/results
- [x] provide an atomic `wtcraft state` write path with restricted stage/role
      vocabulary and legacy-frontmatter fallback
- [ ] freeze the lifecycle vocabulary and keep `orchestrator` outside the task FSM
- [ ] add legal-transition validation to the state write path
- [ ] derive `responsible_role` and report role mismatch
- [ ] `wtcraft next` returns allowed transitions, responsible role, and blockers only
- [ ] language-neutral contract fixtures for lifecycle behavior

Deferred until there is an active client:

- `fsm --json` as a standalone protocol surface
- GUI-specific state-machine APIs

## Phase 8: Composability and Team UX (evidence-driven)

Two independent evidence tracks order this phase:

- **Authorization adoption:** does a real repository retain the protected check,
  and is its setup and policy-maintenance burden acceptable? Phase 6 dogfooding
  records setup time, false denials, and repeated use.
- **Specification effectiveness:** does showing an agent a task specification improve
  verified outcomes? The bounded experiment in
  [agent-capability-eval.md](backlogs/agent-capability-eval.md) runs in `wteval`.
  First complete a 5–10-task paired pilot with one fixed agent configuration,
  then a report covering at least 30 qualified paired tasks.

A null contract result does not invalidate authorization enforcement. A positive
contract result does not establish demand for policy administration. wtcraft
takes a report citation, not eval code or new semantic evidence fields.

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
