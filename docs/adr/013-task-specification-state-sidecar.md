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
Scope, Off-limits, and Verification items of the task specification, HEAD,
tracked diff, and untracked contents. Other Markdown, including checkbox state,
is not an evidence input.

### Plan-time specification digest

`wtcraft new` and `wtcraft state --stage planned` record a digest of the Scope
and Off-limits items and the Verification commands at
`$(git rev-parse --git-path wtcraft/spec.digest)`, inside the per-worktree Git
directory. `wtcraft check` compares the live specification with it and reports
a `specification_changed` violation when they differ. Widening Scope to cover
an out-of-scope change therefore no longer turns a failing check into a pass.
A task without a recorded digest reports `specification_changed: null`.

The digest is outside the worktree but not protected: an executor can
re-record it by setting the stage to `planned`. It turns a silent specification
edit into a visible lifecycle reset; it is not an authorization boundary. The
evidence snapshot answers a different question: it records what the latest
check and verify saw, whereas the digest records what the planner issued. Readiness is a
derived projection: both results must pass and match the current snapshot. It
is not a writable lifecycle stage.

## Compatibility

- `wtcraft status` prefers `.worktree-state.json`.
- If the sidecar is absent, legacy lifecycle/result frontmatter remains a
  read-only fallback.
- `wtcraft new` migrates absorbed legacy frontmatter into a new sidecar and
  removes the mutable fields from the resulting task specification.
- `check` and `verify` create a sidecar lazily for an existing legacy task.
- Once a sidecar exists, lifecycle/result frontmatter is ignored. `status`
  reports `legacy_frontmatter_ignored` and `state`, `check`, and `verify` warn,
  so writes from pre-sidecar harness guidance are visible instead of silently
  dropped. `doctor` flags a missing sidecar ignore rule and harness guidance
  that predates `wtcraft state`.

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
