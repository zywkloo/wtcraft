# ADR: Trusted evidence stays Git and policy facts; evaluator domain models stay out

## Status

Accepted for v0.5. Evaluation only — no code change. Evidence keeps the shape
[policy-envelope-v1](../protocol/policy-envelope-v1.md#reference-adapter-output)
defines.

## Context

A proposal came up for a "Phase 6.5 · Evaluation Evidence Contract": a
milestone between Phase 6 and Phase 8 that would define, up front, the input
contract a future semantic evaluator consumes —

```text
policy digest + base/head SHA + diff + verification results
+ migration type + risk tier
```

— on the reasoning that a trustworthy evaluator needs a frozen, well-specified
evidence packet, so the packet should be specified before the evaluator exists.

The motivating goal is real: judging whether a migration (ObjC→Swift, say)
preserved behavior is worth doing, and doing it against a frozen revision with
deterministic evidence is the right shape for it. The question this ADR answers
is narrower — whether Phase 6's evidence should grow fields for that consumer
now.

## Decision

**No. Evidence carries Git and policy facts only. An evaluator's domain model
does not enter it, and no evaluation contract is specified before an evaluator
exists.**

Two independent reasons, either sufficient.

### 1. It repeats the anti-pattern ADR-010 already rejected

[ADR-010](010-evidence-format-not-in-toto-yet.md) declined to wrap evidence in
in-toto for exactly this reason: no consumer existed. It set the gate
explicitly —

> Explicitly **not** a trigger: an external party mentioning in-toto or SLSA in
> passing, or general "standards are good" pressure. The gate is a concrete
> consumer, not the existence of the standard.

A contract designed for a semantic evaluator that has not been built is the
same trade: a real cost now against a benefit that is currently hypothetical,
and a format shaped by guesswork rather than by what a consumer turned out to
need. ADR-010's resolution applies unchanged — keep the shape *compatible* with
future extension at zero cost, and let the first real consumer say what it
needs.

### 2. `migration type` and `risk tier` are not facts about the change

This is the stronger reason, and it is specific to these fields rather than to
timing.

Everything in evidence today is checkable by a party that trusts only Git and
the policy branch: a commit SHA, a digest, a path list, a ref name. Anyone can
recompute them and get the same answer.

"Migration type" and "risk tier" are not of that kind. They are judgements
produced by the evaluator's model of the world — the output of the thing being
evaluated, presented as an input to its own authorization. Placing them in
evidence would pull semantic judgement into the trusted core, which the
[threat model](../security/threat-model.md) lists as an explicit non-goal:

> proving that an allowed change is safe, correct, secure, or desirable

It would also make the evidence unfalsifiable in a way the current shape is
not. A reader can check a digest. A reader cannot check that a change was
"medium risk."

## Consequence

The boundary this fixes:

```text
wtcraft            frozen revision + policy provenance + scope verdict
                   (facts anyone can recompute)
                        |
                        v
external evaluator  semantic judgement, corpus, findings
                   (claims that need their own evidence)
```

An evaluator consumes evidence; it does not get to write into it. If a future
evaluator needs to record a risk tier, that belongs in the evaluator's own
output, referencing the evidence by `policy.digest` and `change.head_sha` —
which is what those fields are for.

This does not block migration evaluation. It says such work is built as a
consumer first, and only then, if a concrete need survives contact with a real
implementation, is a contract specified — by then informed rather than guessed.

## Revisit when

- a semantic evaluator actually exists and names a field it cannot obtain by
  reading the repository at `change.head_sha` plus the evidence already emitted;
- two or more independent consumers need the same additional field, which is
  evidence of a real contract rather than one tool's convenience;
- the field in question is recomputable by a third party from Git and policy
  state alone — the property that separates every current evidence field from a
  judgement.

Explicitly **not** a trigger: a plan for an evaluator, a design document, or
the observation that a frozen evidence packet would be useful to have. Those
describe the same hypothetical consumer this ADR declines to design for.

## Rejected alternatives

### Add the fields now, leave them null until an evaluator fills them

Rejected. A nullable field in a released schema is still a commitment: it
appears in every evidence object, needs documenting, and invites consumers to
depend on it. It also does not avoid reason 2 — a field for a judgement is
misplaced whether or not it currently holds one.

### Define the contract in a separate schema that evidence does not carry

Not rejected — this is simply what building the consumer first produces. An
evaluator that reads evidence and emits its own structured findings, keyed by
policy digest and head SHA, needs no change to Phase 6 at all. The point of
this ADR is that the separate schema should be written by that evaluator, when
it exists, rather than specified in advance as a wtcraft milestone.

### Make it Phase 6.5 in the roadmap

Rejected as scheduling a specification rather than work. The roadmap tracks
capability; a contract with no implementation and no consumer is neither. The
evaluation experiment that *would* produce a consumer is tracked in
[agent-capability-eval.md](../backlogs/agent-capability-eval.md).

## Related

- [ADR-010](010-evidence-format-not-in-toto-yet.md) — the no-consumer-no-format
  rule this decision applies
- [ADR-011](011-verification-execution-least-privilege.md) — the other limit on
  what a passing verdict may claim
- [Threat model](../security/threat-model.md) — semantic correctness as an
  explicit non-goal
- [Agent capability eval](../backlogs/agent-capability-eval.md) — the
  consumer-first experiment
