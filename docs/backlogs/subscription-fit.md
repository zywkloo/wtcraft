# Subscription fit check (personal, rule-based)

> Status: idea — smaller sibling of the rejected mass-market recommendation
> engine (see `not-doing.md` for what's explicitly out of scope).

Answer two questions from local usage data, no ML — plain arithmetic:

1. **"Is my current plan paying for itself?"** — 30-day tokens priced at API
   rates (ccusage already computes this) vs subscription price.
2. **"Is my money in the right place?"** — per-CLI window utilization, e.g.
   "claude windows hit 90%+ on 18 of 30 days; codex window idle 60% — consider
   upgrading claude tier / downgrading codex, or route more executor traffic
   to codex" (the routing half is `model-select-quota.md`'s job).

## Why this is hobby-sized after all

The algorithm was never the problem — it's `usage × price` comparisons. The
heavy part of the product version is maintaining every provider's plan/quota
table. Scoped to personal use, that burden disappears:

- **Pricing**: reuse LiteLLM's community-maintained price data (tokscale
  already depends on it) — someone else keeps it fresh.
- **Plan quotas**: the user maintains their own 3-line YAML of plans they
  actually pay for (e.g. `claude: max5x, window_tokens: ~88k`). No provider
  publishes these stably; for N=1 user, hand-maintained is fine.

## Shape

A report section in `wtcraft budget` output (not a separate command), emitted
only when a usage tool (ccusage/tokscale) and the user's plan YAML are both
present. Degrades to silence otherwise.

## Boundary

This advises on *purchases* (slow loop, monthly). Task-time routing — "for the
next executor task use X" — is `model-select-quota.md` (fast loop, per task).
The two share data sources but stay separate features.
