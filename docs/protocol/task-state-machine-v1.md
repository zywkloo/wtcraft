# Task State Machine v1

## Purpose

The task state machine defines the declared governance lifecycle of one
worktree task. Its canonical local state lives in `.worktree-state.json`;
`.worktree-task.md` is the stable task specification.

This model is independent of terminal layout, agent vendor, and session
launcher. Runtime facts belong to [Session Model v1](session-model-v1.md).

## Canonical fields

Required lifecycle fields in the JSON sidecar:

```json
{
  "schema_version": 1,
  "task_id": "feat/example-task",
  "stage": "planned",
  "role": "executor",
  "agent": "codex"
}
```

- `stage` is the current governance lifecycle state.
- `role` is the pipeline role currently responsible for receiving or
  continuing the task.
- `agent` identifies the assigned CLI/provider and is descriptive, not an
  authorization boundary.

Legacy task frontmatter may be displayed when no sidecar exists, but it is a
read-only migration fallback and does not participate in new writes.

## Stages and responsible roles

| Stage | Responsible role | Meaning |
|---|---|---|
| `planned` | executor | Task specification is ready for execution |
| `executing` | executor | Scoped implementation work is active |
| `verifying` | verifier | Implementation is under verification |
| `replan` | planner | Verification or scope discovery requires a new plan |
| `approved` | finisher | Verification passed and human approval was recorded |
| `finishing` | finisher | Merge/cleanup handoff is active |
| `done` | none | Terminal lifecycle state |

The responsible role and the owner of a transition are related but distinct.
For example, the planner creates a `planned` contract and hands responsibility
to the executor. The transition owner is the only legal writer for that stage
change; that single-writer rule is the concurrency protocol for
`.worktree-state.json`.

## Allowed transitions

| Transition | Owner |
|---|---|
| `planned -> executing` | executor |
| `executing -> verifying` | executor |
| `verifying -> replan` | verifier |
| `verifying -> approved` | finisher, after human gate |
| `replan -> planned` | planner |
| `approved -> finishing` | finisher |
| `finishing -> done` | finisher |

No other transition is legal in v1.

Each transition must be deliberate and attributable to its owner. The current
`wtcraft state` command validates the stage and role vocabularies, but does not
yet validate previous-stage edges or transition preconditions. Until that core
validation ships, this table is normative workflow guidance rather than a
tamper-resistant state machine.

## Transition preconditions

| Transition | Minimum precondition |
|---|---|
| `planned -> executing` | Task specification has Scope, Off-limits, and Verification sections |
| `executing -> verifying` | Executor handoff is complete |
| `verifying -> replan` | Verification or review found actionable failure |
| `verifying -> approved` | Verification passed and required human gate is satisfied |
| `replan -> planned` | Planner issued the revised task specification |
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
  transition and planner ownership. `wtcraft check` enforces this locally by
  comparing the specification with the digest recorded at planning. The check
  is advisory: anyone who can run `wtcraft state --stage planned` can re-record
  the digest, which also resets the stage to `planned`.
- The task specification and state sidecar are local worktree files and must
  not be committed.
- Runtime session state never authorizes or performs a task-stage transition.

## Observer alarms

An observer reconciles declared task state with Git and session facts. Every
alarm cites a rule in this document or the task specification.

| Alarm | Trigger | Severity |
|---|---|---|
| `illegal-transition` | Observed stage transition is not in the table | violation |
| `bypass` | Pre-execution stage has code changes or an active session | warning |
| `verification-unproven` | `approved`, `finishing`, or `done` lacks passing verification evidence | violation |
| `role-mismatch` | `role` is not the responsible role for the current stage | warning |
| `stale-execution` | `executing` has no live session or recent Git activity | warning |
| `uncontracted` | Worktree/session exists without a task specification | warning |
| `specification-changed` | Scope, Off-limits, or Verification items differ from the digest recorded at planning (`wtcraft new` or `wtcraft state --stage planned`); reported by `wtcraft check` | violation |

The observer reports alarms. Automatic repair is outside v1.

## Persistence and history

The current stage lives in `.worktree-state.json`, written atomically through
`wtcraft state`. Detecting a complete historical transition path requires
previous-state evidence. A future core may keep append-only transition events
under Git-local wtcraft metadata:

```text
<git-common-dir>/wtcraft/tasks/<task-id>/events.jsonl
```

That event log is not required by protocol v1 yet. Until it exists, observers
can validate the current stage and cross-signal consistency but cannot prove
the full historical transition path.

## Compatibility

- Readers accept a missing sidecar and may display legacy task frontmatter.
- Writers following v1 write `stage` and `role` to `.worktree-state.json`.
- Unknown future stages are displayed but treated as unsupported; they must not
  be silently mapped to a known stage.
- Changing the transition table requires a new state-machine version or an
  explicitly backward-compatible extension.

## Non-goals

- selecting which model should perform a role
- controlling terminal or session processes
- automatically merging or approving PRs
- repairing illegal state without human review
