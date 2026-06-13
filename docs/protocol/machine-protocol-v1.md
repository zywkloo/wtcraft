# Machine Protocol v1

`wtcraft` is a human-first CLI. Machine mode is opt-in via `--json` and is
intended for external launchers such as `wtflow`.

This protocol transports the canonical
[Session Model v1](session-model-v1.md) and
[Task State Machine v1](task-state-machine-v1.md) facts without making a
frontend authoritative for either model.

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
- `task_file` when contracted
- `stage`, `role`, `agent`, `status`, `priority`, `created`, `base`
- `verify_result`, `verified`

Fatal errors in machine mode return a JSON error object instead of the array.

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
- `verify_result`
- `verified`
- `results`: one object per verification command
- `summary.total`, `summary.passed`, `summary.failed`

Exit codes:

- `0`: all verification commands passed
- `3`: one or more verification commands failed
- `1`: fatal invocation/runtime error

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
