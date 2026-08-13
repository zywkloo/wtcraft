# ADR: Evidence stays a bespoke JSON object; in-toto deferred, not rejected

## Status

Accepted for v0.5. Evaluation only — no code change. Revisit when a revisit
trigger below fires.

## Context

`scripts/policy_git_adapter.py` emits one evidence object per evaluation (shape
in [`policy-envelope-v1.md`](../protocol/policy-envelope-v1.md#reference-adapter-output)).
It is a hand-designed JSON shape: `policy` names the source ref/commit/digest,
`change` names the Git facts, `verification` names the reviewed plan and its
`not_executed` status, `verdict` names the pass/fail reason.

The supply-chain security world already has a standard shape for exactly this
kind of claim: [in-toto attestations](https://github.com/in-toto/attestation)
(the ITE-6 Statement layer). A Statement is `{ subject, predicateType,
predicate }` — `subject` names the artifact by digest, `predicateType` names
what kind of claim this is, `predicate` carries the claim itself in a format
the type defines. GitHub Actions has native support
(`actions/attest`, `gh attestation verify`), and SLSA provenance and npm/Sigstore
publish attestations use the same envelope.

The question this ADR answers: should v0.5 evidence be wrapped in that
envelope now, or stay as-is.

## Decision

**Stay bespoke for v0.5. Do not wrap evidence in an in-toto Statement yet.**

Reasons, in order of weight:

1. **No consumer exists yet.** in-toto's value is a second party verifying a
   claim without reading this project's docs first — `gh attestation verify`,
   a SLSA-consuming supply chain, a registry that checks provenance before
   install. wtcraft has zero such consumers today: the adapter's only reader
   is a human looking at CI output, or (once P3 lands) a GitHub required-check
   conclusion. Standardizing a format before anything consumes it trades a
   real cost now for a benefit that is currently hypothetical.

2. **No predicate type exists for this claim, so adopting the envelope would
   mean inventing one anyway.** in-toto ships predicate types for build
   provenance (SLSA), vulnerability scans, and a few others — none of them is
   "a human-reviewed policy authorized this changeset." Wrapping today's
   `verdict`/`policy`/`change` object in `{subject, predicateType, predicate}`
   would still require defining a custom `predicateType` URI and its schema.
   That is most of the same design work this project already did, plus the
   overhead of a spec-compliant envelope, for a predicate type nobody else
   recognizes yet — so "adopt the standard" does not yet buy interoperability.

3. **It would be a breaking change to an already-shipped format.**
   `policy_git_adapter.py` and its evidence shape are released (P2, merged to
   `main`). Every field currently at the top level would move under `predicate`,
   `change.head_sha` would need to become (or be duplicated into) `subject`,
   and every doc, fixture, and consumer would need updating simultaneously.
   Nothing forces this now; nothing is asking for it.

4. **wtcraft is code-frozen for the current window.** Per the 2026-08-11
   red/blue-team diagnosis, engineering time is budgeted at roughly two hours
   a week, design writing only. Adopting in-toto is an implementation change
   (new dependency or hand-rolled envelope construction, new fixtures, a
   migration note for the one already-shipped shape) — squarely code work, not
   an ADR.

This is not a rejection of in-toto. The bespoke shape and an in-toto Statement
carry the same information — `policy.source_commit`/`digest` is provenance,
`verdict` is the claim, `change.head_sha` is the subject. Migrating later is a
wrapping exercise, not a redesign, *provided* the field names picked now don't
have to change to fit the envelope. That constraint is checked below.

## What this decision does not defer

The current shape is kept **compatible** with a future wrap, at zero cost
today:

- `change.head_sha` is already the natural in-toto `subject.digest.gitCommit`
  candidate — no field rename needed.
- `policy.digest` is already a `sha256:`-prefixed content digest — the same
  shape in-toto uses for subject/materials digests.
- `evidence_version` already exists as a top-level schema version, so a future
  `evidence_version: 2` can mean "this is an in-toto Statement" without
  inventing new versioning machinery.

No action needed to preserve this — it falls out of decisions already made in
[ADR-009](009-policy-authority.md) and
[policy-envelope-v1.md](../protocol/policy-envelope-v1.md). Recorded here so a
future migration doesn't have to rediscover that the shape was chosen with
this in mind.

## Revisit when

- a real second party needs to verify evidence without reading wtcraft's docs
  first — an external CI system, a registry, or a partner's tooling asks "how
  do I verify this programmatically" and the answer is "read our JSON shape";
- `init-ci` (P3) ships and evidence becomes a required-check artifact that
  other tooling might reasonably want to consume or archive;
- in-toto or SLSA publish a predicate type this claim could adopt without
  inventing one, lowering the cost in point 2 above;
- a GitHub-native alternative (`actions/attest`, artifact attestations) turns
  out to fit better than raw in-toto and is worth evaluating on its own — a
  question this ADR does not answer and a future one should.

Explicitly **not** a trigger: an external party mentioning in-toto or SLSA in
passing, or general "standards are good" pressure. The gate is a concrete
consumer, not the existence of the standard.

## Rejected alternatives

### Wrap evidence in in-toto now

Rejected on cost: no consumer, no predicate type to adopt, breaking change to
a shipped format, and code work during a code-frozen window. See Decision.

### Design a custom `predicateType` for policy authorization now

Rejected: registering a predicate type is a public commitment other tooling
might build against. Doing that before any second party exists inverts the
order — the type should be shaped by an actual consumer's needs, not guessed
at in isolation.

### Reject in-toto permanently and keep the bespoke shape forever

Rejected: the information is provenance-shaped by design (ADR-009's `source_
commit`/`digest` pairing exists for exactly the reason in-toto Statements
exist). Closing the door costs nothing to avoid and a future consumer may make
adoption cheap and clearly worth it.
