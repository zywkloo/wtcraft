# Quota-aware model-select

> Status: not scheduled. Spec lives in `../model-select.md`
> ("Quota-Aware Recommendation" section) — this memo tracks the work item.

Recommend which CLI/model the next task should use, based on **role + stage +
remaining subscription-window quota**. Stage is already encoded in the role
(planner/executor/verifier/finisher), so the orchestrator just passes the role
for the upcoming stage.

## Why this one

- Serves the real daily need: solo dev on 1–3 subscriptions (not API
  pay-as-you-go); the binding constraint is window quota, not dollars.
- None of the surveyed competitors (workmux, Worktrunk, Vibe Kanban, Composio
  AO, Bernstein) do quota-aware routing — rare case of differentiation that is
  also a personal need.
- Hobby-sized: ~2–3 days, bash-able with existing awk patterns.

## Sketch

```bash
wtcraft model-select --role executor
# codex (GPT-5.4) — claude window 87% used, codex 12% used
```

### Pacing advisor (same data, second output dimension)

Beyond "which CLI for the next task", answer "what pace": ease off, push
hard, or switch agent. Pure rule table over (remaining %, time to reset) per
CLI — windows don't roll over, so unused quota at reset is wasted
("use it or lose it" cuts both ways):

| Remaining | Reset | Advice |
|---|---|---|
| high | soon | push hard — burn it before it resets |
| high | far  | proceed normally |
| low  | soon | ease off, coast to reset |
| low  | far  | switch to the idlest CLI in the fallback chain |

```bash
wtcraft model-select --role executor --pace
# codex (GPT-5.4)
# claude: 87% used, resets 14:00 (2h10m) → ease off
# codex:  12% used, resets 16:30 (4h40m) → push
```

Thresholds (what counts as high/low/soon) live in config next to `matching:`,
not hardcoded.

1. Resolve role → `cli` + `fallback` chain from role-models.yml (existing spec)
2. Query each candidate CLI's window consumption from local session logs via
   ccusage / tokscale JSON output (**optional** dependency)
3. Walk the chain left to right; recommend the first CLI with headroom above a
   configurable threshold
4. No usage tool detected → degrade to availability-only routing; never block

## Constraints / known limits

- Local logs measure *consumption on this machine*, not account-side quota
  truth; multi-device usage of the same subscription will read optimistic.
  Acceptable: all agents run on this one Mac.
- **Better quota source for Claude Code** (2026-06-10 finding): the statusline
  hook receives `rate_limits` fields (account-side percentages) during active
  sessions. A statusline script that tees them to e.g.
  `~/.wtcraft/quota-claude.json` gives truth instead of estimation, at zero
  scraping cost. Use it when present; fall back to log estimation.
  Codex/Gemini equivalents unknown — see `external-watchlist.md`.
- **Rejected: tmux send-keys/capture-pane scraping** of in-session commands
  (`/status` etc.). Technically possible, but needs idle detection, blind
  typing into live sessions, and cron polling — fragile scaffolding that
  becomes obsolete the day providers ship a quota API (heavily requested:
  anthropics/claude-code #44328 etc.). Lightweight line: statusline tee +
  log estimation only. `--pace` tolerates asymmetric data quality
  (claude = truth, others = estimate).
- Keep decoupled from `wtcraft budget` per the rule in `../model-select.md`:
  quota enters as an input, the commands don't merge.

## Related

- `wtcraft budget` (PR #12) — measurement side; its recommendation events
  should call model-select, not duplicate routing logic.
- A one-line habit hint in budget output (e.g. "codex window idle 60% over
  30 days — route more executor traffic there") is the maximum scope for
  subscription-purchase advice; see `not-doing.md`.
