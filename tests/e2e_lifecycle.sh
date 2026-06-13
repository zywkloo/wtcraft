#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/framework.sh"

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

  # verify writes its result back into the task contract frontmatter
  grep -q "^verify_result: pass" "$task_file"
  grep -q "^verified: " "$task_file"
  "$CLI" status | grep -q "pass"

  # stage/role columns come from the new contract convention
  "$CLI" status | grep -q "planned"
  "$CLI" status | grep -q "executor"

  # --json is well-formed and carries the same facts
  "$CLI" status --json | python3 -m json.tool >/dev/null
  "$CLI" status --json | grep -q '"stage":"planned"'

  # a worktree without a contract surfaces as uncontracted (any layout — this
  # one lives at an arbitrary path outside worktrees/). Kept inside the temp
  # repo so run_in_temp_repo's rm -rf reclaims it even if an assertion aborts.
  git worktree add -q "${repo}/wt-smoke-wild" -b chore/wild "$current_branch"
  "$CLI" status | grep -q "uncontracted"
  "$CLI" status --json | grep -q '"contracted":false'
  git worktree remove --force "${repo}/wt-smoke-wild"

  # a failing verification is recorded as fail
  sed -i.bak "s|echo ok|false|" "$task_file"
  rm -f "${task_file}.bak"
  ! "$CLI" verify chore/smoke
  grep -q "^verify_result: fail" "$task_file"

  # check sees untracked files: out-of-scope file fails, in-scope passes
  echo "rogue" > "${repo}/worktrees/chore/smoke/rogue.txt"
  ! "$CLI" check chore/smoke
  rm "${repo}/worktrees/chore/smoke/rogue.txt"
  mkdir -p "${repo}/worktrees/chore/smoke/src"
  echo "ok" > "${repo}/worktrees/chore/smoke/src/example.ts"
  "$CLI" check chore/smoke

  # check sees uncommitted edits to tracked files: out-of-scope edit fails
  echo "tweak" >> "${repo}/worktrees/chore/smoke/.wtcraft-seed"
  ! "$CLI" check chore/smoke
  git -C "${repo}/worktrees/chore/smoke" checkout -- .wtcraft-seed
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

run_in_temp_repo test_new_verify_check
run_in_temp_repo test_check_rejects_task_contract_changes

echo "[PASS] e2e_lifecycle"
