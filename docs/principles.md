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

