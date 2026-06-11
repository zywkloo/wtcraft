#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/framework.sh"

test_help_init_status() {
  local repo="$1"
  cd "$repo"
  "$CLI" --help
  "$CLI" init
  "$CLI" status
  test ! -e .worktree-task.template.md
  test -f .agent-harness/presets/preset-anthropic.yml
  test -f .agent-harness/presets/preset-balanced.yml
  test -f .agent-harness/presets/preset-openai.yml
  test -f .agent-harness/presets/preset-google.yml
}

test_patch_agent_files_idempotent() {
  local repo="$1"
  cd "$repo"
  printf "# local claude\n" > CLAUDE.md
  printf "# local agents\n" > AGENTS.md

  "$CLI" init --patch-agent-files
  "$CLI" init --patch-agent-files

  grep -q "<!-- wtcraft:claude:start -->" CLAUDE.md
  grep -q "<!-- wtcraft:claude:end -->" CLAUDE.md
  grep -q "<!-- wtcraft:agents:start -->" AGENTS.md
  grep -q "<!-- wtcraft:agents:end -->" AGENTS.md

  test "$(grep -c 'wtcraft:claude:start' CLAUDE.md)" -eq 1
  test "$(grep -c 'wtcraft:agents:start' AGENTS.md)" -eq 1
}

test_patch_unpatch_roundtrip() {
  local repo="$1"
  cd "$repo"
  printf '# My Project\n\nSome existing notes.\n' > CLAUDE.md
  printf '# Agents\n\nExisting agent guidance.\n' > AGENTS.md
  cp CLAUDE.md CLAUDE.orig
  cp AGENTS.md AGENTS.orig

  # `patch` is an explicit alias for `init --patch-agent-files`
  "$CLI" patch
  grep -q "<!-- wtcraft:claude:start -->" CLAUDE.md
  grep -q "<!-- wtcraft:agents:start -->" AGENTS.md

  # `unpatch` restores the files byte-for-byte (block + separator removed)
  "$CLI" unpatch
  ! grep -q "wtcraft:claude" CLAUDE.md
  ! grep -q "wtcraft:agents" AGENTS.md
  diff CLAUDE.orig CLAUDE.md
  diff AGENTS.orig AGENTS.md

  # unpatch is idempotent and a no-op when no stub is present
  "$CLI" unpatch
  diff CLAUDE.orig CLAUDE.md

  # patch/unpatch reject extra arguments
  ! "$CLI" patch extra 2>/dev/null
  ! "$CLI" unpatch extra 2>/dev/null
}

run_in_temp_repo test_help_init_status
run_in_temp_repo test_patch_agent_files_idempotent
run_in_temp_repo test_patch_unpatch_roundtrip

echo "[PASS] e2e_init_patch"
