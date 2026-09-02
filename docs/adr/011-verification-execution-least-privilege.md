# ADR: Executing the reviewed verification plan needs pinned inputs, not just a sandbox

## Status

Accepted for v0.5. Evaluation only — no code change. The adapter keeps
reporting `"status": "not_executed"`.

## Context

[Threat model](../security/threat-model.md) security property 5 promises that
evidence records the reviewed verification plan *and its execution status*, and
then concedes the gap: "running those commands needs a separate least-privilege
design, so an authorization pass is not yet a statement about verification
results."

With `init-ci` shipping the enforcement point, this is the last thing standing
between Phase 6 and a verdict that means what a reader assumes it means. A
green required check currently proves the changeset was authorized. Readers
will assume it also proves the tests passed. It does not.

The obvious framing — "run the envelope's commands in a sandbox" — is wrong,
and it is worth writing down why before someone implements it.

## The actual problem

The envelope authorizes a command *string*:

```json
{"name": "unit", "command": "bash tests/run_all.sh", "timeout_seconds": 900}
```

The behavior of that string is determined by repository content on the task
branch. The threat model's adversary "may modify every file in that branch,
including `.worktree-task.md`, test configuration". So the adversary controls
what `bash tests/run_all.sh` *does*.

No amount of sandboxing fixes this. A sandbox constrains what the command may
damage; it cannot make a command the adversary wrote report a truthful result.
An executor that edits a test until it passes gets a green verification from a
perfectly isolated runner.

So the useful question is not "how do we run this safely" but "under what
conditions does running it mean anything."

## Decision

Do not execute the plan in v0.5. Record the precondition that would make
execution meaningful, so a later phase implements the right thing:

**Executing the reviewed plan is only evidence when the reviewed policy also
pins the plan's inputs.** Concretely, the envelope must place the verification
inputs — test files, CI configuration, toolchain and dependency pins — under
`off_limits`, or route them through a separate approval. Then a passing
authorization already proves the changeset did not touch them, and running the
commands measures the change against tests the reviewer actually saw.

This composes with what Phase 6 already built rather than adding a mechanism.
The path check is the integrity control; execution is just a second step that
becomes interpretable once the first one covers the inputs.

Two constraints follow for whoever implements it:

1. **The authorization job must never execute the plan.** It runs
   `pull_request_target` with the policy ref available; checking out or running
   task-branch code there is the pwn-request pattern GitHub warns about, and
   `init-ci`'s installed workflow forbids it in comments for that reason.
   Execution belongs in a separate job with no secrets, no write permissions,
   and no access to the policy ref.
2. **A result produced by task-branch code is a claim, not proof.** Evidence
   must attribute it — which commit's tests ran, whether their paths were
   pinned by the envelope — instead of flattening it to `passed: true`. When
   the inputs were not pinned, evidence should say the result is unpinned
   rather than omit the caveat.

## Consequences

Until this lands, the honest reading of a passing check stays narrow, and every
surface that shows it must keep saying so. `init-ci` prints it, the setup guide
states it, and the evidence carries `"status": "not_executed"` rather than an
absent field, so a reader cannot mistake silence for success.

A team that wants merge-blocking test results today should keep using ordinary
CI for that and treat the wtcraft check as an authorization gate beside it.
That is a real limitation, not a temporary packaging gap.

## Rejected alternatives

### Run the plan in the authorization job

Rejected. It is the pwn-request pattern: a privileged `pull_request_target` job
executing untrusted code, with the protected policy ref fetched into the same
workspace.

### Run the plan in an isolated job and trust its exit code

Rejected as insufficient on its own. Isolation bounds the blast radius and is
necessary, but the exit code is still chosen by code the adversary wrote. This
is the alternative most likely to be implemented by mistake, because it looks
like a complete answer and produces a green check.

### Execute the base revision's tests against the pull request's source

Rejected as unreliable rather than unsound. It removes the adversary's control
of the test body, but tests and source move together: a legitimate change that
adds a test, renames a fixture, or bumps a dependency fails for reasons that
have nothing to do with authorization. The failure mode punishes honest work,
which is how a gate gets disabled.

### Have the executor sign a verification result locally

Rejected. Security property 6 already says a local pass is never equivalent to
the remote verdict. A signature proves who ran it, not that the environment or
the inputs were the reviewed ones.

## Revisit when

- an envelope can express verification-input pinning (an `off_limits` covering
  test and CI paths is expressible today; what is missing is guidance and a
  fixture proving the composition);
- a consumer needs merge-blocking test results from wtcraft specifically,
  rather than from the ordinary CI already running beside it;
- fork pull requests come into scope, which changes the isolation requirements
  enough to reopen the execution design as a whole.
