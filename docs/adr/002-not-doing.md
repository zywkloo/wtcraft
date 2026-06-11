# Decided not to do

Rejected directions with reasons — don't re-litigate without new facts.
Recorded 2026-06-10.

Note: *deferred* items (might happen, open to contributors) live in
`README.md`, not here — e.g. the Rust migration.

## `wtcraft monitor` / tmux integration

workmux, Claude Squad, Vibe Kanban, Worktrunk etc. already own the
"worktree + multiplexer + agent lifecycle" space — crowded, actively
maintained, and Claude Code ships native worktree isolation. The underlying
need ("what state is everything in") is covered by verify write-back +
`wtcraft status`; realtime token viewing is covered by ccusage/tokscale
(see `external-watchlist.md`). No polling panes required.

## Contributing Windows support to workmux

Maintainer wontfixed it ([workmux #85](https://github.com/raine/workmux/issues/85)):
internals are POSIX-bound by design (bash, named pipes, process control);
official answer for Windows users is WSL. A PR would be an architectural
rewrite the maintainer doesn't want.

## Subscription recommendation as a mass-market product

What's rejected is the *product* version: serving other people's plan
decisions, which means perpetually tracking every provider's pricing and plan
quotas — and the data moat belongs to whoever already holds usage data
(tokscale-shaped projects).

A scoped-down, rule-based *personal* version is fine and lives in
`subscription-fit.md`: no ML needed, the math is trivial; the user maintains
their own plan-quota table in YAML.
