# Task State Machine v1

## Purpose

The task state machine defines the declared governance lifecycle of one
worktree task. Its canonical state lives in `.worktree-task.md` frontmatter.

This model is independent of terminal layout, agent vendor, and session
launcher. Runtime facts belong to [Session Model v1](session-model-v1.md).

## Canonical fields

Required lifecycle fields:

```yaml
stage: planned
role: executor
agent: codex
```

- `stage` is the current governance lifecycle state.
- `role` is the single role allowed to write the task contract at this stage.
- `agent` identifies the assigned CLI/provider and is descriptive, not an
  authorization boundary.

The legacy `status` field may be displayed as a fallback when `stage` is
missing, but it does not participate in transition validation.

## Stages and owners

| Stage | Owning role | Meaning |
|---|---|---|
| `planned` | planner | Contract is ready for execution |
| `executing` | executor | Scoped implementation work is active |
| `verifying` | verifier | Implementation is under verification |
| `replan` | planner | Verification or scope discovery requires a new plan |
| `approved` | verifier | Verification passed and human approval was recorded |
| `finishing` | finisher | Merge/cleanup handoff is active |
| `done` | none | Terminal lifecycle state |

One stage has one legal writer. That single-writer rule is the concurrency
protocol for `.worktree-task.md`.

## Allowed transitions

```text
planned   -> executing
executing -> verifying
verifying -> replan | approved
replan    -> planned
approved  -> finishing
finishing -> done
```

No other transition is legal in v1.

Each transition must be deliberate and attributable to the role that owns the
source stage. A frontend may request a transition, but wtcraft validates it
against this table before writing.

## Transition preconditions

| Transition | Minimum precondition |
|---|---|
| `planned -> executing` | Contract has Scope, Off-limits, and Verification sections |
| `executing -> verifying` | Executor handoff is complete |
| `verifying -> replan` | Verification or review found actionable failure |
| `verifying -> approved` | Verification passed and required human gate is satisfied |
| `replan -> planned` | Planner issued the revised contract |
| `approved -> finishing` | Finisher accepted the approved handoff |
| `finishing -> done` | Finish checks and required cleanup completed |

V1 documents these preconditions. Not every precondition is automatically
enforced yet.

## Invariants

- `done` is terminal.
- `approved` cannot be reached without successful verification evidence.
- Work that changes tracked or untracked files before `executing` is a bypass
  signal.
- Scope and Off-limits changes after execution begins require a `replan`
  transition and planner ownership.
- The task contract is local worktree state and must not be committed.
- Runtime session state never authorizes or performs a task-stage transition.

## Observer alarms

An observer reconciles declared task state with Git and session facts. Every
alarm cites a rule in this document or the task contract.

| Alarm | Trigger | Severity |
|---|---|---|
| `illegal-transition` | Observed stage transition is not in the table | violation |
| `bypass` | Pre-execution stage has code changes or an active session | warning |
| `verification-unproven` | `approved`, `finishing`, or `done` lacks passing verification evidence | violation |
| `role-mismatch` | Current writer/role does not own the stage | warning |
| `stale-execution` | `executing` has no live session or recent Git activity | warning |
| `uncontracted` | Worktree/session exists without a task contract | warning |
| `contract-tampered` | Scope or Off-limits differs from the plan-time snapshot | violation |

The observer reports alarms. Automatic repair is outside v1.

## Persistence and history

The current stage lives in `.worktree-task.md`. Detecting illegal transitions
requires previous-state evidence. A future core may keep append-only transition
events under Git-local wtcraft metadata:

```text
<git-common-dir>/wtcraft/tasks/<task-id>/events.jsonl
```

That event log is not required by protocol v1 yet. Until it exists, observers
can validate the current stage and cross-signal consistency but cannot prove
the full historical transition path.

## Compatibility

- Readers accept missing `stage` and may display legacy `status`.
- Writers following v1 must write `stage` and `role`.
- Unknown future stages are displayed but treated as unsupported; they must not
  be silently mapped to a known stage.
- Changing the transition table requires a new state-machine version or an
  explicitly backward-compatible extension.

## Non-goals

- selecting which model should perform a role
- controlling terminal or session processes
- automatically merging or approving PRs
- repairing illegal state without human review
