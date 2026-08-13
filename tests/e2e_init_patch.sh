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

test_init_local_keeps_repo_clean() {
  local repo="$1"
  cd "$repo"

  "$CLI" init --local

  test ! -f .gitignore
  grep -qxF '# wtcraft local scaffold' .git/info/exclude
  grep -qxF '/.worktree-task.md' .git/info/exclude
  grep -qxF '/.agent-harness/' .git/info/exclude
  grep -qxF '/.claude/commands/' .git/info/exclude
  grep -qxF '/AGENTS.md' .git/info/exclude
  grep -qxF '/CLAUDE.md' .git/info/exclude
  test -z "$(git status --short)"
}

test_init_local_patch_hides_agent_files() {
  local repo="$1"
  cd "$repo"

  "$CLI" init --local --patch-agent-files

  test -f CLAUDE.md
  test -f AGENTS.md
  grep -q "<!-- wtcraft:claude:start -->" CLAUDE.md
  grep -q "<!-- wtcraft:agents:start -->" AGENTS.md
  test -z "$(git status --short)"
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

test_init_local_in_linked_worktree_uses_git_info_exclude() {
  local repo="$1"
  cd "$repo"
  git config user.name "wtcraft-smoke"
  git config user.email "wtcraft-smoke@example.com"
  echo "seed" > .wtcraft-seed
  git add .wtcraft-seed
  git commit -q -m "seed"

  local current_branch
  current_branch="$(git branch --show-current)"
  WTCRAFT_BASE_BRANCH="$current_branch" "$CLI" new chore/local-init

  (
    cd worktrees/chore/local-init
    "$CLI" init --local
  )

  local exclude_file
  exclude_file="$(git -C worktrees/chore/local-init rev-parse --git-path info/exclude)"
  grep -qxF '# wtcraft local scaffold' "$exclude_file"
  grep -qxF '/.agent-harness/' "$exclude_file"
  grep -qxF '/.claude/commands/' "$exclude_file"
  test -f worktrees/chore/local-init/.agent-harness/planner.md
  test -z "$(git -C worktrees/chore/local-init status --short)"
}

test_new_reports_an_empty_repository_in_wtcraft_terms() {
  local repo="$1"
  cd "$repo"
  # `agent init` needs no repository, so users reach `new` straight after a
  # fresh `git init`, before any commit exists.
  local output
  output="$("$CLI" new chore/too-early 2>&1)" && exit 1
  case "$output" in
    *"no commits yet"*) ;;
    *) echo "expected a wtcraft-level message, got: ${output}" >&2; exit 1 ;;
  esac
}

run_in_temp_repo test_new_reports_an_empty_repository_in_wtcraft_terms

run_in_temp_repo test_help_init_status
run_in_temp_repo test_init_local_keeps_repo_clean
run_in_temp_repo test_init_local_patch_hides_agent_files
run_in_temp_repo test_patch_agent_files_idempotent
run_in_temp_repo test_patch_unpatch_roundtrip
run_in_temp_repo test_init_local_in_linked_worktree_uses_git_info_exclude

echo "[PASS] e2e_init_patch"
