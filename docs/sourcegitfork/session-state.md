# Worktree session state

## Boundary

The intended runtime model is deliberately narrow:

- one worktree may have at most one active agent TUI session
- the session may run Codex CLI, Claude Code, Antigravity, or another TUI
- SourceGit indexes, launches, focuses, and reports the external session
- SourceGit does not implement a terminal emulator or own full conversation
  history

This keeps the repository/worktree model primary while adding a useful
runtime entry point.

## Separate task and session state

Do not put volatile process state into `.worktree-task.md`.

```text
.worktree-task.md       human/agent task contract and declared lifecycle
.worktree-session.json  launcher-owned local runtime state
git facts               actual code and worktree state
```

The task contract contains durable collaboration meaning:

- stage, role, and assigned agent
- Scope and Off-limits
- Verification and handoff records

The session file contains short-lived machine state:

- provider / CLI
- running, waiting, idle, or exited state
- PID and process start time
- terminal application and session identifier
- start time, last activity time, and final exit code
- optional log path or short summary, never full logs

JSON is preferred over Markdown or YAML because the file is program-owned,
frequently rewritten, and consumed across shell, .NET, and a possible future
cross-platform core.

Example:

```json
{
  "version": 1,
  "provider": "codex",
  "state": "running",
  "pid": 48231,
  "process_started_at": "2026-06-13T18:32:10Z",
  "terminal": "ghostty",
  "terminal_session_id": "wtcraft-feat-observer",
  "started_at": "2026-06-13T18:32:10Z",
  "last_active_at": "2026-06-13T18:44:27Z",
  "exit_code": null
}
```

## Ignore policy

`gitignored` is the general outcome. The chosen mechanism differs by file:

| File | Default `wtcraft init` | `wtcraft init --local` |
|---|---|---|
| `.worktree-task.md` | versioned `.gitignore` | clone-local `.git/info/exclude` |
| `.worktree-session.json` | clone-local `.git/info/exclude` | clone-local `.git/info/exclude` |

The distinction is intentional:

- `.worktree-task.md` participates in a shared collaboration protocol, so the
  default ignore rule should follow every clone.
- `.worktree-session.json` contains PID, terminal identifiers, timestamps,
  and machine-local paths. It has no value in another clone and should never
  modify the repository's `.gitignore`.

Linked worktrees share the repository's Git common directory, so one
`info/exclude` rule covers the main worktree and all linked worktrees. Locate
the correct file through Git rather than assuming `.git` is a directory:

```bash
git rev-parse --git-path info/exclude
```

## Ownership and correctness

- The session launcher/registry is the only writer.
- SourceGit and agents read the session file.
- Writers use a temporary file plus atomic rename so readers never observe
  partial JSON.
- PID alone is not proof of liveness because operating systems reuse PIDs;
  validate the process start time too.
- Preserve the final exited state until the next session starts or the
  worktree is removed.
- Keep full logs elsewhere and store only a path or summary in the state file.

## Observer reconciliation

The SourceGit panel compares three signals:

- task contract: what should be happening
- session state: what TUI process appears to be happening
- Git facts: what code activity actually happened

Useful mismatches include:

- task is executing but the session exited
- session is running in an uncontracted worktree
- task is planned but Git already contains modifications
- session claims running but PID/start-time validation fails
