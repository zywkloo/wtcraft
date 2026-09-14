# Task lifecycle state

`.worktree-task.md` is the stable, human-readable task specification. It
declares `state_file: .worktree-state.json`; mutable lifecycle and result facts
live in that JSON sidecar.

The separation is semantic, not a security boundary. Both files are local and
advisory. Protected authorization, when configured, comes from the repository's
policy authority rather than either worktree file.

## State fields

The sidecar records:

```json
{
  "schema_version": 1,
  "task_id": "feat/example-task",
  "stage": "planned",
  "role": "executor",
  "agent": "codex",
  "attempt": 0,
  "check_result": null,
  "check_snapshot": null,
  "verify_result": null,
  "verify_snapshot": null
}
```

Use `wtcraft state`, `wtcraft check`, and `wtcraft verify` to update it. Do not
edit the sidecar directly, and never copy lifecycle/result fields into the task
specification.

## Lifecycle

```text
planned → executing → verifying → approved → finishing → done
                          │
                          └→ replan → planned
```

The current CLI restricts stage and role vocabulary but does not yet enforce
the complete transition table. The roles retain these ownership conventions:

| transition | owner |
|---|---|
| create/replan → `planned` | planner |
| `planned` → `executing` | executor |
| `executing` → `verifying` | executor |
| `verifying` → `replan` | verifier |
| `verifying` → `approved` | human gate, recorded by finisher |
| `approved` → `finishing` | finisher |
| `finishing` → `done` | finisher |

Example:

```bash
wtcraft state feat/example-task --stage executing --role executor --agent codex
```

## Results and readiness

Verification commands remain in `.worktree-task.md`; only their outcomes live
in the sidecar. `check` and `verify` bind results to a snapshot of the Scope,
Off-limits, and Verification items they read, plus HEAD, the tracked diff, and
untracked contents. Ticking a checkbox or editing Context leaves evidence
fresh.

`ready` is derived by `wtcraft status --json`. It is true only when both latest
results pass and both snapshots match the current worktree. A later edit makes
the evidence stale instead of leaving a writable `ready` claim behind.

Legacy task files that still contain `stage`, `role`, `agent`, `status`,
`verify_result`, or `verified` remain readable when no sidecar exists. New
writers must use the sidecar.
