# wteval reconciliation

> Status: audit record, 2026-09-12. Compares what wtcraft says about wteval with
> what the wteval repository contains. It schedules nothing. README wording and
> the [capability-eval memo](agent-capability-eval.md) were corrected in the
> same change; the open questions at the end are unresolved.

## Baseline

- wtcraft `main` at `a1396f1`. Line numbers below refer to that revision.
- wteval `main` at `75c3f0e`, the public revision (GitHub repository created
  2026-09-03). Every verdict is against this revision.
- `tests/run_all.sh` passes on a clean export of wteval `75c3f0e`, and
  `scripts/run_pbt.py --properties pbt_properties/wtcraft.py` passes against
  wtcraft `a1396f1`.
- The local wteval checkout also has unpushed work, a bounded agent adapter and
  a task-admission script. It is summarized under
  [Unpushed wteval work](#unpushed-wteval-work) and changes no verdict, because
  a reader of the public repositories cannot inspect it.

Verdicts: **Accurate**; **Stale** (was true, no longer is); **Never
implemented** (wteval has not built it); **Overstated** (something exists, but
less than the text claims). Nothing was stale: every mismatch is a description
that ran ahead of the code.

## 1. Fact check

### README.md

| Line | Statement | Verdict | Evidence in wteval `75c3f0e` |
| --- | --- | --- | --- |
| 10–11 | wtcraft and wteval "establish a closed loop for trustworthy agent execution" | Overstated | Nothing flows back to wtcraft yet: no agent run exists and no report is cited. The only working direction is wteval reading wtcraft's source and fixtures. |
| 13 | wteval "evaluates whether those acceptance checks catch defects via mutation testing" | Overstated | Mutation tooling exists (`wteval/mutation.py`, `scripts/run_mutation.py`, `scripts/seed_mutations.py`), but it covers Python sources only (AST sites, `py_compile`), uses 12 operator-flip rules, and runs a `--test-cmd` the operator supplies. Nothing reads a task contract's Verification entries, so Planner-declared checks are not what is wired in. The one wtcraft example mutates `scripts/policy_evaluator.py` against wtcraft's own `tests/contract_policy_envelope.py`. |
| 13 | wteval "benchmarks agent capability" | Never implemented | `ManualRunner` is a no-op (`wteval/executor.py`); `scripts/run_executor.py` only writes a schedule; wteval `docs/executor.md` lists worktree setup, live check/verify, and a real runner as not built. Committed capability runs are synthetic fixtures. |
| 13, 41–43, 169 | experimental open-source lab, not published to any package platform | Accurate | Public GitHub repository, Apache-2.0; no `pyproject.toml` or `package.json`; PyPI and npm both return 404 for `wteval`. |
| 38–40 | wteval "tests that acceptance layer with mutation and property-based testing" | Overstated | Mutation: see line 13. PBT: `pbt_properties/wtcraft.py` asserts wtcraft's policy evaluator is deterministic and does not crash. That tests the authorization evaluator, not declared acceptance checks; the remaining properties are generic demos. wteval `docs/mutation-pbt.md` itself assigns mutation to "the tests" and PBT to "the oracle". |
| 40–41 | "`wtcraft verify` asks whether the declared checks passed; `wteval` asks whether those checks can detect defects" | Accurate as a statement of purpose | The same sentence is wteval README's design principle. As a capability it is partial (line 13). |
| 44–46 | ambiguous findings go to human review, e.g. equivalent mutant versus test gap | Accurate, documentation-level | Mutation outputs keep survived sites in `records` for manual triage; wteval `75c3f0e` documents the review boundary. There is no review tooling. |

README lines 10–13 and 37–46 were rewritten to match this table. Line 169 was
accurate and is unchanged.

### docs/roadmap.md

| Line | Statement | Verdict | Evidence |
| --- | --- | --- | --- |
| 232–236 | the contract-effectiveness experiment runs in wteval: a 5–10-task paired pilot, then at least 30 qualified paired tasks | Accurate | Matches wteval `docs/lab-boundary.md`, `docs/capability-eval.md`, and the P0/P1 order of `docs/mvp-plan.md`. "Runs in" names the location; nothing has run. |
| 240 | wtcraft takes a report citation, not eval code or new semantic evidence fields | Accurate | wtcraft has no eval code; wteval writes nothing into wtcraft evidence (section 2). |

### docs/backlogs/agent-capability-eval.md

| Line | Statement | Verdict | Evidence in wteval `75c3f0e` |
| --- | --- | --- | --- |
| 3 | "real-run pilot pending" | Accurate | Executor not connected; the MVP plan's admission and execution items are unchecked. Local attempts exist, but no agent run completed ([Unpushed wteval work](#unpushed-wteval-work)). |
| 13 | oracle includes **compile** checks | Never implemented | No compile signal in wteval's schema, scoring, or docs, and the memo's own signal table has no compile row. `py_compile` only discards stillborn mutants during mutation scoring. See [Q1](#open-questions). |
| 13 | oracle includes **test** checks | Overstated | `result.verify` is scored from records and the seeder runs the test command against mutants, but no committed code runs verification against an agent's change. |
| 13 | oracle includes **scope** checks | Never implemented | `result.check` exists in `capability-run-v1` and the docs say it comes from `wtcraft check`, but no committed code invokes `wtcraft check`. |
| 34 | "Task passed: `verify` runs the task contract's declared commands" | Overstated; the repositories disagree | wteval `docs/capability-eval.md` names `wtcraft verify` as the oracle, but `docs/executor.md` maps `result.verify` to the verification command's exit code, and the unpushed adapter runs the frozen command directly in a separate scoring workspace. See [Q2](#open-questions). |
| 36–37 | repair rounds and token/quota listed among "wtcraft's outputs" | Overstated | The wtcraft CLI records neither; wteval takes both from the runner (`RunnerResult`). The table now says so. |
| 59–62 | admission needs a failing buggy state and a reproducibly passing reference repair | Never implemented | The seeder requires one green baseline run and a repeated buggy failure. It does not re-run the reference or check that the failure is behavioral. `docs/mvp-plan.md` leaves admission unchecked. |
| 64 | private task catalogs remain in wteval | Accurate | `datasets/private/` is gitignored. |
| 69–76 | two arms with one fixed configuration | Never implemented (execution) | The arms exist in the schema and schedule; neither has been executed. |
| 88–89 | verified success rate, scope violation rate | Accurate (scoring only) | `wteval/capability.py` computes both with Wilson intervals, excluding `skip`/`unavailable`. |
| 90 | repair rounds with unbounded failures censored | Never implemented | Only a mean; no censoring. |
| 91 | quota per verified task; missing usage unknown, not zero | Overstated | The ratio uses the quota-observed cohort, but `quota_consumed` sums to `0` when nothing was observed, which wteval's own MVP plan flags. |
| 93–96 | frozen scoring inputs, no access to reference repairs, equal budgets, retained failures, paired outcomes | Never implemented | wteval `docs/executor.md` lists these as unmet requirements. No version of `capability.py` reports paired outcomes. |
| 100 | report intervals | Overstated | Per-arm Wilson intervals exist; no interval on the paired effect. |
| 113–114 | a "consumer of existing evidence, needing no change to Phase 6" | Accurate but loose | It needs no Phase 6 change because it reads no Phase 6 evidence (section 2). |
| 144 | "The harness lives in `wteval`, published." | Accurate but ambiguous | The repository is public, but "published" read as contradicting README's "not published to any package platform". Reworded to "public repository". |
| 155 | wtcraft keeps zero eval dependencies | Accurate | — |
| 169 | the two experiments share a dataset and a runner | Overstated | Scoring is shared (grouped by arm, then agent); there is no runner. |

The other wteval mentions (`docs/backlogs/README.md:19–22`,
`docs/backlogs/quota-aware-task-planning.md:527–529` and `:760`) state intent or
link to files that exist, and are accurate.

## 2. Evidence boundary (ADR-012)

**No crossing in the direction ADR-012 guards.** wteval never writes to
wtcraft evidence, the `wtcraft-policy` branch, or the policy-envelope schema.
Evaluator-domain fields stay in wteval's own schemas, where ADR-012 places
them: `work_kind`, `size`, and `risk` in `example-v1` and `decision-v1`, and the
unpushed `agent_status` and `quota_context` in `capability-run-v1`.

**wteval does not consume trusted evidence either.** ADR-012 expects evaluator
output to reference evidence by `policy.digest` and `change.head_sha`;
`capability-run-v1` carries neither and keys runs by `repository`,
`base_revision`, and `oracle_revision`. The planned scope signal is local
`wtcraft check` against a contract the evaluator writes itself, not
policy-envelope evidence. That is legitimate, but it means this experiment does
not exercise ADR-012's revisit trigger. Read the memo's "consumer of existing
evidence" as "consumer of check results", not "consumer of Phase 6 evidence".

**No field is waiting on wtcraft.** Machine protocol v1 already separates a
negative gate (`ok: true`, `check` exit 2, typed `violations[].kind`) from a
fatal error (`ok: false`, exit 1), and `capabilities --json` reports
`cli_version` for pinning the scorer. Repair rounds and token usage are runner
and provider observations. As wtcraft fields they would bring non-Git facts
into the core, the same objection ADR-012 raises against risk tiers.

**Boundary risks outside ADR-012:**

- *Reverse coupling.* `pbt_properties/wtcraft.py` and the seeding examples
  address wtcraft implementation paths (`scripts/policy_evaluator.py`,
  `tests/contracts/policy-envelope/`, `tests/contract_policy_envelope.py`), not
  a documented interface. Pilot tasks are frozen by SHA and unaffected, but PBT
  and new seeding break if the ADR-006 extraction moves those files.
- *Refs written into the target repository.* `seed_mutations.py` creates
  `wteval/mut-*` branches in the repository it mutates; the local wtcraft clone
  held 42 at audit time. The policy adapter ignores them, but `git push --all`
  would publish them, and each task's `base_revision` resolves only in that
  clone.
- *Future pressure.* wteval's deferred advisor plan proposes a `wtcraft advise`
  command emitting work-kind, size, and risk classifications. That is command
  output, not trusted evidence, but it is the same domain model; review it
  against ADR-012 if the advisor resumes.

## 3. Gaps before a real-run pilot

Judged against public wteval `75c3f0e`; where the unpushed adapter already
covers or exhibits an item, the entry says so.

### Change wteval

1. **Land the runner and admission publicly.** Public wteval has neither.
   Unpushed: `scripts/run_pilot.py` and `scripts/admit_mutations.py`, with no
   tests for either script.
2. **Score the contract arm against a contract the agent cannot edit.** The
   adapter writes the contract arm's `.worktree-task.md` before the agent runs,
   and `wtcraft check` reads that same file afterwards. An agent that widens
   Scope or edits `base:` changes its own score, which memo line 93 rules out.
   Rewrite the contract for both arms after the run, or check against an
   evaluator-held copy.
3. **Stop recording infrastructure failures as gate results.** The adapter
   maps any non-zero `check` exit to `fail`, so a fatal error (exit 1,
   `ok: false`) is indistinguishable from a scope violation. A verification
   timeout is written as `result.verify: "timeout"`, outside the schema enum
   (`pass|fail|skip|unavailable`), so the report loader rejects the record
   instead of counting it. Agent infrastructure failures are detected by
   stderr substrings; anything unmatched, such as an agent CLI configuration
   failure, is recorded as `agent_failed`.
4. **Keep the scope signal independent of the target's `.gitignore`.** The
   adapter leaves `.worktree-task.md` untracked. That works for wtcraft tasks
   only because wtcraft's `.gitignore` lists the file (reproduced: the adapter
   scored an unmodified wtcraft task `check=pass`). In a scratch repository
   without that entry, `wtcraft check` (the 0.4.4 release and `main` alike)
   reports the task file itself as a `task_contract` violation and exits 2,
   even for an in-scope edit. Adding it to the snapshot's `.git/info/exclude`
   restores exit 0 for in-scope and exit 2 with `scope`/`off_limits` for
   out-of-scope edits.
5. **Observe repair rounds or drop the metric.** The adapter hard-codes
   `repair_rounds: 0` and `replan: false`, so the first-pass rate equals the
   verify rate and the memo's censored repair-round metric cannot be computed.
6. **Record the frozen configuration.** The manifest records model, seed, and
   timeout, but not the agent CLI version, sandbox and permission flags, the
   wtcraft scorer version, or the toolchain. The adapter's `claude` endpoint
   also runs without the sandbox flag its `codex` endpoint uses.
7. **Report paired outcomes.** `capability.py` (public and unpushed) reports
   per-arm rates only. The pilot report needs per-task pairs, discordant pairs,
   mutation clusters, and attempted versus scored counts (memo lines 95–96).
8. **Label the pilot mutation-only.** History tasks still have no runnable
   command.
9. **Minor.** The synthesized contract uses `stage: execution`, which is not a
   task-state-machine v1 stage (`executing` is); `check` ignores stage, but
   `status` and `observe` consumers may flag it. wteval
   `docs/capability-eval.md` still names `wtcraft verify` as the oracle
   ([Q2](#open-questions)).

### Change wtcraft

1. Documentation accuracy: done in this change (README lines 10–13 and 37–46;
   the memo's status, signal table, and "published" wording).
2. Resolve [Q1 and Q2](#open-questions) and align the memo's Decision sentence
   and signal table with the answer.
3. No CLI or protocol change is needed for the pilot (section 2).
4. Once a pilot or full report exists, cite it in roadmap Phase 8.

### Change both

Nothing the pilot strictly needs. The reverse coupling and the `wteval/mut-*`
refs from section 2 involve both repositories and should be settled before the
30-task report, not before the pilot.

## Unpushed wteval work

Present in the local wteval checkout on 2026-09-12 and absent from `75c3f0e`:

- `scripts/run_pilot.py`: bounded Codex/Claude adapter with an archive-only
  base workspace, reference copies removed, a separate scoring workspace, a
  seeded shuffle of arm order, and an explicit `--execute`;
- `scripts/admit_mutations.py`: reference-pass, buggy-fail, and
  target-only-repair-pass admission with repeats and recorded exclusions;
- `result.agent_status` and `usage.quota_context` in `capability-run-v1`, with
  validator and agreement tests, and quota aggregation that reports missing or
  mixed units as unknown.

Private admission and execution output exists locally. No recorded run has
`agent_status: completed`, so the real-run pilot is still pending. Gaps 2–6
come from reading and running this unpushed code.

## Open questions

- **Q1 — compile.** The memo's Decision names compile, test, and scope checks;
  its signal table and wteval have no compile signal. Drop "compile", or add a
  distinct signal to wteval?
- **Q2 — verify path.** The memo and wteval `docs/capability-eval.md` say
  `wtcraft verify`. wteval `docs/executor.md` and the adapter run the frozen
  command directly in a separate scoring workspace, and `wtcraft verify` writes
  its result into the agent-editable task file. Which is the intended oracle?
- **Q3 — arm contrast.** In the adapter, the no-contract prompt already says to
  change only the implementation target and not to edit tests, schemas, or
  templates. The contract arm adds explicit Scope/Off-limits lists, the
  verification command, and a task file. Is that the intended intervention, or
  should the no-contract prompt omit scope guidance?
- **Q4 — reproducibility.** Mutation base revisions exist only as branches in
  the operator's wtcraft clone, and the patches are private. Does the pilot
  need third-party re-runs, or is an operator re-run enough?
- **Q5 — wtcraft's own claim.** README line 12 says wtcraft "enforces worktree
  boundaries"; line 156 says the local task contract is not a security
  boundary. Outside the wteval audit, so left unchanged.
