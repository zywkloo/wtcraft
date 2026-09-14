# Machine Protocol v1

`wtcraft` is a human-first CLI. Machine mode is opt-in via `--json` and is
intended for external launchers such as `wtflow`.

This protocol transports task-specification, lifecycle/result sidecar, and Git
facts without making a frontend authoritative for them. Session observation is
documented separately and remains proposed.

## Goals

- keep human-readable output as the default
- keep JSON on `stdout` parseable even when command results are failures
- keep diagnostics and child-command output on `stderr`
- let GUI clients target a repository explicitly instead of depending on `cwd`

## Versioning and discovery

- `wtcraft --version` prints the CLI package version
- `wtcraft capabilities --json` reports machine-protocol support
- `protocol_version: 1` identifies this document's contract

Example:

```bash
wtcraft --version
wtcraft capabilities --json
```

## Repository targeting

Registry commands accept `--repo <path>`:

- `wtcraft status --json --repo /path/to/repo`
- `wtcraft state --json --repo /path/to/repo feat/my-task --stage executing`
- `wtcraft check --json --repo /path/to/repo feat/my-task`
- `wtcraft verify --json --repo /path/to/repo feat/my-task`
- `wtcraft new --repo /path/to/repo feat/my-task`

For registry commands, wtcraft normalizes linked-worktree paths to the
repository's primary worktree root before enumerating `git worktree list`.
This keeps `status --json` stable no matter which linked worktree launched it.

## Stdout and stderr

Rules:

- in machine mode, `stdout` is reserved for a single JSON document
- diagnostics stay on `stderr`
- in `verify --json`, child-command output is forwarded to `stderr`
- exit codes stay compatible with human mode

That means a failed gate can still return valid JSON on `stdout` and a
non-zero exit code.

## Command shapes

### `status --json`

Success shape: JSON array of worktree objects.

Compatibility note: `status --json` shipped before protocol v1. Its success
shape stays an array for compatibility. Each entry now also includes
`repo_root`.

Fields:

- `repo_root`
- `worktree`
- `branch`
- `zombie`
- `locked`
- `contracted`
- `task_file`, `state_file`, and `state_present` when contracted
- `state_valid`: `true`/`false` when a sidecar is present, `null` otherwise;
  lifecycle and result fields are `null` when it is `false`
- `legacy_frontmatter_ignored`: `true` when a sidecar exists and the task
  frontmatter still sets `stage`, `role`, `agent`, `status`, `verify_result`,
  or `verified`; the sidecar values are reported and those fields are ignored
- `stage`, `role`, `agent`, `status`, `attempt`, `handoff_from`, `handoff_to`
- `check_result`, `checked`, `verify_result`, `verified`
- `created_at`, `updated_at`, `priority`, `created`, `base`
- derived `ready` and `evidence_stale`

`status --json` reads stable metadata from `.worktree-task.md`, mutable facts
from `.worktree-state.json`, and derives readiness by comparing recorded check
and verify snapshots with the current Scope, Off-limits, and Verification items
and the Git worktree. It
does not report live process/session state.

Fatal errors in machine mode return a JSON error object instead of the array.

### `state --json`

Success shape: JSON object containing `worktree`, `task_file`, `state_file`, and
the resulting `stage`, `role`, `agent`, and `attempt` values.

`state` is the single CLI write path for assignment and lifecycle coordination.
It validates the vocabulary and atomically replaces the JSON sidecar, but does
not claim that local state is protected authorization.

### `check --json`

Success and gate-failure shape: JSON object.

Example:

```json
{
  "protocol_version": 1,
  "command": "check",
  "ok": true,
  "result": "fail",
  "exit_code": 2,
  "repo_root": "/repo",
  "worktree": "/repo/worktrees/feat/task",
  "task_file": "/repo/worktrees/feat/task/.worktree-task.md",
  "state_file": "/repo/worktrees/feat/task/.worktree-state.json",
  "snapshot": "0123456789abcdef",
  "base": "main",
  "changed_files": ["rogue.txt"],
  "scope": ["src/"],
  "off_limits": ["docs/"],
  "violations": [
    {
      "kind": "scope",
      "file": "rogue.txt",
      "matched": null,
      "message": "Scope violation: rogue.txt"
    }
  ],
  "summary": {
    "violation_count": 1
  }
}
```

