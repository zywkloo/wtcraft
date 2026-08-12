#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/framework.sh"

tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

test_agent_init_without_git() {
  local project="${tmp_root}/plain-project"
  mkdir -p "$project"

  (
    cd "$project"
    "$CLI" agent init

    test ! -e .git
    grep -qxF '# Project Instructions' AGENTS.md
    grep -qxF '@AGENTS.md' CLAUDE.md

    cp AGENTS.md AGENTS.before
    cp CLAUDE.md CLAUDE.before
    "$CLI" agent init
    diff AGENTS.before AGENTS.md
    diff CLAUDE.before CLAUDE.md
  )
}

test_agent_init_preserves_existing_content() {
  local project="${tmp_root}/existing-project"
  mkdir -p "$project"
  printf '# Existing agent rules\n\nUse pnpm.\n' >"${project}/AGENTS.md"
  printf '# Claude-specific notes\n' >"${project}/CLAUDE.md"
  cp "${project}/AGENTS.md" "${project}/AGENTS.before"

  "$CLI" agent init --path "$project"
  "$CLI" agent init --path "$project"

  diff "${project}/AGENTS.before" "${project}/AGENTS.md"
  grep -qF '# Claude-specific notes' "${project}/CLAUDE.md"
  test "$(grep -cF '@AGENTS.md' "${project}/CLAUDE.md")" -eq 1
}

test_agent_init_accepts_existing_relative_import() {
  local project="${tmp_root}/relative-import-project"
  mkdir -p "$project"
  printf '# Existing agent rules\n' >"${project}/AGENTS.md"
  printf '@./AGENTS.md\n' >"${project}/CLAUDE.md"

  "$CLI" agent init --path "$project"

  test "$(grep -cF 'AGENTS.md' "${project}/CLAUDE.md")" -eq 1
}

test_file_only_commands_without_git() {
  local project="${tmp_root}/file-only-project"
  mkdir -p "$project"

  (
    cd "$project"
    "$CLI" init >/dev/null
    test ! -e .git
    test -f .agent-harness/planner.md

    "$CLI" patch >/dev/null
    test -f AGENTS.md
    test -f CLAUDE.md

    "$CLI" lang install --lang zh-CN >/dev/null
    grep -qF '<!-- wtcraft:lang:start -->' AGENTS.md

    "$CLI" unpatch >/dev/null
    ! grep -qF '<!-- wtcraft:agents:start -->' AGENTS.md

    "$CLI" migrate --yes >/dev/null
  )
}

test_local_mode_still_requires_git_without_partial_scaffold() {
  local project="${tmp_root}/local-mode-project"
  mkdir -p "$project"

  ! "$CLI" init --local --repo "$project" >/dev/null 2>&1
  test ! -e "${project}/.agent-harness"
  test ! -e "${project}/.claude"
}

test_agent_init_without_git
test_agent_init_preserves_existing_content
test_agent_init_accepts_existing_relative_import
test_file_only_commands_without_git
test_local_mode_still_requires_git_without_partial_scaffold

echo "[PASS] e2e_agent"
