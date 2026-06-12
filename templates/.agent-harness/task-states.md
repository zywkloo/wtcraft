# Task Stage State Machine

The `stage:` frontmatter field in `.worktree-task.md` is the authoritative
lifecycle state of a worktree task. Tools (`wtcraft status`, observers,
alarms) read `stage`; the older `status:` field is kept as a coarse legacy
indicator and is used as a fallback when `stage` is absent.

## Frontmatter fields

```
stage: planned        # FSM state — see lifecycle below
role: executor        # pipeline role currently responsible for the task
status: ready         # legacy coarse state (kept for back-compat)
```

`role` values match the keys in `role-models.yml`
(planner / executor / verifier / finisher).

## Lifecycle

```
planned → executing → verifying → approved → finishing → done
                          │
                          └→ replan → planned   (loopback)
```

## Transition table

Each transition has exactly one owning role — only that role may write the
task file at that point. This single-writer rule is also the concurrency
protocol: at any moment the file has one legal writer, so no locking is
needed.

| transition            | owner    | trigger                                      |
|-----------------------|----------|----------------------------------------------|
| (create) → planned    | planner  | contract written (`/planwt`, `wtcraft new`)  |
| planned → executing   | executor | work starts in the worktree                  |
| executing → verifying | executor | implementation complete, verification run    |
| verifying → replan    | verifier | verify/check failed, or premises challenged  |
| verifying → approved  | human    | re-plan checkpoint confirmed (finisher records) |
| replan → planned      | planner  | contract revised and reissued                |
| approved → finishing  | finisher | push / PR / cleanup begins                   |
| finishing → done      | finisher | verification recorded, worktree finishable   |

Verifier responsibilities currently live in `finisher.md` (steps 2–4);
the owner column names the role, not the file.

Any stage change not in this table is an **illegal transition** (see the
alarm catalog in the wtcraft repo, `docs/backlogs/stage-state-machine.md`).

## Write discipline

- Update `stage` with `wtcraft`'s frontmatter helper or an equivalent
  read-modify-write that lands via temp-file + `mv` (atomic rename), so
  readers never see a half-written file.
- Do not edit the task file when you are not the owner of the current
  stage. If you believe the stage is wrong, report it instead of fixing it.
