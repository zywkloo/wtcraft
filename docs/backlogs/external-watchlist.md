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

### Git GUI landscape matrix (2026-06)

Popularity proxies: Homebrew 365d cask installs (macOS-only — understates
SourceGit, whose base skews Windows + Chinese community) and GitHub stars
(historical honor, not active usage — see GitUp).

| Tool           | Price/License     | Platforms | Installs/yr | Stars | Worktree |
|----------------|-------------------|-----------|------------:|------:|----------|
| GitHub Desktop | free, MIT         | Win/mac   | 48,661      | 21.6k | ✗ |
| SourceTree     | free, closed      | Win/mac   | 18,066      | —     | ✗ (years-old request) |
| Fork           | $59.99 once       | Win/mac   | 13,057      | —     | ✓ basic |
| GitKraken      | freemium/sub      | 3-plat    | 7,453       | —     | ✓✓ Agent Mode |
| Sublime Merge  | $99 once          | 3-plat    | 4,963       | —     | ✗ |
| GitButler      | FSL (src-visible) | 3-plat    | 3,418       | 21.0k | ✗ (virtual branches paradigm) |
| Tower          | ~$69/yr sub       | Win/mac   | 2,179       | —     | ✗ |
| SourceGit      | free, MIT         | 3-plat    | 1,618       | 5.4k  | ✓ full |
| Gittyup        | free, MIT         | 3-plat    | 743         | 2.2k  | ✗ |
| SmartGit       | commercial        | 3-plat    | 634         | —     | ✓ |
| Gitnuro        | free, GPL-3       | 3-plat    | <threshold  | 2.6k  | ✗ |
| GitUp          | free, GPL-3       | mac only  | 47          | 12.0k | ✗ (effectively dead) |

(lazygit, 79.2k★, is the category star king but TUI — out of scope.)

Takeaways:

- **Worktree support is a minority feature**: 4 of 12 GUIs (GitKraken,
  Fork, SmartGit, SourceGit). Among them only SourceGit is open source —
  the fork-base choice was effectively forced.
- Stars ≠ usage: GitUp 12k★ / 47 installs-yr; GitButler 21k★ (HN hype) /
  3.4k installs. SourceGit's 5.4k★ / 1.6k-installs ratio is healthy and
  climbing (releases biweekly, 7–9k downloads each cross-platform).
- **GitButler is the anti-worktree pole**: virtual branches put parallel
  work in one working dir — the opposite of wtcraft's worktree-isolation
  philosophy. Useful as a positioning contrast.
- SourceGit vs Sublime Merge directly: SM ~3× installs on macOS but its
  updates are fixes/perf only; SourceGit ships features biweekly.
  SourceGit's top open complaints: Askpass spam (#1577), big-repo perf;
  top asks: auto-updater (#1575, +14 — fork users won't auto-update
  either, distribute via Homebrew tap), conflict-window editing (#2168),
  uncommitted-changes-in-graph (#1673 — the Sublime Merge feature
  switchers will miss; upstream-scale work, don't build it in the fork).

### SourceGit maintainer background (public info, 2026-06)

`love-linger` ("leo"), Chengdu, China. GitHub since 2013; no bio/blog/
company listed, 44 followers despite the 5.4k★ project — deliberately
low-profile. 4,220 of ~5,400 commits (78%) are his; only 3 other humans
above 40 commits. His 4 other public repos are all support forks for
SourceGit work (Avalonia, AvaloniaEdit, protobuf, winget-pkgs). Oldest
fork snapshots (2021) describe SourceGit as "Windows GUI client" — it
began Windows-only (WPF era) and later went cross-platform via Avalonia,
which explains the Windows-heavy user base and issue traffic.

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
