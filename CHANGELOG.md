# Changelog

All notable changes to wtcraft are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
