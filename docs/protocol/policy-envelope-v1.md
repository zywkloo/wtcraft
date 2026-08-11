# Policy Envelope v1

Status: design contract for v0.5. The reference evaluator and Git adapter use
this contract; the shipping `wtcraft` CLI does not yet expose it.

The machine-readable schema is
[`policy-envelope-v1.schema.json`](../../schemas/policy-envelope-v1.schema.json).

## Authority

An envelope is authoritative only when a repository adapter reads it from the
configured protected policy ref. For the v0.5 prototype that ref is
`refs/heads/wtcraft-policy`; task-branch copies are ignored. The authority
model and required repository configuration are defined in
[ADR-009](../adr/009-policy-authority.md).

## Binding fields

An envelope binds exactly one policy record to:

- `repository`: canonical `owner/name` identity;
- `head_ref`: expected implementation branch, including `refs/heads/`;
- `base_sha`: exact lowercase 40-character merge-base revision;
- `allowed_paths` and `off_limits`: repository-relative path patterns;
- `verification`: reviewed commands for a later protected verification step.

Path matching follows current `wtcraft check` semantics: a pattern with no `*`
matches its exact path or directory prefix; `*` matches any characters,
including `/`. `off_limits` always takes precedence over `allowed_paths`.

## Policy selection

The Git adapter computes the implementation head's actual merge-base against
the current target-base ref, then lists `.wtcraft/policies/*.json` at the
policy ref. It accepts exactly one schema-valid record where `repository`,
`head_ref`, and `base_sha` match those immutable facts. This deliberately
allows the target branch to advance after authorization; rebasing the
implementation branch changes its merge-base and requires a new policy. Zero matches is
`policy_not_found`; more than one is `ambiguous_policy`. A malformed policy
record on the authority ref is an `invalid_policy` error, not an artifact to
silently skip.

## Canonical digest

Evidence uses this canonical envelope digest:

```text
sha256(UTF-8(JSON with object keys sorted, separators ',' and ':', ensure_ascii=false))
```

The evidence also records the resolved policy Git commit. The digest detects a
content difference; the commit records the reviewed source and history. Neither
is a substitute for Git-hosting review or branch protection.

## Reference adapter output

`scripts/policy_git_adapter.py` emits one JSON document. The successful shape
includes:

```json
{
  "evidence_version": 1,
  "command": "policy-git-adapter",
  "ok": true,
  "result": "pass",
  "exit_code": 0,
  "policy": {
    "policy_id": "example-policy",
    "source_ref": "refs/heads/wtcraft-policy",
    "source_commit": "...",
    "digest": "sha256:..."
  },
  "change": {
    "repository": "owner/repo",
    "head_ref": "refs/heads/feat/example",
    "base_ref_sha": "...",
    "merge_base_sha": "...",
    "head_sha": "...",
    "changed_files": ["src/example.ts"]
  },
  "verdict": {"result": "pass", "reason": "authorized", "policy_id": "example-policy"}
}
```

`ok: false` means the adapter could not establish authorization, such as a
missing policy ref or malformed policy. `ok: true` with `result: "fail"` means
the adapter evaluated the authorization and rejected the changeset.

The adapter does not execute `verification` commands. That requires a separate
least-privilege CI execution design and remains outside this reference surface.
