#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CLI="${REPO_ROOT}/scripts/wtcraft"

run_in_temp_repo() {
  local fn_name="$1"
  local tmpdir
  tmpdir="$(mktemp -d)"
  (
    cd "$tmpdir"
    git init -q
    "$fn_name" "$tmpdir"
  )
  rm -rf "$tmpdir"
}

test_help_init_status() {
  local repo="$1"
  cd "$repo"
  "$CLI" --help
  "$CLI" init
  "$CLI" status
  test ! -e .worktree-task.template.md
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

test_new_verify_check() {
  local repo="$1"
  cd "$repo"
  git config user.name "wtcraft-smoke"
  git config user.email "wtcraft-smoke@example.com"
  echo "seed" > .wtcraft-seed
  git add .wtcraft-seed
  git commit -q -m "seed"

  local current_branch
  current_branch="$(git branch --show-current)"

  "$CLI" init
  git add -A && git commit -q -m "wtcraft init"
  WTCRAFT_BASE_BRANCH="$current_branch" "$CLI" new chore/smoke

  local task_file="${repo}/worktrees/chore/smoke/.worktree-task.md"
  sed -i.bak "s|pnpm tsc --noEmit|echo ok|" "$task_file"
  rm -f "${task_file}.bak"
  git -C worktrees/chore/smoke check-ignore -q .worktree-task.md
  test -z "$(git -C worktrees/chore/smoke status --short -- .worktree-task.md)"

  "$CLI" verify chore/smoke
  "$CLI" check chore/smoke
}

test_check_rejects_task_contract_changes() {
  local repo="$1"
  cd "$repo"
  git config user.name "wtcraft-smoke"
  git config user.email "wtcraft-smoke@example.com"
  echo "seed" > .wtcraft-seed
  git add .wtcraft-seed
  git commit -q -m "seed"

  local current_branch
  current_branch="$(git branch --show-current)"

  "$CLI" init
  git add -A && git commit -q -m "wtcraft init"
  WTCRAFT_BASE_BRANCH="$current_branch" "$CLI" new chore/task-contract

  (
    cd worktrees/chore/task-contract
    git add -f .worktree-task.md
    git commit -q -m "accidentally commit task contract"
  )

  ! "$CLI" check chore/task-contract 2>/dev/null
}

run_in_temp_repo test_help_init_status
run_in_temp_repo test_patch_agent_files_idempotent
run_in_temp_repo test_patch_unpatch_roundtrip
run_in_temp_repo test_new_verify_check
run_in_temp_repo test_check_rejects_task_contract_changes

echo "Smoke tests passed."
