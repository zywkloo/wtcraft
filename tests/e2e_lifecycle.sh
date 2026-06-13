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
  "$CLI" --version | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'
  "$CLI" capabilities --json | python3 -m json.tool >/dev/null
  "$CLI" capabilities --json | grep -q '"registry_commands"'
  WTCRAFT_BASE_BRANCH="$current_branch" "$CLI" new chore/smoke

  local task_file="${repo}/worktrees/chore/smoke/.worktree-task.md"
  sed -i.bak "s|pnpm tsc --noEmit|echo ok|" "$task_file"
  rm -f "${task_file}.bak"
  git -C worktrees/chore/smoke check-ignore -q .worktree-task.md
  test -z "$(git -C worktrees/chore/smoke status --short -- .worktree-task.md)"

  "$CLI" verify chore/smoke
  "$CLI" check chore/smoke
  "$CLI" verify --json chore/smoke | python3 -m json.tool >/dev/null
  "$CLI" verify --json chore/smoke | grep -q '"result":"pass"'
  "$CLI" check --json chore/smoke | python3 -m json.tool >/dev/null
  "$CLI" check --json chore/smoke | grep -q '"result":"pass"'

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
  (cd "${repo}/worktrees/chore/smoke" && "$CLI" status --json | grep -q '"branch":"chore/smoke"')
  (cd / && "$CLI" status --json --repo "$repo" | grep -q '"branch":"chore/smoke"')
  (cd / && "$CLI" check --json --repo "$repo" chore/smoke | grep -q '"result":"pass"')

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
  set +e
  verify_json="$("$CLI" verify --json chore/smoke 2>/dev/null)"
  verify_exit=$?
  set -e
  [ "$verify_exit" -eq 3 ]
  printf '%s' "$verify_json" | python3 -m json.tool >/dev/null
  printf '%s' "$verify_json" | grep -q '"result":"fail"'
  grep -q "^verify_result: fail" "$task_file"

  # check sees untracked files: out-of-scope file fails, in-scope passes
  echo "rogue" > "${repo}/worktrees/chore/smoke/rogue.txt"
  ! "$CLI" check chore/smoke
  set +e
  check_json="$("$CLI" check --json chore/smoke 2>/dev/null)"
  check_exit=$?
  set -e
  [ "$check_exit" -eq 2 ]
  printf '%s' "$check_json" | python3 -m json.tool >/dev/null
  printf '%s' "$check_json" | grep -q '"kind":"scope"'
  rm "${repo}/worktrees/chore/smoke/rogue.txt"

  # Machine mode preserves paths that line-delimited Git output would quote or
  # split. JSON encoding is the only representation change.
  local unusual_path=$'odd path\nline.txt'
  printf 'rogue\n' > "${repo}/worktrees/chore/smoke/${unusual_path}"
  set +e
  check_json="$("$CLI" check --json chore/smoke 2>/dev/null)"
  check_exit=$?
  set -e
  [ "$check_exit" -eq 2 ]
  CHECK_JSON="$check_json" UNUSUAL_PATH="$unusual_path" python3 - <<'PY'
import json
import os

payload = json.loads(os.environ["CHECK_JSON"])
path = os.environ["UNUSUAL_PATH"]
assert path in payload["changed_files"]
assert any(item["file"] == path for item in payload["violations"])
PY
  rm "${repo}/worktrees/chore/smoke/${unusual_path}"

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

test_new_defaults_to_master_or_main() {
  local repo="$1"
  cd "$repo"
  git config user.name "wtcraft-smoke"
  git config user.email "wtcraft-smoke@example.com"
  echo "seed" > .wtcraft-seed
  git add .wtcraft-seed
  git commit -q -m "seed"

  "$CLI" init
  git add -A && git commit -q -m "wtcraft init"

  "$CLI" new chore/default-master
  grep -q "^base: master" "${repo}/worktrees/chore/default-master/.worktree-task.md"

  git branch -m main
  "$CLI" new chore/default-main
  grep -q "^base: main" "${repo}/worktrees/chore/default-main/.worktree-task.md"
}

test_new_prefers_origin_head_and_accepts_base_override() {
  local repo="$1"
  cd "$repo"
  git config user.name "wtcraft-smoke"
  git config user.email "wtcraft-smoke@example.com"
  echo "seed" > .wtcraft-seed
  git add .wtcraft-seed
  git commit -q -m "seed"

  "$CLI" init
  git add -A && git commit -q -m "wtcraft init"

  local remote_repo
  remote_repo="$(mktemp -d)"
  git init -q --bare "$remote_repo"
  git remote add origin "$remote_repo"
  git push -q -u origin master
  git remote set-head origin master

  "$CLI" new chore/default-origin
  grep -q "^base: origin/master" "${repo}/worktrees/chore/default-origin/.worktree-task.md"

  "$CLI" new --base master chore/explicit-base
  grep -q "^base: master" "${repo}/worktrees/chore/explicit-base/.worktree-task.md"

  rm -rf "$remote_repo"
}

run_in_temp_repo test_new_verify_check
run_in_temp_repo test_check_rejects_task_contract_changes
run_in_temp_repo test_new_defaults_to_master_or_main
run_in_temp_repo test_new_prefers_origin_head_and_accepts_base_override

echo "[PASS] e2e_lifecycle"
