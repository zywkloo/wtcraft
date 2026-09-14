# ADR: Separate task specification from lifecycle and result state

## Status

Accepted for the next wtcraft release.

## Context

`.worktree-task.md` originally served two jobs: a human-readable task contract
and a mutable store for `stage`, assignment, and verification results. The
first changes rarely and describes what should be done. The second changes
during execution and describes what has happened. Sharing one Markdown file
made ordinary state updates look like specification changes and encouraged
agents to rewrite the document that defines their task boundaries.

Neither local file is an authorization boundary. An executor with local write
access can alter both. Protected authorization remains the responsibility of a
separate policy authority and required CI check.

## Decision

One worktree task has two ignored local files:

```text
.worktree-task.md       stable, human-readable task specification
.worktree-state.json    mutable lifecycle and latest-result sidecar
```

The task specification contains stable task identity, objective/context,
Scope, Off-limits, acceptance criteria, dependencies, and the Verification
plan. Its frontmatter declares:

```yaml
task_id: feat/example-task
state_file: .worktree-state.json
```

It does not contain `stage`, `role`, `agent`, `status`, `verify_result`, or
`verified` in newly written files.

The versioned JSON sidecar contains lifecycle, role/agent assignment, attempt
and handoff coordination, timestamps, and the latest check/verification result.
`wtcraft state`, `wtcraft check`, and `wtcraft verify` are its writers and use
atomic replacement. Agents are instructed not to edit it directly.

Check and verification results are bound to a worktree snapshot covering the
task specification, HEAD, tracked diff, and untracked contents. Readiness is a
derived projection: both results must pass and match the current snapshot. It
is not a writable lifecycle stage.

## Compatibility

- `wtcraft status` prefers `.worktree-state.json`.
- If the sidecar is absent, legacy lifecycle/result frontmatter remains a
  read-only fallback.
- `wtcraft new` migrates absorbed legacy frontmatter into a new sidecar and
  removes the mutable fields from the resulting task specification.
- `check` and `verify` create a sidecar lazily for an existing legacy task.

## Consequences

- Task-definition edits and execution-state updates have distinct review and
  parsing semantics.
- JSON state can be schema-versioned and written atomically without Markdown
  churn.
- Local tampering remains possible and is not described as a security breach;
  the sidecar improves coordination, not authority.
- Session/PID monitoring, heartbeats, append-only events, durable runtimes, and
  dashboards remain outside this decision.

## Relationship to earlier decisions

This ADR supersedes ADR-001 only where it called `.worktree-task.md` a combined
local-state file. ADR-001's ignored, worktree-local, never-commit behavior still
applies to both local task files.
