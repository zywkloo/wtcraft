# Contract Test Specification

## Purpose

Contract tests protect the implementation-independent behavior defined by:

- [Machine Protocol v1](machine-protocol-v1.md)
- [Session Model v1](session-model-v1.md)
- [Task State Machine v1](task-state-machine-v1.md)

The current Bash CLI and future Rust core must run the same fixtures and produce
the same observable results. Contract tests are a compatibility gate, not an
implementation test: they do not assert internal functions, command sequences,
or language-specific error types.

## Scope

The shared suite covers:

- machine-mode JSON shapes and exit codes
- task and session parsing
- legal and illegal task-stage transitions
- session-state transitions and identity-loss recovery
- reconciliation alarms derived from task, session, and Git facts
- trusted policy-envelope authorization and failure cases
- forward-compatible handling of unknown optional fields

Human-readable output, terminal integration, agent-provider behavior, and exact
diagnostic wording on `stderr` are outside the shared contract unless a later
protocol explicitly includes them.

## Fixture layout

Fixtures live under `tests/contracts/`:

```text
tests/contracts/
  machine/
    check-scope-failure/
      case.json
      repo/
      expected.json
  session/
    running-process-identity-lost/
      case.json
      input.json
      expected.json
  task-state/
    planned-to-executing/
      case.json
      input.json
      expected.json
  reconciliation/
    executing-with-exited-session/
      case.json
      input.json
      expected.json
  policy-envelope/
    stale-base-revision/
      case.json
      policy.json
      change.json
      expected.json
```

Committed fixture repositories contain only the minimum files needed to express
the case. The runner copies each fixture into a temporary directory before
execution and may initialize Git metadata there.

## Case manifest

Every fixture has a `case.json` manifest:

```json
{
  "contract_version": 1,
  "id": "machine.check-scope-failure",
  "subject": "cli",
  "command": ["check", "--json", "--repo", "$REPO", "feat/task"],
  "expected_exit_code": 2,
  "stdout": "expected.json",
  "stderr": "ignore"
}
```

Required fields:

| Field | Meaning |
|---|---|
| `contract_version` | Fixture schema version; currently `1` |
| `id` | Stable, globally unique case identifier |
| `subject` | `cli`, `task-state`, `session`, `reconciliation`, or `policy-envelope` |
| `expected_exit_code` | Expected process/result exit code; required for `cli` fixtures. Pure-core fixtures, including `policy-envelope`, use their structured expected result instead. |

Subject-specific fields such as `command`, `input`, `stdout`, and `expected`
are permitted. Unknown manifest fields must be ignored by v1 runners.

`stderr` is one of:

- `ignore`: contents are not compared
- `empty`: no diagnostic output is allowed
- a fixture path: normalized contents must match

## Comparison rules

JSON is compared structurally, not as formatted text:

- object key order and whitespace do not matter
- array order matters unless a protocol field explicitly says otherwise
- number, string, boolean, object, array, and `null` types must match
- missing fields and fields set to `null` are different
- unexpected fields fail strict producer-output comparison

Strict producer comparison prevents an implementation from silently extending
v1 output without first updating the protocol and fixtures. Separate
forward-compatibility cases verify that readers ignore unknown optional fields.

## Normalization

Fixtures must not depend on a developer's machine. Before comparison, runners
replace approved dynamic values with tokens:

| Token | Value |
|---|---|
| `$TMP` | Fixture temporary-directory root |
| `$REPO` | Canonical primary worktree path |
| `$WORKTREE` | Canonical target worktree path |
| `$GIT_COMMON_DIR` | Canonical Git common-directory path |

Fixture inputs may use these tokens and runners expand them before execution.
Fixture expected outputs may use them and runners normalize actual outputs
before comparison.

Timestamps, PIDs, process start times, UUIDs, and platform-specific paths must
either be supplied deterministically by the fixture or normalized through an
explicit field-aware rule. Runners must not use broad regular expressions that
could hide meaningful differences.

## CLI runner requirements

For each `subject: cli` fixture, a runner:

1. creates an isolated temporary directory
2. prepares the fixture repository and worktrees
3. invokes the selected implementation without a shell wrapper
4. captures `stdout`, `stderr`, and the process exit code independently
5. requires `stdout` to contain exactly one valid JSON document in machine mode
6. normalizes approved dynamic values
7. structurally compares the result with the fixture expectation
8. removes the temporary directory even after failure

The runner selects an implementation explicitly, for example:

```bash
tests/run_contracts.sh --implementation bash
tests/run_contracts.sh --implementation rust
```

The Rust implementation must not call the Bash implementation while claiming
to pass the Rust contract suite.

## Pure-core runner requirements

Task-state, session, and reconciliation fixtures describe pure input facts and
expected results. They must not require a live agent process, terminal, network,
or hosted Git provider.

The same fixture may be evaluated by a thin Bash reference adapter and by Rust
unit/integration tests. Both adapters must preserve the fixture schema rather
than translate it into implementation-specific snapshots.

## Minimum v1 coverage

Before Rust becomes the default implementation, the shared suite must include:

### Machine protocol

- capability discovery and version reporting
- `status --json` with zero, contracted, uncontracted, locked, and zombie
  worktrees
- `check --json` pass, scope violation, off-limits violation, and fatal error
- `verify --json` pass, verification failure, and fatal error
- explicit `--repo` targeting from outside the repository and from a linked
  worktree
- paths and frontmatter values containing JSON control characters

### Task state

- every legal transition
- representative illegal transitions, including transitions out of `done`
- missing legacy `stage` behavior
- unknown future stage behavior
- transition precondition failures as they become enforceable

### Session model

- every runtime state
- every allowed transition
- rejected transitions
- PID reuse detected through process start-time mismatch
- clean exit, lost identity, failed launch, and explicit takeover
- unknown optional field handling

### Reconciliation

- each alarm named in Task State Machine v1
- consistent task/session/Git facts that produce no alarm
- multiple simultaneous alarms with deterministic ordering

### Trusted policy envelope

- approved policy accepts a matching repository, branch, base SHA, and paths
- a task-branch copy of policy cannot widen an authoritative policy-branch scope
- stale base revisions and branch mismatches fail closed
- absent or malformed authoritative policy fails closed
- evidence records the authoritative policy source commit and canonical digest
  once the protected verifier is implemented

## Change policy

A behavior change that affects a contract fixture requires:

1. updating the relevant protocol document
2. adding or changing the fixture
3. demonstrating the intended result against the Bash reference
4. updating every maintained implementation before switching the default

A bug fix may intentionally change a fixture. The commit or PR must explain why
the old expected behavior violated the documented contract.

Contract fixtures are versioned independently from implementation tests.
Breaking fixture-schema changes increment `contract_version`; breaking public
protocol changes require a new protocol version.

## Adoption sequence

1. Add the fixture runner and machine-protocol fixtures around current Bash
   behavior.
2. Add pure task-state, session, and reconciliation fixtures as those adapters
   are implemented.
3. Run the Bash suite in CI as the reference compatibility gate.
4. Run the same suite against Rust during extraction.
5. Consider Rust eligible to become the default only when both implementations
   pass the required v1 fixture set.
