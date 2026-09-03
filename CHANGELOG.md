# Changelog

All notable changes to wtcraft are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `wtcraft init-ci` installs the trusted-change-authorization check into a
  repository: the `pull_request_target` workflow plus the evaluator it runs, at
  `.wtcraft/policy_git_adapter.py` and `.wtcraft/policy_evaluator.py`. The
  evaluator is vendored rather than installed at check time, because the job is
  privileged and runs from the trusted base checkout. Installing the check does
  not enforce it; the command prints the repository-administration steps that
  do, and states that a passing verdict says nothing about whether tests passed.
- `init-ci` reports a vendored file that differs from the installed wtcraft
  version instead of silently leaving it, and `--force` refreshes it. A stale
  vendored evaluator keeps bugs a newer wtcraft has fixed, including the
  off-limits rename bypass.
- `docs/adr/012-evaluation-evidence-boundary.md` records that trusted evidence
  carries Git and policy facts only. A proposed "Phase 6.5 evaluation evidence
  contract" is rejected on two grounds: it repeats the no-consumer-no-format
  anti-pattern ADR-010 already settled, and its `migration type` / `risk tier`
  fields are evaluator judgements rather than facts a third party can recompute,
  so placing them in evidence would pull semantic judgement into the trusted
  core the threat model excludes.
- `docs/adr/011-verification-execution-least-privilege.md` records why the
  reviewed verification plan is still not executed: sandboxing cannot make a
  command the adversary wrote report truthfully, so execution is only evidence
  once the reviewed policy pins the plan's inputs.

### Fixed
- npm packages no longer ship `__pycache__` directories. The `files` field
  includes listed directories wholesale, so the compiled-bytecode caches needed
  an explicit negation.

### Changed
- `capabilities --json` reports `init-ci`. Additive within protocol v1.

## [0.4.4] - 2026-08-12

### Added
- `wtcraft agent init` initializes `AGENTS.md` as the canonical shared
  instruction file and makes `CLAUDE.md` import it with `@AGENTS.md`. The
  command is idempotent, preserves existing content, and works without Git.

### Changed
- File-only project setup and maintenance commands no longer require a Git
  repository. `init`, `patch`, `unpatch`, `lang`, and `migrate` can operate in
  a plain directory; `init --local` still requires Git because it writes
  `.git/info/exclude`.

### Fixed
- `wtcraft new` now reports a repository with no commits in its own terms and
  names the fix, instead of letting git's `fatal: invalid reference` surface.
  Because `agent init` works without a repository, running `new` right after a
  fresh `git init` is an ordinary path rather than a corner case.

## [0.4.3] - 2026-06-24

