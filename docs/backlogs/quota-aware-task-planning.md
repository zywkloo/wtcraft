# Quota-aware task planning and outcome feedback

> Status: discovery and planning only. Recorded 2026-08-20.
>
> This document does not authorize implementation, merge the historical
> `origin/feat/budget-tracker` branch, or move model routing into the trusted
> verification core. The first gate is a manual, labeled dogfood study.

## Decision

Explore a **pre-execution task advisor** that classifies an incoming coding
prompt, predicts its likely token and subscription-quota consumption, and
recommends a provider/model tier for the next lifecycle role. Close the loop
after execution by comparing the forecast with observed usage and wtcraft's
deterministic verification result.

Do not build another token dashboard, subscription reseller, universal LLM
gateway, or autonomous agent launcher.

The product question is:

```text
Given this prompt, repository, task contract, current quota state, and prior
verified runs, which lifecycle role and model tier should handle the next step,
what quota range should the developer expect, and how much capacity should be
reserved for verification and repair?
```

The optimization target is **verified task success per unit of scarce quota**,
not minimum tokens in isolation.

## Why this belongs near wtcraft

Dedicated usage tools already answer “where did the tokens go?”:

- [TokenTracker](https://github.com/xiufengsun/TokenTracker) already provides
  broad local provider parsing, quota windows, project/model views, native
  apps, widgets, achievements, and a desktop pet, plus machine-readable status
  intended for AI-agent ingestion;
- [tokscale](https://github.com/junhoyeo/tokscale) reads local sessions and
  subscription usage across multiple coding agents;
- [CodeBurn](https://github.com/getagentseal/codeburn) classifies task activity,
  compares models, identifies waste, and correlates sessions with Git output;
- [OpenUsage](https://openusage.sh/) aggregates quota, spend, burn rate, and
  provider usage.

Wtcraft already owns facts those tools do not own:

- an explicit task contract;
- declared lifecycle `stage` and responsible `role`;
- Scope and Off-limits boundaries;
- a worktree-bound session identity and provider;
- deterministic `check` and `verify` outcomes;
- protected policy and change evidence at the Git boundary.

The useful gap is therefore prediction and policy **against explicit task
intent and verified outcomes**, not more log parsing or charts.

## Product boundaries

| Component | Responsibility |
| --- | --- |
| `wtcraft` | Capture explicit task/role facts, produce a preflight recommendation, persist local decision evidence, and attach observed usage to deterministic outcomes. |
| `wteval` | Build labeled datasets, evaluate classifier/forecast/routing versions, compare experiments, and export traces/results. It is not a runtime service. |
| `wtflow` | Optionally manage instruction enable/disable and render the lightweight Quota Cat cat-and-jars overlay after the decision engine proves useful. It does not recreate TokenTracker's dashboard or general usage pet. |
| TokenTracker | Preferred first provider/session/quota adapter and existing visibility surface. Other usage tools remain fallback adapters. |
| Provider CLIs | Execute the work and remain authoritative for provider-reported quota. |

The trusted authorization evaluator must not depend on an LLM prediction. A
missing or failed advisor never weakens `check`, `verify`, protected policy, or
the human approval gate.

## Advisor runtime versus recommended runtime

The advisor should have a small, fixed, user-configured route. It must not use
the model-selection result to choose the model that performs the current
classification; that creates a recursive and difficult-to-audit decision.

Initial dogfood preference:

```text
primary:  agy + configured Gemini Flash model
fallback: Cursor Composer -> Claude Haiku -> configured GPT-5.4-class model
```

The concrete model names are examples from the current personal configuration,
not product constants. Availability, explicit model selection, structured
output, and non-interactive invocation must be proven by each endpoint adapter.
In particular, Cursor Composer must not be treated as a CLI fallback until a
stable explicit invocation boundary exists.

The two decisions remain distinct in evidence and UI:

| Decision | Example | Source |
| --- | --- | --- |
| `advisor_route` | `agy / Gemini Flash` | Fixed configuration plus availability fallback. |
| `recommended_route` | `codex / executor / balanced-coding` | Task classification, capability constraints, quota policy, and history. |

The advisor's own latency and quota consumption are overhead and must be
recorded separately. Invocation policy is independent from its route:

```text
always          call the configured advisor for every debounced new request
low-confidence call it only when the deterministic baseline is uncertain
shadow          calculate and record advice without interrupting the user
off             deterministic/local behavior only
```

Use `always` for the initial personal dogfood MVP so every new request produces
an asynchronous recommendation and a consistent labeled trail. Run the rules
classifier alongside it as a shadow baseline. After measuring latency, quota
overhead, agreement, and overrides, `low-confidence` may become the product
default. Follow-up turns within the same task/stage should be debounced.

### Role config and capability matrix

After role-models v2 is stable, add an `advisor` role to the template, live
dogfood config, generated presets, docs, and fixtures together. Do not patch
only the live `.agent-harness/role-models.yml`.

The current flat role config expresses preference (`cli`, `model`, ordered
`fallback`, and `rationale`) but cannot safely answer whether an endpoint:

- supports headless or async invocation;
- can guarantee versioned structured output;
- honors explicit model and reasoning-tier selection;
- exposes usage or subscription-quota observations;
- is currently authenticated and available;
- is a CLI, GUI composer, protocol endpoint, or API adapter.

Keep role preference human-editable, but join it at runtime with a separate,
generated capability/availability matrix. `model-select` remains the single
routing brain; `advise` supplies the recommended role, constraints, and quota
state instead of implementing a second fallback resolver.

## Lifecycle vocabulary

Prompt classification and task lifecycle state are related but not identical.
Use `work_kind` for the prediction so it cannot be confused with the canonical
task-state-machine `stage`.

Proposed `work_kind` values:

| Work kind | Meaning | Typical next role |
| --- | --- | --- |
| `discovery` | Understand an unfamiliar code path, requirements, or failure before committing to a change. | planner |
| `planning` | Define scope, architecture, acceptance criteria, sequencing, or risk for non-trivial work. | planner |
| `execution` | Implement a bounded change with sufficiently clear scope and verification. | executor |
| `verification` | Review or test an existing diff/commit against known requirements without adding feature scope. | verifier |
| `repair` | Address concrete failed checks or accepted findings against an existing change. | executor, then verifier |
| `finishing` | Prepare handoff metadata, commit/PR text, archive, or cleanup after approval. | finisher |

Also predict an orthogonal size and risk:

```text
size: xs | s | m | l | xl
risk: low | medium | high
```

A large execution request may produce `recommended_sequence: [planning,
execution, verification]` rather than pretending it is one flat call.

## User experience

### Robust v1: explicit preflight

The first command surface should be advisory and non-launching:

```bash
wtcraft advise --prompt "Fix the stale refresh-token retry bug"
wtcraft advise --stdin --json
```

An enabled workspace instruction may ask the current agent to call this command
for a fresh prompt or task. V1 returns human-readable CLI plus JSON. A later
wtflow state or TokenTracker renderer may show the fixed advisor route
separately from the recommended execution route, reason codes, confidence,
quota reservation, and Use/Override/Ignore actions. Do not build a second
quota dashboard, menu-bar app, widget suite, or pet.

The preferred daily UX is a one-click workspace toggle that prepares a short
auditable instruction for `AGENTS.md` or an equivalent provider instruction
file. The exact generated text must be configuration-aware, but the intent is:

```text
For each new user prompt or task, call the configured quota analyzer first.
Treat the result as advisory context only. If the analyzer is unavailable,
continue normally and mention the unavailable analyzer only when relevant.
```

The toggle must detect and display instruction states:

```text
enabled      supported instruction exists and matches current config
missing      no analyzer instruction is installed for this workspace
drifted      instruction exists but command/config no longer matches
unsupported  current agent surface has no reliable instruction path
```

Analyzer calls are advisory context, not authorization. They must never weaken
protected policy, bypass approval gates, or make task execution conditional on
an LLM recommendation.

Illustrative output shape:

```text
Classification
  work kind: execution
  size: small
  risk: medium
  confidence: 0.84

Forecast
  tokens: p50  / p90
  quota-window delta: p50 / p90
  likely repair rounds: 0-1

Recommendation
  next role: executor
  model tier: balanced-coding
  reasoning tier: medium
  reserve: preserve quota for independent verification and one repair round
  fallback: use configured executor fallback if the preferred window lacks headroom

Why
  bounded bug fix; existing target area; verification required; no architecture
  decision detected
```

The user may accept, override, or ignore the recommendation. Every override is
valuable feedback and must be recordable without forcing an agent launch.

### Fallback surface: explicit task-feeding boundary

Automatic classification is reliable only where a supported instruction,
wtcraft, or wtflow owns the task input. Manual feeding is still useful for
unsupported agents, one-off tasks, demos, and debugging:

- explicit stdin/paste into `wtcraft advise` or an optional wtflow control;
- an explicit `wtcraft handoff` or `wtcraft run` wrapper;
- provider-specific prompt hooks where available.

Provider hooks are precision adapters, never the core contract. A prompt typed
directly into an arbitrary Claude/Codex/Agy session without the instruction can
bypass the advisor; v1 must report that limitation rather than monitoring the
clipboard, scraping terminal UI, intercepting keystrokes, or depending on ACP
internals.

## Decision pipeline

```text
prompt + task contract + Git facts
                |
                v
      deterministic feature extraction
                |
                v
      rules classifier + confidence
                |
       low confidence only
                v
      optional structured LLM classifier
                |
                v
 historical forecast + current quota snapshots
                |
                v
 capability/quality/quota policy
                |
                v
 recommendation + reasons + human decision
                |
                v
          external agent execution
                |
                v
 observed usage + check/verify + repair rounds
                |
                v
       wteval calibration and comparison
```

The LLM may classify or explain evidence. It must not invent quota values,
override a hard capability constraint, or turn a failed deterministic check
into a successful outcome.

## Classification design

### Deterministic features first

Candidate preflight signals:

- prompt verbs and explicit intent (`design`, `implement`, `review`, `fix`,
  `verify`, `release`);
- presence and completeness of Scope, Off-limits, and Verification sections;
- whether a diff, failed verification result, or accepted finding already
  exists;
- requested or inferred file/module count;
- cross-cutting indicators such as migration, schema, security, concurrency,
  public API, or multi-repository changes;
- existing task stage and responsible role;
- repository language/toolchain and expected verification commands;
- user-supplied urgency, risk, and quality constraints.

The rules path should be cheap, deterministic, testable, and able to return
`confidence: low` rather than overclaim.

### Optional LLM escalation

Only low-confidence or conflicting classifications call an LLM. The response
must use a versioned structured schema and include:

- predicted work kind, size, and risk;
- recommended sequence of roles;
- evidence features supporting the decision;
- missing information;
- confidence;
- no free-form model name or quota fabrication.

A conditional workflow is a legitimate future LangGraph use case:

```text
rules -> confidence gate -> LLM classifier? -> forecast -> policy -> human gate
```

LangGraph is optional. The deterministic path must work without LangChain,
LangGraph, an API key, or network access.

## Forecast design

### Separate the quantities

Never collapse these into a single dollar field:

| Quantity | Meaning |
| --- | --- |
| `reported_tokens` | Provider/session-reported input, cached, output, and reasoning tokens when available. |
| `api_equivalent_cost` | What the observed tokens would cost at public API list prices; not subscription billing. |
| `subscription_quota_delta` | Observed change in a provider-reported rolling subscription window. |
| `quota_remaining` | Provider-reported or adapter-observed remaining percentage/window state. |
| `source_confidence` | Reliability of the adapter and attribution. |

Subscription plans use opaque and changing limits. Forecast the observed quota
delta directly when enough before/after snapshots exist; do not assume a fixed
token-to-quota conversion.

### Forecast targets

For each candidate provider/model tier, predict ranges rather than false
precision:

- token usage `p50` and `p90`;
- subscription quota delta `p50` and `p90`;
- wall-clock range;
- expected tool/turn count;
- probability of requiring replan or repair;
- probability of passing the declared verification in the first cycle.

### Cold start

Before enough personal history exists:

1. use coarse work-kind/size buckets;
2. report wide intervals and low confidence;
3. avoid a dollar or quota claim when no source supports it;
4. never use `characters / 4` as billing truth;
5. ask for an explicit user size/risk override when classification materially
   changes the recommendation.

### Personal calibration

The useful estimator is user/repository specific. Condition historical runs on:

- provider and model/reasoning tier;
- work kind, size, and risk;
- repository/toolchain;
- prompt/context size bucket;
- number of scoped files/modules;
- verification command class;
- cache state when reliably reported;
- retry, repair, and replan history.

Start with interpretable baselines (bucketed quantiles or regularized
regression). Do not add a complex ML model until it beats the baseline on held
out dogfood tasks.

## Quota policy and recommendation

The advisor ranks eligible choices only after applying hard constraints:

- required tools, modality, context capacity, privacy, and repository access;
- configured role/provider allowlist and fallbacks;
- current provider availability and quota headroom;
- minimum quality/risk tier;
- explicit user preference or prohibition.

Then optimize an auditable objective such as:

```text
expected verified success
-------------------------
expected quota consumption + expected retry/repair consumption
```

The first version returns a recommendation and reason codes. It does not launch
or switch accounts automatically.

### Capacity reservation

Do not spend all remaining capacity on execution. A recommendation should
reserve enough expected headroom for:

- independent verification;
- one repair cycle when risk is non-trivial;
- user-requested chat usage that shares the same subscription window, when the
  provider exposes only a combined bucket.

Reservation percentages must be policy inputs or learned estimates, not
hard-coded universal facts.

## Data sources and adapter confidence

Preferred order:

1. official provider/CLI structured usage or quota output;
2. a versioned TokenTracker CLI JSON snapshot;
3. a pinned TokenTracker localhost read-only API adapter for prototyping;
4. established local usage tool JSON (`tokscale`, `CodeBurn`, OpenUsage, or
   another configured adapter);
5. local vendor session records through an isolated best-effort adapter;
6. explicit user snapshot;
7. unavailable.

Each observation records:

```text
source_name
source_kind
source_version
observed_at
confidence: authoritative | reported | inferred | unavailable
```

Vendor log schemas and OAuth-backed quota endpoints can change. Adapter failure
must degrade to `unavailable` without blocking normal wtcraft verification.

## Evidence schema sketch

The stable schema is more important than the first classifier.

```json
{
  "schema_version": 1,
  "decision_id": "uuid",
  "task_id": "feat/fix-refresh",
  "session_id": null,
  "repository_fingerprint": "local-pseudonym",
  "prompt_fingerprint": "sha256:redacted",
  "classification": {
    "work_kind": "execution",
    "size": "s",
    "risk": "medium",
    "confidence": 0.84,
    "classifier_version": "rules-v1",
    "recommended_sequence": ["execution", "verification"]
  },
  "forecast": {
    "tokens_p50": null,
    "tokens_p90": null,
    "quota_delta_p50": null,
    "quota_delta_p90": null,
    "forecast_version": "cold-start-v1",
    "confidence": "low"
  },
  "quota_snapshots": [],
  "recommendation": {
    "role": "executor",
    "provider": "configured-provider",
    "model_tier": "balanced-coding",
    "reasoning_tier": "medium",
    "reason_codes": ["bounded-change", "verification-reserve"],
    "policy_version": "quota-policy-v1"
  },
  "human_decision": {
    "status": "pending",
    "override_reason": null
  },
  "outcome": null
}
```

After execution, `outcome` may include observed usage, final revision,
`check`/`verify` evidence references, repair rounds, human disposition, and
whether the work shipped. Store fingerprints and aggregates by default; prompt
or transcript contents are opt-in and never required for quota accounting.

## Storage and privacy

- Local-first and append-only.
- Store under Git common-dir wtcraft metadata, not in the worktree or tracked
  source tree.
- Do not copy provider OAuth credentials.
- Do not persist prompt, response, transcript, or code content by default.
- Pseudonymize repository and task identifiers for exports.
- Make deletion and retention explicit.
- Treat prompt/tool content as sensitive even when OpenTelemetry supports it.

Candidate local path:

```text
<git-common-dir>/wtcraft/usage/events.jsonl
```

The event log is local evidence, not trusted merge authorization. A future
exporter can emit OpenTelemetry GenAI attributes for provider/model, input,
output, cache, reasoning, workflow, evaluation score, and decision IDs.

## Evaluation plan (`wteval`)

> Superseded in part by
> [agent-capability-eval.md](agent-capability-eval.md). The deterministic-oracle
> eval described there stands alone and does not depend on the advisor being
> built. The dataset below is compatible with it: this section adds the
> forecast and classification labels an advisor needs on top of the same runs.

The evaluation lab is the sibling public repository
[`wteval`](https://github.com/zywkloo/wteval), not a public `eval/` tree in
this repo. Public wtcraft stays a Git-native governance core. Personal dogfood
labels stay gitignored in `wteval/datasets/private/`.
Interview-visible output from the experiment, if any, is a later methodology
report rather than product code here.

### Dataset

Start with 30–50 real wtcraft/wtflow dogfood tasks across at least two
providers. For each task:

- preserve the prompt fingerprint and optionally a redacted prompt;
- human-label work kind, size, and risk;
- capture repository/task features available before execution;
- capture before/after quota snapshots when available;
- capture provider/model/reasoning tier and observed tokens;
- attach deterministic `check` and `verify` outcomes;
- label replan/repair rounds and human overrides.

Do not train and evaluate on the same tasks. Keep a chronological holdout to
expose drift.

### Metrics

| Component | Initial metric |
| --- | --- |
| Work-kind classifier | Macro F1 and confusion matrix. |
| Size/risk classifier | Macro F1 plus adjacent-tier tolerance. |
| Token forecast | Median absolute/log error and p50/p90 interval coverage. |
| Quota forecast | Absolute percentage-point error and interval coverage. |
| Recommendation | Verified success rate, quota per verified task, repair rounds, and human override rate. |
| Reliability | Missing-data rate, adapter parse failures, and stale quota observations. |

Counterfactual model-routing quality is not observable from one chosen run.
Any claim that provider A was better than provider B requires controlled replay
or a matched benchmark, not historical selection-biased data.

### Provisional go/no-go gate

Continue past the pilot only if:

- at least 30 human-labeled tasks exist;
- the classifier beats a simple majority/keyword baseline;
- prediction intervals are meaningfully calibrated rather than cosmetic;
- quota recommendations expose reason codes and never fabricate missing data;
- at least one recommendation or reservation decision changes after outcome
  feedback;
- the resulting report answers a decision the existing usage dashboards do
  not answer.

If not, keep wtcraft's existing role/task governance and integrate a dedicated
usage tool without building a prediction product.

## Observability and AI stack

This is a legitimate, bounded place for AI-engineering tools:

- **LangChain model adapters / structured output:** optional LLM classifier;
- **LangGraph:** conditional low-confidence escalation and human-decision flow;
- **OpenTelemetry GenAI conventions:** portable spans and usage attributes;
- **LangSmith or Phoenix:** traces, labeled datasets, experiments, and
  comparison—not the system of record;
- **MCP:** optional read-only tools such as `advise_task`, `get_quota_state`,
  and `explain_recommendation` after the CLI contract is stable.

Do not add all of them merely for keywords. A plain deterministic classifier
and local JSON schema should remain the baseline every AI-assisted version must
beat.

## Delivery plan

### P0 — Reconcile historical work

- Inventory `origin/feat/budget-tracker` and
  `origin/claude/token-budget-analysis-9r74l`.
- Extract reusable product requirements and fixtures.
- Record obsolete assumptions and do not merge the branch wholesale.
- Decide whether the public command name is `advise`, `plan-usage`, or another
  term; avoid overloading `budget` with both prediction and accounting.

### P1 — Manual dataset pilot

- Freeze representative TokenTracker quota fixtures and implement a read-only
  prototype adapter against its existing local JSON API.
- Define a versioned `limits --json` or `snapshot --json` contract suitable for
  an upstream-compatible contribution.
- Select 30–50 recent sessions/tasks.
- Map them to wtcraft task IDs, roles, stages, and verification outcomes.
- Human-label work kind/size/risk.
- Produce a notebook/report with baselines and missing-data analysis.

No runtime product code before this phase answers whether the data is usable.

### P2 — Stable evidence schema and deterministic advisor

- Freeze decision/outcome schema v1.
- Implement feature extraction and rules classification.
- Emit human and JSON output.
- Add user override and explicit missing-data states.
- Add contract fixtures for every classification and failure mode.
- Record `advisor_route` separately from `recommended_route`.
- Define endpoint capability/availability schema without changing generated
  role-model presets in isolation.

### P3 — Forecast baseline

- Implement bucketed p50/p90 forecasts.
- Backtest chronologically.
- Capture quota before/after snapshots through adapters.
- Separate tokens, API-equivalent cost, and quota delta in every output.

### P4 — Optional LLM classification graph

- Add an install extra rather than a mandatory dependency.
- Support `always` for initial dogfood and `low-confidence`, `shadow`, and
  `off` policies; measure before choosing a general default.
- Require structured output and version prompts/graphs.
- Trace rules and LLM decisions separately.
- Compare against the deterministic baseline in wteval.
- Use the fixed configured `advisor` route with ordered availability fallback;
  never recursively route the current classification through its own output.

### P5 — Recommendation policy, dry-run only

- Apply capability, privacy, risk, and quota hard constraints.
- Recommend provider/model/reasoning tier from the existing role-model config.
- Join role preference with the endpoint capability/availability matrix.
- Reserve verification and repair headroom.
- Emit auditable reason codes and fallback choices.
- Require a human decision; do not launch or switch accounts.

### P6 — Outcome feedback and public evaluation

- Attach sessions and observed usage to decisions.
- Join deterministic check/verify evidence.
- Track repair/replan rounds and overrides.
- Export OTel traces and one LangSmith/Phoenix experiment.
- Publish methodology, limitations, and actual metrics.

### P7 — Optional surfaces after evidence

- focused TokenTracker fork/upstream PR for a stable machine-readable quota
  contract, without prompt ingestion or dashboard rebranding;
- minimal wtflow instruction enable/disable and Quota Cat cat-and-jars advice
  rendering, only if the advisor changes real choices;
- read-only MCP server;
- explicit handoff/run wrapper;
- team export or cross-machine aggregation only with a demonstrated user need.

## Historical branch disposition

The remote `origin/feat/budget-tracker` branch contains valuable intent and
roughly 1,400 lines of design/implementation work, including cost reporting,
budget rules, handoff, and quota-aware routing. Treat it as research material,
not merge-ready code.

Reuse:

- before-execution recommendation versus after-execution accounting split;
- source-confidence and unavailable-data concepts;
- worktree/task attribution;
- role-level fallback and explicit dry-run/human control;
- adapter degradation rather than one vendor as core truth.

Reject or rewrite:

- hard-coded historical model prices;
- `characters / 4` as token truth;
- cache-hit inference based only on elapsed time;
- a fixed token-to-subscription-quota conversion;
- claims that branch-only behavior is already shipped on `main`;
- direct dependence on mutable vendor JSONL schemas;
- automatic account switching or launch in the first version.

## Risks

| Risk | Mitigation |
| --- | --- |
| Vendor log/quota schema churn | External adapters, version/source metadata, contract fixtures, fail to unavailable. |
| Subscription quota is opaque | Predict observed quota delta separately; use ranges and confidence. |
| Classification call wastes quota | Rules first; LLM only on low confidence; allow a local classifier. |
| Prompt and code leakage | Local-first, fingerprint/redact by default, content opt-in only. |
| False precision | Quantile ranges, calibration metrics, explicit cold-start state. |
| Cheap routing reduces quality | Hard quality/risk floors and verified-outcome feedback. |
| Historical selection bias | Controlled replay/matched tasks before cross-model superiority claims. |
| Model identifiers rot | Read the configured role-model registry; keep policy tiers semantic and version the resolved choice. |
| Scope becomes an agent platform | Advisory CLI first; no launcher, gateway, account manager, or dashboard. |

## Resume-readiness gate

This gate governs claiming that **an advisor product exists**. It is not the
gate for reporting a measurement result: see
[agent-capability-eval.md](agent-capability-eval.md), which needs neither
forecasting, tracing, nor a second provider adapter to publish a
verified-success-rate table honestly. Do not let this heavier bar block the
lighter one.

Do not describe this as implemented until an end-to-end vertical slice exists.
A credible portfolio claim requires:

- real structured LLM integration or a clearly measured deterministic baseline;
- at least two provider/quota adapters;
- a labeled dogfood dataset and held-out evaluation;
- p50/p90 forecast metrics;
- OTel traces plus a LangSmith/Phoenix comparison;
- outcome linkage to wtcraft verification;
- documented privacy, schema drift, missing data, and human override behavior.

Even then, use “dogfooded open-source agentic developer tool” until external
production use supports a stronger claim. This project can demonstrate applied
AI engineering; it cannot manufacture years of production LLM experience.

## Open questions

- Is `wtcraft advise` the right command, or should prediction live behind a
  separate optional package?
- Can current usage tools export stable per-session and subscription snapshots
  without wtcraft reading credentials?
- Which prompt/task features are available before a task contract exists?
- How should one raw prompt be split into a recommended role sequence?
- What is the smallest local classifier that beats deterministic rules?
- What retention window produces useful calibration without storing sensitive
  content?
- Which tasks are safe and cheap enough for controlled cross-provider replay?
- What amount of external adoption is needed before moving the feature from
  backlog to roadmap?

## Related

- [Task State Machine v1](../protocol/task-state-machine-v1.md)
- [Session Model v1](../protocol/session-model-v1.md)
- [`wtcraft model-select`](../model-select.md)
- [Stage state machine backlog](stage-state-machine.md)
- [wteval Quota Cat overlay UX](https://github.com/zywkloo/wteval/blob/main/docs/ambient-companion.md)
