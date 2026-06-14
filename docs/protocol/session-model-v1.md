# Session Model v1

## Purpose

The session model describes the local runtime attached to a worktree. It lets a
launcher or observer answer:

- which agent process was launched for this worktree
- whether that exact process still appears alive
- whether it is interactive or headless
- when it started, last showed activity, and exited

It does not describe task intent or governance approval. Those belong to
`.worktree-task.md` and [Task State Machine v1](task-state-machine-v1.md).

## Authority and ownership

The launcher that creates a session is the single writer of:

```text
.worktree-session.json
```

Other tools, including agents and GUIs, are readers. A new launcher may take
ownership only after determining that the previous recorded process is no
longer the same live process.

The file is machine-local and must never be committed. Writers use a temporary
file plus atomic rename.

## Cardinality

A worktree has at most one primary active session.

Delegated jobs launched inside a primary agent session are not primary sessions
in v1. A future protocol version may add delegated jobs without changing the
identity of the primary session.

## Schema

Required fields:

```json
{
  "schema_version": 1,
  "session_id": "019eba11-dd9f-7b51-a43f-9889cadf67fc",
  "worktree": "/repo/worktrees/feat/task",
  "provider": "codex",
  "launch_mode": "interactive",
  "state": "running",
  "pid": 48231,
  "process_started_at": "2026-06-13T18:32:10Z",
  "started_at": "2026-06-13T18:32:10Z",
  "last_active_at": "2026-06-13T18:44:27Z",
  "exited_at": null,
  "exit_code": null,
  "terminal": "ghostty",
  "terminal_session_id": "wtcraft-feat-task",
  "log_path": null,
  "summary": null
}
```

Field rules:

| Field | Rule |
|---|---|
| `schema_version` | Integer `1` for this contract |
| `session_id` | Stable unique identifier created by the launcher |
| `worktree` | Canonical absolute worktree path |
| `provider` | Agent CLI identifier such as `codex`, `claude`, or `agy` |
| `launch_mode` | `interactive` or `headless` |
| `state` | One of the states below |
| `pid` | OS process ID, or `null` after launch failure |
| `process_started_at` | OS-observed process start time; pairs with PID |
| `started_at` | Launcher-observed session start time |
| `last_active_at` | Best available activity timestamp, or `null` |
| `exited_at` | Timestamp recorded when exit is observed |
| `exit_code` | Process exit code when known |
| `terminal` | Terminal application identifier for interactive sessions |
| `terminal_session_id` | Launcher-specific focus handle when available |
| `log_path` | Optional machine-local log path; never full log contents |
| `summary` | Optional short final status; never conversation history |

Unknown fields must be ignored by v1 readers.

## Runtime states

| State | Meaning |
|---|---|
| `starting` | Launch requested, exact process identity not yet confirmed |
| `running` | Exact process identity is live |
| `waiting` | Launcher has positive evidence that user input is required |
| `idle` | Process is live but no recent activity is observed |
| `exited` | Exact process exit was observed |
| `lost` | Recorded identity cannot be verified and clean exit was not observed |
| `failed` | Launch failed before a usable session was established |

`waiting` is optional precision. Vendor-neutral observers may report `running`
or `idle` instead of guessing.

## Identity and liveness

PID alone is not identity because operating systems reuse PIDs. A process is the
recorded session only when PID and process start time both match.

Liveness evidence is ordered:

1. PID plus process start-time match
2. launcher-owned terminal/session handle
3. filesystem activity as a weak fallback

Vendor-specific hooks may improve `last_active_at`, but their absence or failure
must not invalidate the session model.

## Allowed transitions

```text
starting -> running | failed | lost
running  -> waiting | idle | exited | lost
waiting  -> running | idle | exited | lost
idle     -> running | waiting | exited | lost
failed   -> starting
exited   -> starting
lost     -> starting
```

A new `starting` transition creates a new `session_id`. Historical sessions are
not stored in this sidecar; a launcher may archive them elsewhere.

## Reconciliation with task state

Session state is an observed runtime fact, not permission to change task stage.
The observer compares session, task, and Git facts and reports mismatches.

Examples:

| Task fact | Session fact | Observer result |
|---|---|---|
| `stage: executing` | `state: running` | consistent |
| `stage: executing` | `state: exited` | warning: executor session exited |
| `stage: planned` | `state: running` | warning: work started before transition |
| no task contract | `state: running` | warning: uncontracted session |
| any active stage | `state: lost` | warning: session identity lost |

The observer reports these conditions. It does not silently repair either file.

## Recovery rules

- A stale `running` record becomes `lost` when exact process identity fails.
- A launcher may replace `lost`, `failed`, or `exited` with a new session.
- A launcher must not replace a verified live primary session without an
  explicit stop/takeover action.
- Preserve terminal and exit details until a new session starts or the
  worktree is removed.

## Non-goals

- terminal emulation
- conversation storage
- vendor output scraping as required truth
- delegated job modeling
- cross-machine session migration
