# External watchlist

Upstream projects relevant to wtcraft — things to watch, adopt, or contribute
small PRs to. Recorded 2026-06-10.

## tokscale (junhoyeo/tokscale)

Cross-CLI token usage tracker (30+ clients: Claude Code, Codex CLI, Gemini
CLI, …). Rust CLI, open source, plus a hosted leaderboard/profile service at
tokscale.ai. Reads **local session logs only** (e.g. `~/.claude/projects/**/*.jsonl`,
`~/.codex/sessions/`) — no API keys, no provider account access; GitHub login
is only for leaderboard submission.

### Watch: Antigravity CLI support

tokscale supports the Antigravity *IDE* today; the standalone *CLI* is the
gap. Antigravity CLI stores usage in SQLite + protobuf blobs (not JSONL);
field mappings are being reverse-engineered in
[PR #703](https://github.com/junhoyeo/tokscale/pull/703)
(related issues: #648, #574, #561). Relevant once quota-aware model-select
wants Antigravity as a candidate CLI.

### Contribution opportunity: SNS share cards

Profile pages (`tokscale.ai/u/<user>`) lack a PNG `og:image`, so pasting a
profile link into X/socials renders no preview card. Existing embeds are SVG
(fine for GitHub README, which only allows images; useless for `og:image`,
which doesn't accept SVG). Small PR: PNG render endpoint (satori/resvg over
the existing SVG templates), ~1–2 days, no architectural changes — unlike the
workmux Windows idea (see `not-doing.md`).

## ccusage (ryoppippi/ccusage)

`ccusage blocks --live` — realtime dashboard of the current 5-hour
subscription window, aggregated across all local sessions/worktrees. Answers
"is my subscription paying for itself" by computing API-equivalent cost from
local logs. Subscription-friendly; no tmux needed for token monitoring.

## SessionWatcher (closed source, macOS)

The only found tool that shows **remaining** subscription quota, not just
consumption: 5-hour window + weekly cap + reset time per provider, live in
the macOS menu bar. Covers Claude Code, Codex, Copilot, Cursor, Gemini CLI,
Antigravity. $2.99–7.99 one-time. Local processing, closed source — useful as
a human-facing display, not as a data source for wtcraft.

## Worktree agent GUIs (2026-06 landscape)

Surveyed for the stage-state-machine observer/GUI direction. Recorded
2026-06-11. Conclusion: worktree dashboards and agent runners are crowded;
**nobody does file-based, repo-native task state** (TASK.md as truth) or
Scope/Off-limits/verification governance. Every tool below keeps state in its
own app/DB and wants to *own* the workflow by spawning agents.

- **GitKraken Desktop 12.0 Agent Mode** (2026-04) — commercial; agent
  sessions panel per worktree, running/waiting/done status, spawns Claude
  Code/Codex/Copilot/Gemini/OpenCode. Closest commercial product; no
  task-contract concept.
- **Vibe Kanban** (BloopAI, Apache-2.0, Rust+React) — kanban state machine
  over worktrees, but: agent runner, own DB, runs agents with
  `--dangerously-skip-permissions` by default (anti-governance). Sunsetting
  since early 2026. Reference for board UI only.
- **Conductor** (conductor.build) — Mac-only Claude Code worktree runner.
- **Superset** (ELv2) / **Crystal→Nimbalyst** — macOS-first agent
  editors/runners.
- **Parallel Code** (johannesjo, MIT, Electron+SolidJS) — worktree-first
  dashboard + diff review, BYO agent/editor. macOS+Linux only (no Windows).
  Viable fork base if a TS path is ever wanted.

### Fork base: SourceGit (chosen direction)

MIT, C#/Avalonia, Windows/macOS/Linux, worktree GUI already built in, very
active (v2026.12, 2026-06-01, 5.4k★). Plan: add a governance panel that
reads `worktrees/**/.worktree-task.md` + `wtcraft status --json` — the
bounded delta, since worktree support already exists. Sublime-Merge-class
client, fits "GUI instead of CLI" preference.

Full customization plan with mount points and weekend scope:
`sourcegit-governance-fork.md`.

## Account-side quota: access paths (2026-06 state)

- **No public API.** Open feature requests: anthropics/claude-code #44328,
  #45392, #19880, #32796. The OAuth usage endpoint returns rolling-window
  consumption *percentages* only (no absolute numbers or plan limits).
- **Claude Code statusline receives `rate_limits` fields** during an active
  session — a custom statusline command can tee these percentages to a local
  file, giving account-side truth with zero scraping. This is the most
  promising quota source for `model-select-quota.md`.
- ccusage/tokscale measure per-machine consumption from logs — estimation,
  optimistic if the same subscription is used on multiple devices.
