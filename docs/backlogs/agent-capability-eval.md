# Agent capability eval with a deterministic oracle

> Status: planned experiment. Recorded 2026-09-02.
>
> This is not a roadmap phase and not a product line. It authorizes a bounded
> measurement experiment whose output is a report, not a shipped feature. It
> does not move evaluation into the trusted verification core.

## Decision

Build a standalone offline eval that measures **coding-agent task outcomes
scored by a deterministic oracle** — compile, test, and scope checks — rather
than by a judge model.

The claim being tested:

```text
wtcraft check + verify already produce a deterministic pass/fail per task.
That is a ground-truth oracle. Most LLM eval does not have one.
```

Routing and quota recommendation are one downstream application of the
resulting dataset. They are not the objective, and nothing here schedules them.

## Why the oracle is the point

The usual failure mode of LLM eval is that the scorer is itself a model: noisy,
uncalibrated, and disagreeing with human labels in ways that are expensive to
measure. Work that sidesteps that has a real methodological advantage.

wtcraft's outputs qualify:

| Signal | Source | Determinism |
| --- | --- | --- |
| Task passed | `verify` runs the task contract's declared commands | Deterministic given a fixed revision and toolchain |
| Change stayed in scope | `check` compares changed paths against Scope/Off-limits | Deterministic |
| Repair rounds | Count of executor cycles before first pass | Observed, not judged |
| Token/quota consumption | Provider-reported | Reported, with source confidence |

None of these require a model to score. That is the whole argument, and it is
worth stating plainly rather than burying it under a routing product.

The honest limit, which must be stated whenever the result is: **a passing
oracle proves the declared verification passed, not that the change is
semantically correct.** The oracle executes a human-written plan; it does not
invent one. A task whose tests are weak has a weak oracle.

## Scope

Deliberately small. The output is a report with real numbers, not a system.

### Dataset

30–50 tasks, drawn from real commit history in repositories the author already
owns. Each task is "make this test pass", where the test comes from the actual
historical commit — so ground truth exists without hand-labeling correctness.

Prefer this over a public benchmark as the primary set: a public benchmark
cannot exercise Scope/Off-limits contracts, which are the part wtcraft
contributes. A small public-benchmark slice may be added later purely as an
external reference point.

### Runs

2–3 agent/model configurations across the task set, in two arms:

```text
arm A: agent runs with a wtcraft task contract (Scope, Off-limits, Verification)
arm B: agent runs with the same prompt and no contract
```

Arm B exists so the experiment can answer a question the roadmap keeps asking
and never measures: **does the contract change verified outcomes, or only feel
tidier?** A null result is a publishable result and should not be suppressed.

### Metrics

| Metric | Definition |
| --- | --- |
| Verified success rate | Fraction of tasks where `verify` passes |
| Scope violation rate | Fraction where `check` reports an out-of-scope path |
| Repair rounds | Cycles to first pass; unbounded failures recorded as censored |
| Quota per verified task | Observed consumption divided by successes, not by attempts |

Report intervals, not point estimates. At N=40 the intervals will be wide; say
so rather than implying a ranking the sample cannot support.

## What this explicitly does not do

Recorded so the reasoning is not re-derived:

### Rejected: a "Phase 6.5 Evaluation Evidence Contract"

