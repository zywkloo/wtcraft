# Task State Sidecar v1

## Purpose

`.worktree-state.json` stores mutable coordination facts for the task specified
by `.worktree-task.md`. The specification declares the relationship with:

```yaml
state_file: .worktree-state.json
```

The path is fixed in v1. Both files are ignored, local, and advisory; neither
is a protected authorization source.

## Document shape

```json
{
  "schema_version": 1,
  "task_id": "feat/example-task",
  "stage": "planned",
  "role": "executor",
  "agent": "codex",
  "status": "ready",
  "attempt": 0,
  "handoff_from": null,
  "handoff_to": null,
  "check_result": null,
  "checked": null,
  "check_snapshot": null,
  "verify_result": null,
  "verified": null,
  "verify_snapshot": null,
  "created_at": "2026-09-13T20:00:00Z",
  "updated_at": "2026-09-13T20:00:00Z"
}
```

| Field | Meaning |
|---|---|
| `schema_version` | Integer `1` |
| `task_id` | Stable task identity, matching the task specification |
| `stage` | Current governance lifecycle stage |
| `role` | Role currently responsible for the task |
| `agent` | Assigned CLI/provider, or `null` |
| `status` | Legacy coarse status: `ready` before completion, `done` at the `done` stage |
| `attempt` | Non-negative coordination/retry counter |
| `handoff_from`, `handoff_to` | Optional provider handoff names |
| `check_result` | `pass`, `fail`, or `null` |
| `checked` | UTC timestamp of the latest completed check |
| `check_snapshot` | Opaque snapshot identifier checked |
| `verify_result` | `pass`, `fail`, or `null` |
| `verified` | UTC timestamp of the latest completed verification |
| `verify_snapshot` | Opaque snapshot identifier verified |
| `created_at`, `updated_at` | UTC sidecar timestamps |

Unknown fields are ignored by v1 readers. A missing sidecar activates the
legacy Markdown-frontmatter read fallback. New writers always use the sidecar.

## Layout

A v1 sidecar uses the layout wtcraft writes: `{` and `}` on their own lines,
exactly one field per line, each value a string, integer, boolean, or `null`,
and every field in the table above present. Other writers must emit the same
layout.

A reader that finds any other layout, including valid JSON on a single line,
treats the sidecar as invalid rather than reading empty values:
`status --json` reports `state_valid: false`, and `state`, `check`, and
`verify` exit with a fatal error before writing anything.

## Writers

- `wtcraft new` creates the document by atomic rename.
- `wtcraft state` updates assignment/lifecycle coordination.
- `wtcraft check` updates the latest check fields.
- `wtcraft verify` updates the latest verification fields.

One command publishes its complete update through a single final rename.
Its temporary files (`.worktree-state.json.*`) are removed when the command
exits early, and `check` and evidence snapshots never count them as task
changes. Direct agent edits are outside the protocol. Agent and handoff names
are printable text; control characters are rejected.

## Evidence freshness

A snapshot binds what `check` and `verify` read and the worktree they judge:

- the Scope and Off-limits items and the Verification commands of the task
  specification (other Markdown, such as Context or checkbox ticks, is not
  part of the snapshot);
- HEAD and the tracked working-tree diff;
- untracked paths and their contents. An untracked symlink is bound by its
  target path, and an untracked nested repository by its HEAD.

`.worktree-state.json` and its temporary files are excluded.

`ready` is not stored. `wtcraft status --json` derives it when both latest
results are `pass` and both recorded snapshots equal the current snapshot. If
recorded evidence targets different contents, `evidence_stale` is true.

Snapshots demonstrate freshness of local evidence, not protected review or
authorization. The plan-time specification digest that `check` compares is a
separate record kept in the per-worktree Git directory, not in the sidecar.