Exit codes:

- `0`: no violations
- `2`: one or more violations
- `1`: fatal invocation/runtime error

### `verify --json`

Success and verification-failure shape: JSON object.

Fields:

- `protocol_version`
- `command`
- `ok`
- `result`: `pass` or `fail`
- `exit_code`
- `repo_root`
- `worktree`
- `task_file`
- `state_file`
- `snapshot`
- `verify_result`
- `verified`
- `results`: one object per verification command
- `summary.total`, `summary.passed`, `summary.failed`

Exit codes:

- `0`: all verification commands passed
- `3`: one or more verification commands failed
- `1`: fatal invocation/runtime error

### `observe --json`

Status: proposed, not yet shipped. Recorded here so clients do not each
re-implement reconciliation and drift apart.

`status --json` answers "what are the raw facts." `observe --json` answers
"what is wrong," by reconciling three sources the core already has access to:

1. task-specification facts (`.worktree-task.md`)
2. task lifecycle/result facts (`.worktree-state.json`)
3. proposed session facts (`.worktree-session.json`, [Session Model v1](session-model-v1.md))
4. Git facts

It emits one object per worktree carrying the `status --json` fields plus a
session summary and an `alarms[]` array. Each alarm is a fact, not a
presentation: it cites the rule it violates. The reconcile rules are already
canonical — the
[Session Model v1 "Reconciliation with task state"](session-model-v1.md) table
and the
[Task State Machine v1 "Observer alarms"](task-state-machine-v1.md) table.
`observe` makes those tables executable so a GUI/TUI renders alarms instead of
computing them.

Per-alarm shape:

```json
{
  "kind": "executor-session-exited",
  "severity": "warning",
  "rule": "session-model-v1#reconciliation-with-task-state",
  "message": "task stage is executing but the recorded session exited"
}
```

Rationale for keeping this in the core rather than each client:

- the reconcile tables are a single contract; one implementation cannot drift
  from another
- liveness (PID + process-start-time match) is host-local and easy to get
  subtly wrong; the core should own it once
- clients stay thin renderers, which is the whole point of the machine protocol

Transport split: `observe --json` is not shipped by the Bash reference core.
A future one-shot command may read `.worktree-session.json`. Push delivery — a
long-lived process that streams
changes over SSE — is intentionally **not** a Bash-core concern. It is deferred
to the extracted Rust core ([ADR-006](../adr/006-rust-core-extraction.md)),
where a daemon and filesystem watching are appropriate. Until an actual client
requires this, wtcraft does not prescribe polling or ship process monitoring.

Why the boundary sits here: the one-shot is *level-triggered* — it reports
current state on demand. Streaming would add *edge-triggered* delivery (report
the transition, not just the state) plus continuous liveness, both of which need
a service runtime (persistent process, filesystem/process event subscriptions, a
transport) that the Bash core deliberately does not grow. Only the **delivery**
differs. Any future observer must be capability-discovered rather than inferred
from this proposal.

## Error objects

Fatal machine-mode errors use this shape:

```json
{
  "protocol_version": 1,
  "command": "check",
  "ok": false,
  "error": {
    "code": 1,
    "message": "missing task file: /repo/worktrees/feat/task/.worktree-task.md"
  }
}
```

`ok: false` means wtcraft itself could not complete the request. By contrast,
`ok: true` with a non-zero command exit code means the command completed and
the gate result was negative.

## Compatibility rules

- V1 readers ignore unknown object fields.
- Existing fields do not change type or meaning within v1.
- New optional fields may be added within v1.
- Removing a field, changing a field type, changing exit-code meaning, or
  changing a success shape requires a new protocol version.
- Clients discover optional command support through `capabilities --json`.
- Clients must not infer task transitions or session liveness from human output.