Moved to [ADR-012](../adr/012-evaluation-evidence-boundary.md), which settles it
as an architectural constraint rather than a scheduling note: trusted evidence
carries Git and policy facts only, and an evaluator's domain model (`migration
type`, `risk tier`) does not enter it. The consequence for this experiment is
that it is built as a consumer of existing evidence, needing no change to
Phase 6.

### Rejected for now: migration semantic eval

Evaluating ObjC→Swift or Java→Kotlin migrations for behavioral equivalence
requires a frozen corpus with golden behavior, differential old-vs-new
execution, and human-labeled defects. That is months of corpus engineering, it
is the actual asset of such a product, and its device/E2E layer contradicts
this project's scope statement of a local, Git-native harness.

It is also a different product that shares perhaps a couple hundred lines with
wtcraft — a frozen revision plus deterministic evidence. wtcraft would be an
optional dependency, not its foundation.

Revisit only after the experiment above reports what fraction of real defects
the deterministic layer already catches. If deterministic checks catch most of
them, the product is "configure the right checks" and no semantic evaluator is
warranted. If they catch few, there is a thesis worth funding. That number is
currently unknown, which is precisely why the larger plan should not be
scheduled yet.

### Not scheduled: anything in the advisor delivery plan

[quota-aware-task-planning.md](quota-aware-task-planning.md) remains
discovery-only. This memo does not authorize P0–P7 there. Note that the roadmap
also lists quota-aware model selection under Explicitly Deferred, and this memo
does not change that.

## Where this lives

**The harness lives in `wteval`, published.** wtcraft does not grow an `eval/`
directory.

Putting it in wtcraft would have been more convenient — the repository is
already public, already has CI, already has readers. That is the only argument
for it, and convenience is a poor reason to erode a boundary drawn on purpose.
This memo's own position is that evaluation *consumes* wtcraft rather than
living inside it; siting the evaluator in the evaluated repository contradicts
that on day one, and gets more expensive to undo once the eval grows
cross-agent and cross-model comparisons that have nothing to do with wtcraft.

wtcraft keeps zero eval dependencies. What it takes back is a citation, not
code: the contract-arm result belongs in the roadmap as the Phase 8 evidence it
has been asking for, as a sentence and a link.

### Two experiments, one harness

Naming these separately is what made the placement question tractable — they
answer different questions and only one of them is about wtcraft:

| Experiment | What it measures | Whose question |
| --- | --- | --- |
| Contract arm vs no-contract arm | Whether a task contract changes verified outcomes | wtcraft's own, and the Phase 8 evidence gap |
| Agent/model comparison scored by the oracle | Agent capability, using wtcraft as the instrument | the eval's |

They share a dataset and a runner, so the code is not split across
repositories; only the reporting is. The second is the one that carries the
methodological claim about deterministic scoring.

## Relationship to the quota-aware memo

That memo already specifies a dataset of 30–50 dogfood tasks and a metrics
table, but subordinates them to an advisor product: eval appears as a pilot
(P1) and a feedback loop (P6) around a routing feature.

This memo inverts the dependency. The eval stands alone and is worth running
even if no advisor is ever built. Routing consumes the dataset afterward if it
is built at all.

That memo's "Resume-readiness gate" also sets the bar at two provider adapters,
p50/p90 forecast calibration, OTel traces, and a LangSmith/Phoenix comparison.
That is the correct bar for claiming *an advisor product exists*. It is the
wrong bar for a measurement result: none of forecasting, tracing, or a second
provider adapter is required to report a verified-success-rate table honestly.
Those two bars are now tracked separately, and this memo owns the second.

## Go/no-go

Ship the report if all of these hold:

- at least 30 tasks ran to a recorded outcome in both arms;
- the oracle's pass/fail was reproducible on a re-run of the same revision;
- limitations state sample size, single-codebase provenance, and the
  weak-test-weak-oracle caveat;
- the write-up distinguishes what was measured from what was inferred.

Abandon and record why if the oracle turns out not to be reproducible — a
flaky verification command set would invalidate the central claim, and that
finding is itself worth writing down.

## Related

- [Trusted Change Authorization threat model](../security/threat-model.md) —
  why authorization is not semantic correctness
- [ADR-010](../adr/010-evidence-format-not-in-toto-yet.md) — the
  no-consumer-no-format rule this memo applies
- [ADR-011](../adr/011-verification-execution-least-privilege.md) — why a
  passing authorization is not a statement about tests
- [ADR-012](../adr/012-evaluation-evidence-boundary.md) — the evidence boundary
  this experiment is built to respect
- [Quota-aware task planning](quota-aware-task-planning.md) — the advisor
  application downstream of this dataset
- [Roadmap](../roadmap.md) — Phase 6 status and the two gaps that block v0.5
