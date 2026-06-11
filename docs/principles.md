# wtcraft Principles

## 1) Git-Native

`wtcraft` builds on `git worktree` instead of replacing it.
If a user can run git, they can run `wtcraft`.

## 2) Harness, Not Agent

`wtcraft` does not compete with coding agents.
It provides boundaries:
- task contract
- file ownership limits
- verification gates

## 3) Public by Default

All project docs must be safe for a fully public repository:
- no private infrastructure assumptions
- no secret environment requirements in core docs
- no personal internal process hidden as universal advice

## 4) Non-Invasive Setup

Do not overwrite existing `CLAUDE.md` or `AGENTS.md` by default.

Preferred pattern:
- keep harness logic under `.agent-harness/`
- add only small routing stubs to root agent files when needed
- provide explicit opt-in for automated patching

## 5) Boundaries Before Parallelism

Running more agents is not the goal.
Clear boundaries and mergeability are the goal.

Rule of thumb:
- shared files: serialize
- file-disjoint tasks after a shared foundation: parallelize carefully

## 6) Budget-Aware by Design

`wtcraft` should help solo developers control:
- token usage
- review load
- context switching cost

Every feature should be evaluated against these costs.

## 7) Small Reliable Steps

Prefer simple commands that fail clearly:
- `init`
- `status`
- `check`

Expand only after these are reliable.

## 8) Hybrid Orchestration: Strategic vs. Tactical

When integrating `wtcraft` with agent environments (like Claude Code or Codex CLI):
- **Strategic Actions (Slash Commands)**: Use these only for complex, multi-step orchestration workflows requiring deep planning, context gathering, or structured contract-writing (e.g., `/planwt`, `/finishwt`, `/statuswt`).
- **Tactical Actions (Direct CLI Executions)**: Do not wrap atomic CLI commands (like `wtcraft check` or `wtcraft verify`) in custom slash commands. Since modern terminal-based agents possess shell execution capabilities, they can natively run these commands directly in the terminal as guided by their harness instructions.

This hybrid model prevents agent-side command bloat while keeping the workflow flexible, reliable, and lightweight.

## 9) Prior Art and References

The term **harness engineering** was defined by [Martin Fowler](https://martinfowler.com/articles/harness-engineering.html) as the infrastructure and orchestration layer that wraps a coding agent — tooling, state management, error recovery, and boundary enforcement. `wtcraft` is a solo-developer implementation of that concept.

Production-scale validation:

| Source | Scale | Key insight |
|---|---|---|
| [Fowler — "Harness engineering for coding agent users"](https://martinfowler.com/articles/harness-engineering.html) | Conceptual definition | Harness = the layer between human intent and model execution |
| [OpenAI — "Harness engineering: leveraging Codex in an agent-first world"](https://openai.com/index/harness-engineering/) | 1M+ lines, 1,500+ PRs / 5 months | Context engineering + architectural constraints + entropy management |
| [Stripe — "Minions: one-shot, end-to-end coding agents"](https://stripe.dev/blog/minions-stripes-one-shot-end-to-end-coding-agents) | 1,300+ AI PRs / week | Deterministic [D] + agentic [A] step tagging; 2-round CI cap |

Fowler describes *what* harness engineering is. Stripe and OpenAI describe *how* it works at enterprise scale. `wtcraft` brings the same pattern to a solo developer with a limited budget.
