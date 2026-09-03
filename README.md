# wtcraft

> **Git-native agent governance core.**
>
> `wtcraft` is a lightweight governance core for worktree-based agent
> workflows. It defines task contracts, tracks lifecycle state, and exposes
> deterministic scope and verification checks for CLIs, agents, and graphical
> clients.

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

Short alias available after install: `wtc`

## Quick Start

```bash
wtcraft --version                        # print the installed CLI version
wtc agent init                          # create AGENTS.md + CLAUDE.md; no Git required
wtcraft init                            # scaffold harness; no Git required
wtcraft init --local                    # scaffold locally; ignore via .git/info/exclude
wtcraft patch                           # append routing stubs to CLAUDE.md / AGENTS.md
wtcraft lang install --lang zh-CN       # enforce output language in CLAUDE.md
wtcraft new feat/my-task                # create worktree + task contract
wtcraft new --base origin/main feat/x   # override the base branch/ref explicitly
wtcraft status                          # list active worktree contracts
wtcraft capabilities --json             # discover machine-protocol features
wtcraft status --json --repo /repo      # machine-readable status for a target repo
wtcraft check <worktree-name-or-path>   # verify Scope / Off-limits
wtcraft verify <worktree-name-or-path>  # run Verification commands
```

`wtcraft new` resolves its base in this order: `--base`, then
`WTCRAFT_BASE_BRANCH`, then `origin/HEAD`, then local `main`, local `master`,
local `develop`, and finally the current branch.

After running `wtcraft init`, you can use these slash commands in Claude Code:
- `/planwt <task description>`: Plan task + create worktree
- `/finishwt <worktree-name>`: Run verification and finish
- `/statuswt`: List active worktree task files

## Suggested Workflow Roles

These roles and the models in `role-models.yml` are editable workflow guidance.
The current CLI does not launch agents, route models, enforce role handoffs, or
run token telemetry.


<!-- wtcraft:models:start -->
* **Orchestrator (e.g., Gemini 3.6 Flash)**: An optional coordination profile for environment and Git logistics. `wtcraft` does not launch, route, or monitor this role.

* **Planner (e.g., Claude Opus 5)**: A suggested planning profile that writes the local task contract (`.worktree-task.md`) with Scope, Off-limits, and Verification sections.

* **Executor (e.g., GPT-5.5)**: A suggested implementation profile working in a dedicated Git worktree. `wtcraft check` detects out-of-scope changes when invoked; it does not sandbox the agent runtime.

* **Verifier (e.g., Claude Opus 5)**: A human or agent review profile that can consume `check --json` and `verify --json`. `wtcraft` does not automatically run a review agent or a PR gate.

* **Finisher (e.g., Gemini Flash 3.6)**: A suggested workflow profile that runs `wtcraft check` and `wtcraft verify`, then performs the repository's normal handoff and cleanup steps. Token telemetry is not implemented.
<!-- wtcraft:models:end -->

## Commands

| Command | Arguments | What it does |
|---|---|---|
| `wtcraft agent init` | `[--path <path>]` | Create or preserve canonical `AGENTS.md` instructions and make `CLAUDE.md` import them. Does not require Git. |
| `wtcraft init` | `[--patch-agent-files] [--local] [--repo <path>]` | Scaffold harness files without requiring Git. Does not overwrite. `--local` requires Git because it uses `.git/info/exclude`. |
| `wtcraft init-ci` | `[--repo <path>] [--force]` | Install the trusted-change-authorization check and the evaluator it runs. Installing it does not enforce it; the command prints the repository-administration steps that do. |
| `wtcraft patch` | `[--repo <path>]` | Alias for `init --patch-agent-files`. Appends routing stubs to `CLAUDE.md` / `AGENTS.md`. |
| `wtcraft unpatch` | `[--repo <path>]` | Remove the routing stub from `CLAUDE.md` / `AGENTS.md`. |
| `wtcraft lang` | `install\|remove [--repo <path>]` | Add or remove language enforcement rules (e.g. `install --lang zh-CN`). |
| `wtcraft new` | `[--repo <path>] [--base <branch>] <type/name>` | Create a worktree and local `.worktree-task.md` contract. |
| `wtcraft status` | `[--json] [--repo <path>]` | List active worktree tasks and their status. `--json` is the machine-readable status surface. |
| `wtcraft check` | `[--json] [--repo <path>] <worktree-path-or-name>` | Verify the worktree's changes stay within Scope / Off-limits boundaries. |
| `wtcraft verify` | `[--json] [--repo <path>] <worktree-path-or-name>` | Run the Verification commands declared in the worktree's contract. |
| `wtcraft capabilities` | `--json` | Report supported machine-protocol features for external launchers. |
| `wtcraft --version` | — | Print the installed CLI version. |
| `wtcraft help` | `[command]` | Show usage. |

## Why

AI agents (and human contributors) hallucinate, over-engineer, and accidentally break unrelated code. While parallel agents are useful, raw parallelism creates common problems: unclear handoffs, context pollution, and file collisions.

`wtcraft` provides a small, inspectable verification harness. It focuses on
handoff, task boundaries, and deterministic checks rather than agent runtime
control.

- **Git-Native Task Isolation:** Keep parallel task changes separated with `git worktree`.
- **Task Contracts:** Make agent handoffs explicit with a per-task whitelist in `.worktree-task.md`.
- **Deterministic Checks:** Detect out-of-scope files and run declared verification commands on demand.
- **Machine-Readable Facts:** Expose status, scope results, and verification results as stable JSON.

No hosted platform or custom agent runtime is required. You can use Aider,
Cursor, Claude, or another coding agent because the checks operate on Git and
the worktree changeset.

The current local task contract is mutable and is not, by itself, a security
boundary. A reviewed policy envelope and protected required check are planned
for the next milestone; see the [Roadmap](./docs/roadmap.md).

## Docs

- [Protocol Contracts](./docs/protocol/README.md)
- [Rust Core Extraction ADR](./docs/adr/006-rust-core-extraction.md)
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
