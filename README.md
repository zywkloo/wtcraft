# wtcraft

> **Zero-trust containment and governance for AI-generated code.**
> Provide a definitive safety harness for agentic coding. Let your AI write code; `wtcraft` ensures it strictly obeys file boundaries, verification rules, and **token budgets** before it ever touches your main branch.

[![npm version](https://img.shields.io/npm/v/wtcraft.svg?logo=npm&maxAge=300)](https://www.npmjs.com/package/wtcraft)
[![PyPI version](https://img.shields.io/pypi/v/wtcraft.svg?logo=pypi&maxAge=300)](https://pypi.org/project/wtcraft/)
[![CI](https://github.com/zywkloo/wtcraft/actions/workflows/ci.yml/badge.svg)](https://github.com/zywkloo/wtcraft/actions/workflows/ci.yml)
[![GitHub release](https://img.shields.io/github/v/release/zywkloo/wtcraft?logo=github&maxAge=300)](https://github.com/zywkloo/wtcraft/releases)
[![License](https://img.shields.io/github/license/zywkloo/wtcraft)](./LICENSE)

<p align="center">
  <img src="https://raw.githubusercontent.com/zywkloo/wtcraft/main/wtcraft-icon.PNG" alt="wtcraft icon" width="120" />
</p>

## Install

```bash
pipx install wtcraft       # pip / pipx (recommended — isolated venv)
npm install -g wtcraft     # npm (global)
brew tap zywkloo/wtcraft https://github.com/zywkloo/wtcraft && brew install wtcraft
```

## Quick Start

```bash
wtcraft init                            # scaffold harness into current repo
wtcraft patch                           # append routing stubs to CLAUDE.md / AGENTS.md
wtcraft lang install --lang zh-CN       # enforce output language in CLAUDE.md
wtcraft new feat/my-task                # create worktree + task contract
wtcraft status                          # list active worktree contracts
wtcraft check <worktree-name-or-path>   # verify Scope / Off-limits
wtcraft verify <worktree-name-or-path>  # run Verification commands
```

After running `wtcraft init`, you can use these slash commands in Claude Code:
- `/planwt <task description>`: Plan task + create worktree
- `/finishwt <worktree-name>`: Run verification and finish
- `/statuswt`: List active worktree task files

## The Layered Agent Team


<!-- wtcraft:models:start -->
* **Orchestrator (e.g., Gemini 3.5 Flash)**: Sits at the top of the workflow. Highly tool-agentic, low-latency, and coordinates the overall project state. It focuses on environment orchestration, git logistics, verification suites, and telemetry. Core features like cross-repository worktree monitoring, automated session summarization, and active agent handoff routing are **coming soon (upcoming role integration)**.

* **Planner (e.g., Claude Opus 4.8)**: The slow, high-reasoning "architect". It reads the requirement, analyzes the code context, and designs the bounded execution contract (`.worktree-task.md`) specifying Scope, Off-limits, and Verification steps.

* **Executor (e.g., GPT-5.4)**: The precision coder. It is budget-friendly, highly focused, and operates strictly inside the isolated worktree sandbox, adhering strictly to the contract boundaries.

* **Verifier (e.g., Claude Opus Fable 5)**: The quality gatekeeper. It automatically conducts code reviews, checks for style/security constraints, and runs PR-level checks. If verification fails, it can trigger a feedback loop back to the Planner or Executor.

* **Finisher (e.g., Gemini Flash 3.5)**: Performs deterministic boundary validation (`wtcraft check`), test suite verification (`wtcraft verify`), and cleans up local worktree assets after a successful merge to keep the development disk clean. Additionally, in an upcoming release (integrating with PR #12), the Finisher will aggregate and report **token telemetry** to track cost, budget, and API usage per agent model (**Coming Soon**).
<!-- wtcraft:models:end -->

## Commands

| Command | Arguments | What it does |
|---|---|---|
| `wtcraft init` | `[--patch-agent-files]` | Scaffold harness files. Does not overwrite. |
| `wtcraft patch` | — | Alias for `init --patch-agent-files`. Appends routing stubs to `CLAUDE.md` / `AGENTS.md`. |
| `wtcraft unpatch` | — | Remove the routing stub from `CLAUDE.md` / `AGENTS.md`. |
| `wtcraft lang` | `install\|remove` | Add or remove language enforcement rules (e.g. `install --lang zh-CN`). |
| `wtcraft new` | `<type/name>` | Create a worktree and local `.worktree-task.md` contract. |
| `wtcraft status` | — | List active worktree tasks and their status. |
| `wtcraft check` | `<worktree-path-or-name>` | Verify the worktree's changes stay within Scope / Off-limits boundaries. |
| `wtcraft verify` | `<worktree-path-or-name>` | Run the Verification commands declared in the worktree's contract. |
| `wtcraft help` | `[command]` | Show usage. |

## Why

AI agents (and human contributors) hallucinate, over-engineer, and accidentally break unrelated code. While parallel agents are useful, raw parallelism creates common problems: unclear handoffs, context pollution, and file collisions.

`wtcraft` provides a definitive safety harness. It focuses on handoff, boundaries, and deterministic containment, not just concurrency. 

- **Git-Native Containment:** Keep agent work physically isolated with `git worktree`.
- **Task Contracts:** Make agent handoffs explicit with a per-task whitelist in `.worktree-task.md`.
- **Deterministic Gating:** Enforce scope boundaries at the commit/PR level. If a task isn't in scope, the code doesn't merge.
- **Budget-Aware:** Avoid infinite LLM loops and track API usage per worktree.

No hosted platform is required. No custom runtime is required. You can use Aider, Cursor, Claude, or Devin — `wtcraft` simply wraps your working directory in a zero-trust governance layer.

## Docs

- [Roadmap](./docs/roadmap.md)
- [Gotchas & Coding Survival Guide](./docs/gotchas/README.md)
- [Principles](./docs/principles.md)
- [Migration Notes](./docs/migration.md)
- [Changelog](./CHANGELOG.md)

## Testing

```bash
bash tests/run_all.sh
```

## License

Apache-2.0. See [LICENSE](./LICENSE).