### Fixed
- `wtcraft lang install` crashed on macOS bash 3.2 (`remaining[@]: unbound variable`) when no extra arguments were passed, due to empty-array expansion under `set -u`; fixed with the bash-3.2-safe expansion idiom (#38).
- Test suite used the bash-4-only `mapfile` builtin, which prevented `tests/run_all.sh` from running at all on macOS bash 3.2; replaced with a portable `while read` loop (#38).
- Added `.agent-harness/llm-anti-patterns.md`, which the `CLAUDE.md` routing stub referenced (`read .agent-harness/llm-anti-patterns.md`) but was never committed, leaving a dangling reference after `wtcraft init` (#39).

### Changed
- `wtcraft lang install` / `lang remove` now mirror the language-enforcement block into `AGENTS.md` (not just `CLAUDE.md`) when that file exists, matching how `patch` / `unpatch` treat agent files. Only existing agent files are patched — never created; if neither `CLAUDE.md` nor `AGENTS.md` exists, the command exits non-zero and points the user at `wtcraft patch` (#38).

### Added
- `tests/e2e_lang.sh` regression coverage for `lang install` / `lang remove` across all four cases: CLAUDE.md-only, AGENTS.md-only, both, and neither (#38).

## [0.4.2] - 2026-06-13

### Added
- `wtcraft doctor` — diagnoses the install and scaffold: CLI path/version, other-wtcraft-on-PATH shadow detection, scaffold completeness, and legacy-file detection (#31).
- `wtcraft migrate [--yes]` — fills missing scaffold files and removes known legacy files (#31).
- `wtcraft status --json` plus machine protocol v1 — layout-agnostic worktree enumeration exposing `stage` / `role`, as a machine interface for observers.
- `wtcraft --version` command; local init mode and the `wtc` short alias.
- Stage state-machine convention: `task-states.md` and `stage:` / `role:` task-contract fields.

### Fixed
- Reliable version resolution — installers stamp `WTCRAFT_VERSION` so `--version` survives brew/pip installs instead of printing `unknown`; `__version__` now derives from package metadata; `scripts/bump-version.sh` single-sources the three build manifests (#36).
- Hardened machine-protocol edge cases (JSON escaping, unusual worktree paths).

## [0.4.1] - 2026-06-11

### Changed
- Maintenance republish (version bump only) following `0.4.0`.

## [0.4.0] - 2026-06-11

### Added
- LLM anti-patterns guide (`.agent-harness/llm-anti-patterns.md`) and `wtcraft lang` language-enforcement patching.
- role-models v2 — structured `role-models.yml` schema with preset codegen (`presets/`) for model selection.
- Layered test suite: awk unit tests for the markdown parsers and preset-init assertions.

### Changed
- Governance pivot: README and tagline reframed around repo/worktree governance and token budget.
- `check` now covers uncommitted/untracked files; `verify` writes its result into the task-contract frontmatter; `status` gains a Verified column.
- `finisher` adds a re-plan checkpoint to challenge task premises before push/PR.

### Fixed
- Restored task-contract violation detection in `check`.
- Keep worktree task contracts local; stopped mutating `.git/info/exclude`.

## [0.3.9] - 2026-06-03

### Changed
- Maintenance release (version and Homebrew formula bump only).

## [0.3.8] - 2026-05-31

### Added
- Release guardrails in `CLAUDE.md` and `AGENTS.md`: version tags must use `v<semver>` and be created from `main` only.

### Changed
- Bumped package versions to `0.3.8` for npm and PyPI republish after immutable `0.3.7` artifacts were already published.

## [0.3.7] - 2026-05-31

### Added
- `wtcraft patch` command as explicit alias of `wtcraft init --patch-agent-files`.
- `wtcraft unpatch` command to remove only wtcraft-managed routing stubs from `CLAUDE.md` and `AGENTS.md`.
- Smoke test coverage for patch/unpatch roundtrip, idempotency, and argument validation.

### Changed
- Integration test now treats pip package install as `SKIP` in offline/network-restricted environments while preserving hard failures for non-network errors.
- README command reference now includes all commands (`patch`, `unpatch`, and `statuswt` slash command docs alignment).

## [0.3.6] - 2026-05-29

### Added
- Gemini CLI support in executor guidelines, with `GEMINI.md` patch integration.
- `/planwt` upgraded to a full orchestrator (one-shot plan + worktree creation).
- `statuswt` slash command; automated GitHub Release creation on `v*` tag push.

### Changed
- Eliminated the duplicate shell script and templates via symlinks (#15).
- README: "Cheap Token Orchestrator (CTO)" tagline, architecture/stack docs, and a Layered Agent Team diagram with Human-in-the-Loop.

## [0.3.5] - 2026-05-27

### Added
- Self-bootstrapped `wtcraft` routing and harness files to the repository (dogfooding).
- Dedicated architectural guide on Multi-Agent Handoff and future plans for triggers/automations (`docs/handoff-automation.md`).
- Conditional execution for CI integration tests to run only on push to `main` branch, optimizing PR build speed.

### Fixed
- Added Windows platform support via Git Bash detection (`shutil.which("bash")`).
- Added symlink resolution in the shell wrapper to support global npm/Homebrew installations.
- Fixed missing `contents: read` permissions in NPM publishing workflow to enable OIDC provenance.
- Simplified and optimized NPM/PyPI keywords with high-frequency, un-compounded search terms (e.g., `agent`, `ai`, `llm`, `token`).

## [0.3.4] - 2026-05-27

### Changed
- Bump package version to `0.3.4` for npm and PyPI release tagging

## [0.3.3] - 2026-05-27

### Fixed
- Correct author email to zywkloo@icloud.com

## [0.3.2] - 2026-05-27

### Changed
- `pyproject.toml`: add authors, classifiers, and full project URLs for PyPI sidebar

## [0.3.1] - 2026-05-27

### Fixed
- `pyproject.toml`: use `setuptools.build_meta` backend (legacy path unavailable in CI)
- `package.json`: remove leading `./` from npm bin path
- `publish.yml`: add `workflow_dispatch` trigger for manual PyPI releases
- `publish-npm.yml`: automated npm publishing via OIDC trusted publisher

## [0.3.0] - 2026-05-26

### Added
- `wtcraft help [command]` — per-command usage with pattern docs and exit codes
- Glob pattern matching in `wtcraft check` scope/off-limits items:
  `*.md`, `src/*.ts`, `src/**/*.ts` all resolve correctly
- Richer `wtcraft verify` output: per-command separator, timing, exit code,
  and a structured summary table
- `package.json` for npm distribution (`npm install -g wtcraft`)
- `pyproject.toml` + `src/wtcraft/` for pip/pipx distribution
- `Formula/wtcraft.rb` Homebrew formula (tap: `zywkloo/wtcraft`)
- Executor model-selection guide + Codex CLI fallback note in `executor.md`
- `WTCRAFT_TEMPLATE_DIR` env var: overrides template location for pip/Homebrew installs

### Changed
- `cmd_check` now delegates path matching to `file_matches_scope_item()`,
  which falls back to bash glob matching when the pattern contains `*`

## [0.2.0]

### Added
- `wtcraft new <type/name>`: create worktree from base branch + seed task contract
- `wtcraft verify <worktree>`: run verification commands from task contract
- Cleaner section parser for frontmatter and Scope/Verification extraction
- Smoke test suite (`tests/smoke.sh`)
- Role-split docs: planner, executor, finisher
- Optional routing-stub injection for `CLAUDE.md` / `AGENTS.md`
  (opt-in via `--patch-agent-files`; append-only, never overwrites)
- CI checks: shellcheck lint + smoke tests on push

## [0.1.0]

### Added
- `wtcraft init`: scaffold harness files into a target repo
- `wtcraft status`: list active worktree task files and statuses
- `wtcraft check <worktree>`: compare changed files against Scope and Off-limits
- `.agent-harness/` starter docs and templates (planner, executor, finisher)
- Initial public repository and vision docs

[Unreleased]: https://github.com/zywkloo/wtcraft/compare/v0.3.8...HEAD
[0.3.8]: https://github.com/zywkloo/wtcraft/compare/v0.3.7...v0.3.8
[0.3.7]: https://github.com/zywkloo/wtcraft/compare/v0.3.5...v0.3.7
[0.3.5]: https://github.com/zywkloo/wtcraft/compare/v0.3.4...v0.3.5
[0.3.4]: https://github.com/zywkloo/wtcraft/compare/v0.3.3...v0.3.4
[0.3.3]: https://github.com/zywkloo/wtcraft/compare/v0.3.2...v0.3.3
[0.3.2]: https://github.com/zywkloo/wtcraft/compare/v0.3.1...v0.3.2
[0.3.1]: https://github.com/zywkloo/wtcraft/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/zywkloo/wtcraft/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/zywkloo/wtcraft/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/zywkloo/wtcraft/releases/tag/v0.1.0
