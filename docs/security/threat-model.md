# Trusted Change Authorization Threat Model

## Status

Design baseline for v0.5.0. This document describes a target trust boundary;
the current v0.4.x CLI does not yet implement it.

## Objective

`wtcraft` should let a protected CI check answer one narrow question:

> Does this pull request's changeset match a reviewed authorization for this
> repository, branch, base revision, path set, and verification plan?

It does not claim to sandbox an agent, prove a change is semantically correct,
or replace code review.

## Terms

| Term | Meaning | Trust level in v0.5 |
|---|---|---|
| Local task contract | Ignored `.worktree-task.md` used to plan and run local work | Untrusted convenience state |
| Task branch | The implementation branch and every file changed by its author | Untrusted input |
| Policy envelope | A versioned authorization record on the policy authority | Authoritative when fetched from the protected policy branch |
| Evidence | A machine-readable CI verdict tied to a policy commit and PR changeset | Derived output |
| Protected merge boundary | The repository ruleset that requires the verifier before merging | Enforcement point |

## Adversary and assumptions

The primary adversary is an executor agent, compromised developer environment,
or careless contributor that can create and force-push an implementation branch.
It may modify every file in that branch, including `.worktree-task.md`, test
configuration, and a copy of a policy envelope.

The model assumes all of the following are configured before the result is
called an authorization verdict:

1. A separate `wtcraft-policy` branch accepts changes only through reviewed
   pull requests and does not grant direct write permission to executors.
2. The default branch has a merge rule requiring the wtcraft verifier result.
3. Changes to the verifier workflow and its pinned action/version receive the
   same protected review as policy changes.
4. CI reads the policy from the configured protected branch, never from the
   implementation checkout.

Repository administrators, compromised Git hosting, a compromised CI runner,
and a malicious reviewer are trusted by this model. A team that cannot accept
those assumptions needs a stronger identity or signing system outside v0.5.

## Security properties

A passing protected-check verdict must establish these properties:

1. **Authority separation.** The policy used by CI was not read from the task
   branch or the local ignored task contract.
2. **Policy integrity.** Evidence identifies the exact policy source commit
   and policy digest used for evaluation.
3. **Change binding.** The policy names the repository, expected head ref, and
   exact base SHA; a rebase or branch substitution fails closed.
4. **Scope binding.** Every changed path is checked against the authoritative
   allowed-path and off-limits rules.
5. **Verification binding.** Evidence records the reviewed verification plan
   and its execution status. A task-branch edit cannot silently replace that
   plan. The v0.5 adapter reports the plan with `"status": "not_executed"`;
   running those commands needs a separate least-privilege design, so an
   authorization pass is not yet a statement about verification results.
   [ADR-011](../adr/011-verification-execution-least-privilege.md) records why
   isolation alone is not that design, and the input-pinning precondition that
   would make execution meaningful.
6. **Merge enforcement.** A local pass, hook pass, or self-reported task state
   is never equivalent to the required remote verdict.

## Attacks and required outcomes

| Attack | Required outcome |
|---|---|
| Executor edits `Scope` in `.worktree-task.md` | No effect on protected verdict |
| Executor adds a wider policy file to the task branch | CI ignores it and uses `wtcraft-policy` |
| Executor changes the branch or rebases after approval | `head_ref` or `base_sha` mismatch fails closed |
| Executor changes a workflow to skip the verifier | Repository workflow protection/review prevents it from becoming the authoritative check |
| Policy is absent or malformed | Fail closed with a machine-readable authorization error |
| Changed path is outside the envelope | Fail with the offending paths in evidence |
| Executor renames a protected file out of an off-limits directory | Both sides of the rename appear in the changeset; the off-limits path fails closed |
| Policy is edited after approval | New policy-branch commit is visible in provenance; a replacement authorization requires review |
| Local hook is bypassed | No effect on the protected merge verdict |

## Explicit non-goals

- preventing an agent process from reading files, using the network, or running
  shell commands;
- proving that an allowed change is safe, correct, secure, or desirable;
- approving a contributor's identity solely from a field in JSON;
- protecting against repository administrators, compromised CI, or compromised
  Git hosting;
- providing a hosted policy control plane or enterprise identity service.

## Operational flow

```text
human-reviewed policy PR
        |
        v
protected wtcraft-policy branch
        |
        |  (policy commit + envelope digest)
        v
implementation PR  ---->  required wtcraft CI check  ---->  merge verdict
      (untrusted)                 |                           (evidence)
                                  v
                      exact repo/ref/base/path/verify check
```

The policy branch is an authority boundary, not a place to keep a second copy
of local planning notes. One immutable `policy_id` authorizes one expected
head ref and one base revision. A changed authorization creates a new policy
record and receives a new review; it does not amend an old task in place.

## Consequence for current task contracts

`.worktree-task.md` remains useful for humans and agents: it can hold context,
work notes, local commands, and a draft scope. It is deliberately not used as
the policy source in a protected CI verdict. Any field duplicated between the
task contract and the envelope is advisory locally and authoritative only in
the envelope.
