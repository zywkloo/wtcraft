# wtcraft

> **Your Cheap Token Orchestrator (CTO).**
> For developers who can afford 3 cheap subscriptions but not 1 expensive one.

[![npm version](https://img.shields.io/npm/v/wtcraft.svg?logo=npm&maxAge=300)](https://www.npmjs.com/package/wtcraft)
[![PyPI version](https://img.shields.io/pypi/v/wtcraft.svg?logo=pypi&maxAge=300)](https://pypi.org/project/wtcraft/)
[![CI](https://github.com/zywkloo/wtcraft/actions/workflows/ci.yml/badge.svg)](https://github.com/zywkloo/wtcraft/actions/workflows/ci.yml)
[![GitHub release](https://img.shields.io/github/v/release/zywkloo/wtcraft?logo=github&maxAge=300)](https://github.com/zywkloo/wtcraft/releases)
[![License](https://img.shields.io/github/license/zywkloo/wtcraft)](./LICENSE)

<p align="center">
  <img src="https://raw.githubusercontent.com/zywkloo/wtcraft/main/wtcraft-icon.PNG" alt="wtcraft icon" width="120" />
</p>
**$200/month for one AI agent?**

No.

Use cheap tiers across Claude, Codex, and Gemini — then run them like a team.

`wtcraft` coordinates multiple agents with git worktrees, task files, and clear boundaries — so one solo developer can run parallel work without depending on one premium plan.

```bash
npm install -g wtcraft
```

`wtcraft` is a lightweight, git-native harness that gets you parallel multi-agent coding without the premium-tier price tag. Claude Pro ($20) + ChatGPT Plus ($20, includes Codex CLI) + Gemini (free tier) — coordinated, beats one $200 subscription, if the handoff between agents is bounded, verifiable, and budget-aware.

**Keywords:** `Solo Dev` · `Budget-Aware` · `Agent Handoff` · `Boundaries` · `Lightweight`

The goal is simple:
- keep agent work isolated with `git worktree`
- make agent handoffs explicit with a task contract
- keep file and task boundaries easy to verify
- stay usable from CLI + any IDE

No hosted platform is required. No custom runtime is required.

## The Layered Agent Team

`wtcraft` enables you to orchestrate a highly efficient, budget-friendly multi-agent team by assigning models to specialized roles based on their speed, reasoning power, and cost:

```
             [ Human Developer ]
                      │
                      ▼ (Strategic Intent)
┌────────────────────────────────────────────┐
│   Orchestrator (Gemini 3.5 Flash)          │ ◄── Cross-Repo Integration (Coming Soon)
└─────────────────────┬──────────────────────┘
                      │ (Subtask & Context)
                      ▼
┌────────────────────────────────────────────┐
│   Planner (Claude Opus / GPT-5.5)          │ ◄── Strategic Architect
└─────────────────────┬──────────────────────┘      ▲
                      │ (Writes Task Contract)      │
                      ▼                             │
┌────────────────────────────────────────────┐      │ (Re-plan / Loopback)
│  Executor (GPT-5.3-codex / Claude Sonnet)  │ ◄── Precision Coder
└─────────────────────┬──────────────────────┘      │
                      │ (Writes Code in Sandbox)    │
                      ▼                             │
             [ Human Developer ] (Pushes, Creates PR)
                      │                             │
                      ▼                             │
┌────────────────────────────────────────────┐      │
│   Verifier (Claude Opus / Gemini Pro)      │ ◄── Agentic Review (Upcoming)
└─────────────────────┬──────────────────────┘      │
                      │                             │
                      ▼                             │
             [ Human Developer ] ───────────────────┘
             (Approve OR Retry / Re-plan)
                      │
                      │ (If Approved -> Merge)
                      ▼
┌────────────────────────────────────────────┐
│   Finisher (Gemini Flash / Claude Haiku)   │ ◄── Local Cleanup & Token Telemetry (Coming Soon)
└────────────────────────────────────────────┘
```

> [!NOTE]
> **Implementation Status**:
> - **Gemini Integration & Orchestrator Routing**: Gemini CLI integration and the Orchestrator role's routing pathways are **not wired up in the current release** (deferred as a major target for the next version, `v0.4.0`).
> - **Token Telemetry**: Token telemetry routing is **currently incomplete** and remains active on the development roadmap.

* **Orchestrator (e.g., Gemini 3.5 Flash)**: Sits at the top of the workflow. Highly tool-agentic, low-latency, and coordinates the overall project state. It focuses on environment orchestration, git logistics, verification suites, and telemetry. Core features like cross-repository worktree monitoring, automated session summarization, and active agent handoff routing are **coming soon (upcoming role integration)**.
* **Planner (e.g., Claude Opus / GPT-5.5)**: The slow, high-reasoning "architect". It reads the requirement, analyzes the code context, and designs the bounded execution contract (`.worktree-task.md`) specifying Scope, Off-limits, and Verification steps.
* **Executor (e.g., GPT-5.3-codex / Claude Sonnet)**: The precision coder. It is budget-friendly, highly focused, and operates strictly inside the isolated worktree sandbox, adhering strictly to the contract boundaries.
* **Verifier (e.g., Claude Opus / Gemini Pro)**: The quality gatekeeper. It automatically conducts code reviews, checks for style/security constraints, and runs PR-level checks. If verification fails, it can trigger a feedback loop back to the Planner or Executor.
* **Finisher (e.g., Gemini Flash / Claude Haiku)**: Performs deterministic boundary validation (`wtcraft check`), test suite verification (`wtcraft verify`), and cleans up local worktree assets after a successful merge to keep the development disk clean. Additionally, in an upcoming release (integrating with PR #12), the Finisher will aggregate and report **token telemetry** to track cost, budget, and API usage per agent model (**Coming Soon**).

This layered model prevents command and context bloat, simplifies agent prompts, and maximizes code quality while keeping token expenses extremely low.

## Why

Parallel agents are useful, but raw parallelism creates four common problems:
- unclear handoff between planner and executor agents
- context pollution across tasks
- file ownership collisions
- review overload from too many noisy PRs

`wtcraft` focuses on handoff, boundaries, and budget-aware sequencing, not maximum concurrency.

For the design story and engineering philosophy behind this project, read the **TokenChef Series**:
- [Chief Token Orchestrator (Part 2): Manage Claude, Codex, and Gemini as a Structured Software Team](https://zywkloo.github.io/blog/chief-token-orchestrator-manage-layered-agent-team/)
- [wtcraft (Part 3): A Lightweight, Git-Native Scaffolding for Bounded Multi-Agent Coding](https://zywkloo.github.io/blog/wtcraft-lightweight-git-native-multi-agent-scaffolding/)

## Core Model

1. Planner defines a bounded task contract.
2. Executor works only inside that contract.
3. Verifier checks scope, off-limits, and completion gates.
4. Finisher handles push/PR/cleanup.

This supports a DAG workflow:
- merge shared foundation tasks first
- run file-disjoint tasks in parallel
- serialize tasks that touch shared files

## Project Status

Early public bootstrap.

Current scope:
- open documentation for workflow and roadmap
- starter contract and command specs
- CLI MVP available (`init`, `status`, `check`)

## Requirements

| Dependency | Required | Notes |
|---|---|---|
| bash | yes | macOS / Linux native; Windows requires [Git for Windows](https://git-scm.com/download/win) (includes Git Bash) |
| git | yes | worktree support (git ≥ 2.5) |
| Claude + Codex access | yes (for full workflow) | both are expected for planner/finisher + executor roles; either CLI or App usage is acceptable |
| Package manager (npm / pipx\|pip / Homebrew) | yes (choose one) | use at least one installation path |

For the full multi-agent workflow in this repo, both Claude and Codex are expected.
You can use their CLI variants or app-based workflows, but the role split assumes both tools are available.

## Install

**npm (global):**

```bash
npm install -g wtcraft
```

**pip / pipx:**

```bash
pipx install wtcraft        # recommended — isolated venv, no conflicts
# or
pip install --user wtcraft
```

**Homebrew (tap):**

```bash
brew tap zywkloo/wtcraft https://github.com/zywkloo/wtcraft
brew install wtcraft
```

**From source (no package manager needed):**

```bash
git clone https://github.com/zywkloo/wtcraft.git
chmod +x wtcraft/scripts/wtcraft
# add wtcraft/scripts to PATH, or run directly:
wtcraft/scripts/wtcraft init
```

## Quick Start

```bash
wtcraft init                            # scaffold harness into current repo
wtcraft init --patch-agent-files        # also append routing stubs to CLAUDE.md / AGENTS.md
wtcraft patch                           # explicit alias for: init --patch-agent-files
wtcraft unpatch                         # remove the routing stubs from CLAUDE.md / AGENTS.md
wtcraft new feat/my-task                # create worktree + task contract
wtcraft status                          # list active worktree contracts
wtcraft check <worktree-name-or-path>   # verify Scope / Off-limits
wtcraft verify <worktree-name-or-path>  # run Verification commands
wtcraft help [command]                  # per-command usage
```

### Commands

| Command | Arguments | What it does |
|---|---|---|
| `wtcraft init` | `[--patch-agent-files]` | Scaffold harness files into the current git repo. With `--patch-agent-files`, also appends managed routing stubs to `CLAUDE.md` and `AGENTS.md`. Never overwrites existing files. |
| `wtcraft patch` | — | Explicit alias for `init --patch-agent-files`: scaffold harness files and append the managed routing stub to `CLAUDE.md` / `AGENTS.md`. Idempotent and append-only. |
| `wtcraft unpatch` | — | Remove the managed routing stub (added by `patch`) from `CLAUDE.md` / `AGENTS.md`. Only the marked block is removed; other content and scaffolded files are left untouched. |
| `wtcraft new` | `<type/name>` | Create a worktree and seed its local `.worktree-task.md` contract. The task contract is excluded from git in that worktree. Base branch defaults to `develop` (override with `WTCRAFT_BASE_BRANCH`). |
| `wtcraft status` | — | List active worktree task files and their frontmatter (path, status, agent, priority). |
| `wtcraft check` | `<worktree-path-or-name>` | Verify the worktree's changes stay within the contract's Scope / Off-limits boundaries. |
| `wtcraft verify` | `<worktree-path-or-name>` | Run the Verification commands declared in the worktree's task contract. |
| `wtcraft help` | `[command]` | Show top-level usage, or detailed usage for a specific command. |

What `init` scaffolds:
- `.agent-harness/planner.md`
- `.agent-harness/executor.md`
- `.agent-harness/finisher.md`
- `.claude/commands/planwt.md` → becomes the `/planwt` slash command in Claude Code
- `.claude/commands/finishwt.md` → becomes the `/finishwt` slash command in Claude Code
- `.claude/commands/statuswt.md` → becomes the `/statuswt` slash command in Claude Code

`init` is non-destructive: existing files are not overwritten.
By default `init` does not modify `CLAUDE.md` or `AGENTS.md`.
Use `--patch-agent-files` (or the `wtcraft patch` alias) to append managed routing stubs. If `CLAUDE.md` or `AGENTS.md` do not exist, wtcraft will create them with a managed stub. Reverse it with `wtcraft unpatch`, which removes only the marked wtcraft block and leaves the rest of each file intact.

### Claude Code slash commands

After running `wtcraft init`, restart Claude Code to load the new commands:

| Command | What it does |
|---|---|
| `/planwt <task description>` | Reads `.agent-harness/planner.md`, writes a bounded task contract, and runs `wtcraft new <branch>` |
| `/finishwt <worktree-name>` | Reads `.agent-harness/finisher.md`, runs verification, checks boundaries, and reports results |
| `/statuswt` | Reads `.agent-harness/` context and reports the status of all active worktree task files |

**Typical workflow:**

```
/planwt add oauth login flow        # 1. plan task + create worktree
# agent works inside the worktree
wtcraft check feat/oauth-login      # 2. verify Scope / Off-limits
/finishwt feat/oauth-login          # 3. run verification and finish
```

`new` defaults to base branch `develop`. Set `WTCRAFT_BASE_BRANCH=main` (or another branch) when needed.

## Prior Art and References

The term **harness engineering** was defined by [Martin Fowler](https://martinfowler.com/articles/harness-engineering.html) as the infrastructure and orchestration layer that wraps a coding agent — tooling, state management, error recovery, and boundary enforcement. `wtcraft` is a solo-developer implementation of that concept.

Production-scale validation:

| Source | Scale | Key insight |
|---|---|---|
| [Fowler — "Harness engineering for coding agent users"](https://martinfowler.com/articles/harness-engineering.html) | Conceptual definition | Harness = the layer between human intent and model execution |
| [OpenAI — "Harness engineering: leveraging Codex in an agent-first world"](https://openai.com/index/harness-engineering/) | 1M+ lines, 1,500+ PRs / 5 months | Context engineering + architectural constraints + entropy management |
| [Stripe — "Minions: one-shot, end-to-end coding agents"](https://stripe.dev/blog/minions-stripes-one-shot-end-to-end-coding-agents) | 1,300+ AI PRs / week | Deterministic [D] + agentic [A] step tagging; 2-round CI cap |

Fowler describes *what* harness engineering is. Stripe and OpenAI describe *how* it works at enterprise scale. `wtcraft` brings the same pattern to a solo developer with a limited budget.

## Docs

- [Roadmap](./docs/roadmap.md)
- [Principles](./docs/principles.md)
- [Migration Notes](./docs/migration.md)
- [Changelog](./CHANGELOG.md)

## Testing

```bash
chmod +x tests/smoke.sh
tests/smoke.sh
```

## License

Apache-2.0. See [LICENSE](./LICENSE).
