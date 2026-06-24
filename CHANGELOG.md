# Changelog

All notable changes to wtcraft are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.3] - 2026-06-24

### Fixed
- `wtcraft lang install` crashed on macOS bash 3.2 (`remaining[@]: unbound variable`) when no extra arguments were passed, due to empty-array expansion under `set -u`; fixed with the bash-3.2-safe expansion idiom (#38).
- Test suite used the bash-4-only `mapfile` builtin, which prevented `tests/run_all.sh` from running at all on macOS bash 3.2; replaced with a portable `while read` loop (#38).
- Added `.agent-harness/llm-anti-patterns.md`, which the `CLAUDE.md` routing stub referenced (`read .agent-harness/llm-anti-patterns.md`) but was never committed, leaving a dangling reference after `wtcraft init` (#39).

### Changed
- `wtcraft lang install` / `lang remove` now mirror the language-enforcement block into `AGENTS.md` (not just `CLAUDE.md`) when that file exists, matching how `patch` / `unpatch` treat agent files. Only existing agent files are patched — never created; if neither `CLAUDE.md` nor `AGENTS.md` exists, the command exits non-zero and points the user at `wtcraft patch` (#38).

### Added
- `tests/e2e_lang.sh` regression coverage for `lang install` / `lang remove` across all four cases: CLAUDE.md-only, AGENTS.md-only, both, and neither (#38).

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
