# Policy Envelope Contract Fixtures

These fixtures define the authorization behavior planned for v0.5. They are
normative cases for the future policy evaluator; P0 intentionally adds the
cases before exposing a CLI flag or CI action.

Each case supplies:

- `policy.json`: the policy read from the protected `wtcraft-policy` branch;
- `change.json`: immutable facts collected for an implementation pull request;
- optional `task-branch-policy.json`: an untrusted copy supplied by the
  executor, which must never become authoritative;
- `expected.json`: the evaluator verdict.

The evaluator must validate the authoritative envelope against
[`policy-envelope-v1.schema.json`](../../../schemas/policy-envelope-v1.schema.json)
before evaluating paths. It must fail closed for a missing, malformed, stale,
or mismatched policy. `tests/contract_policy_envelope.sh` runs the P1 reference
evaluator against these cases. A later CI adapter will attach policy
commit/digest provenance to its evidence.
