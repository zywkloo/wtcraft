# ADR: Protected Policy Branch as the v0.5 Authorization Authority

## Status

Accepted for v0.5 design. Not yet implemented in the shipping CLI.

## Context

The current task contract is an ignored, mutable worktree file. It is useful
for local planning, but an executor can alter its scope and verification
commands. A CI clone generally cannot see it. Treating that file as an
authorization source would therefore make a `check` result a useful local
signal, not a protected merge decision.

v0.5 needs a source of policy that is separate from an implementation pull
request while remaining Git-native and inspectable.

## Decision

For the first trusted-change prototype, each repository has a separately
protected `wtcraft-policy` branch. Reviewed authorization records live at:

```text
.wtcraft/policies/<policy-id>.json
```

An implementation pull request identifies a policy ID. The required verifier:

1. fetches the policy only from `refs/heads/wtcraft-policy`;
2. rejects a missing or malformed envelope;
3. verifies repository identity, expected head ref, and exact base SHA;
4. evaluates the PR changeset against the envelope's path rules and reviewed
   verification plan;
5. emits the policy branch commit and canonical envelope digest in its evidence.

The policy branch must require review and deny direct executor writes. The
default branch must require the verifier before merge. The verifier workflow
and its action pin are protected configuration, not ordinary task-branch code.

The policy envelope intentionally does **not** contain an authoritative
`approved_by` string. A string authored inside the envelope proves nothing.
Approval identity comes from the protected branch's pull-request/review history
or, in a later release, from a cryptographic attestation.

## Implementation boundary

P1 adds `scripts/policy_evaluator.py` as a reference evaluator with contract
fixtures. It accepts an already-selected policy file and immutable changeset
facts; it intentionally does not fetch Git refs, execute verification commands,
or claim that a local file was reviewed. Keeping those responsibilities out of
the evaluator prevents a local task branch from becoming an implicit policy
authority.

P2 provides `scripts/policy_git_adapter.py`, which binds an already fetched
policy ref and Git changeset to provenance-bearing evidence. The remaining
GitHub workflow transport is documented in
[`github-actions-integration.md`](../security/github-actions-integration.md).
Before a repository can call the adapter from a required workflow it must:

1. obtain repository, head ref, and merge-base facts from the pull request;
2. fetch policy from the fixed `wtcraft-policy` remote ref, not from the PR
   checkout or a PR-supplied ref name;
3. record the resolved policy branch commit and canonical policy digest;
4. run the reviewed verification plan with least-privilege workflow permissions;
5. publish a single machine-readable evidence object and a required check
   conclusion.

`init-ci` may scaffold that adapter, but cannot create trust by itself: branch
rules, review rights, and workflow protection remain repository administration.

## Why a separate branch

- The task author can modify every file in an implementation PR, so a policy
  committed in that PR is not an independent authorization.
- The policy remains inspectable Git data; no hosted wtcraft service is needed.
- A policy commit can be named in evidence and audited alongside its review.
- The approach works for a GitHub-first `init-ci` release while leaving room
  for provider-specific adapters later.

## Consequences

- Authorization is deliberately a two-step workflow: policy review, then
  implementation/merge review.
- Rebasing an authorized branch changes its merge base and fails closed until a
  new policy is reviewed. This is friction by design, not an implementation
  defect.
- Local hooks remain useful fast feedback but are explicitly bypassable.
- Repositories unable to protect a policy branch cannot honestly claim a
  protected authorization verdict; they receive local verification only.
- v0.5 has a Git-hosting configuration prerequisite. `init-ci` must document
  it rather than imply the CLI can enforce a remote ruleset by itself.

## Rejected alternatives

### Policy in `.worktree-task.md`

Rejected: ignored, mutable local state is not CI-visible authority.

### Policy committed in the implementation PR

Rejected: the executor can widen the policy and the code in the same change.

### Self-signed JSON or an `approved_by` field

Rejected: self-asserted identity does not establish review authority.

### Immediate hosted signing service

Rejected for v0.5: it adds identity, key management, availability, and support
obligations before Git-native authorization has been validated with users.

### Git notes

Rejected: notes are easy to omit from fetch/push workflows and are too opaque
for the first user-facing authorization path.
