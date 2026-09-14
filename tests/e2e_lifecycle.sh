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
  local state_file="${repo}/worktrees/chore/smoke/.worktree-state.json"
  sed -i.bak "s|pnpm tsc --noEmit|echo ok|" "$task_file"
  rm -f "${task_file}.bak"
  test -f "$state_file"
  python3 -m json.tool "$state_file" >/dev/null
  grep -q '^state_file: .worktree-state.json' "$task_file"
  ! grep -qE '^(stage|role|agent|status|verify_result|verified):' "$task_file"
  git -C worktrees/chore/smoke check-ignore -q .worktree-task.md
  git -C worktrees/chore/smoke check-ignore -q .worktree-state.json
  test -z "$(git -C worktrees/chore/smoke status --short -- .worktree-task.md)"
  test -z "$(git -C worktrees/chore/smoke status --short -- .worktree-state.json)"

  "$CLI" verify chore/smoke
  "$CLI" check chore/smoke
  "$CLI" verify --json chore/smoke | python3 -m json.tool >/dev/null
  "$CLI" verify --json chore/smoke | grep -q '"result":"pass"'
  "$CLI" check --json chore/smoke | python3 -m json.tool >/dev/null
  "$CLI" check --json chore/smoke | grep -q '"result":"pass"'

  # verify records results in the sidecar without mutating the specification
  grep -q '"verify_result": "pass"' "$state_file"
  grep -q '"verified": "' "$state_file"
  ! grep -q '^verify_result:' "$task_file"
  "$CLI" status | grep -q "pass"

  # stage/role columns come from the new contract convention
  "$CLI" status | grep -q "planned"
  "$CLI" status | grep -q "executor"

  # --json is well-formed and carries the same facts
  "$CLI" status --json | python3 -m json.tool >/dev/null
  "$CLI" status --json | grep -q '"stage":"planned"'
  "$CLI" status --json | grep -q '"state_present":true'
  "$CLI" status --json | grep -q '"check_result":"pass"'
  "$CLI" status --json | grep -q '"attempt":0'
  "$CLI" status --json | grep -q '"ready":true'
  mkdir -p "${repo}/worktrees/chore/smoke/src"
  echo "later edit" >"${repo}/worktrees/chore/smoke/src/evidence-stale.ts"
  "$CLI" status --json | grep -q '"ready":false'
  "$CLI" status --json | grep -q '"evidence_stale":true'
  rm "${repo}/worktrees/chore/smoke/src/evidence-stale.ts"
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

  # lifecycle updates also go to the sidecar, never the task specification
  "$CLI" state chore/smoke --stage executing --role executor --agent codex --attempt 2
  "$CLI" state --json chore/smoke --handoff-from claude --handoff-to codex | python3 -m json.tool >/dev/null
  grep -q '"stage": "executing"' "$state_file"
  grep -q '"status": "ready"' "$state_file"
  grep -q '"attempt": 2' "$state_file"
  "$CLI" status --json | grep -q '"handoff_from":"claude"'
  "$CLI" status --json | grep -q '"handoff_to":"codex"'
  ! grep -q '^stage:' "$task_file"

  "$CLI" state chore/smoke --stage done
  grep -q '"status": "done"' "$state_file"
  "$CLI" state chore/smoke --stage executing

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
  grep -q '"verify_result": "fail"' "$state_file"

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
  local unusual_path=$'odd path\ncontrol\001line.txt'
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

  # A missing/invalid base is a fatal gate error, never an empty-diff pass.
  sed -i.bak "s|^base: .*|base: does-not-exist|" "$task_file"
  rm -f "${task_file}.bak"
  set +e
  check_json="$("$CLI" check --json chore/smoke 2>/dev/null)"
  check_exit=$?
  set -e
  [ "$check_exit" -eq 1 ]
  CHECK_JSON="$check_json" python3 - <<'PY'
import json
import os

payload = json.loads(os.environ["CHECK_JSON"])
assert payload["ok"] is False
assert "failed to enumerate changed files" in payload["error"]["message"]
PY
  sed -i.bak "s|^base: .*|base: ${current_branch}|" "$task_file"
  rm -f "${task_file}.bak"

  mkdir -p "${repo}/worktrees/chore/smoke/src"
  echo "ok" > "${repo}/worktrees/chore/smoke/src/example.ts"
  "$CLI" check chore/smoke

  # check sees uncommitted edits to tracked files: out-of-scope edit fails
  echo "tweak" >> "${repo}/worktrees/chore/smoke/.wtcraft-seed"
  ! "$CLI" check chore/smoke
  git -C "${repo}/worktrees/chore/smoke" checkout -- .wtcraft-seed
  "$CLI" check chore/smoke
}

test_machine_mode_fatal_errors_are_json() {
  local repo="$1"
  cd "$repo"

  local command output exit_code
  for command in check verify; do
    set +e
    output="$("$CLI" "$command" --json 2>/dev/null)"
    exit_code=$?
    set -e
    [ "$exit_code" -eq 1 ]
    COMMAND="$command" OUTPUT="$output" python3 - <<'PY'
import json
import os

payload = json.loads(os.environ["OUTPUT"])
assert payload["command"] == os.environ["COMMAND"]
assert payload["ok"] is False
assert payload["error"]["code"] == 1
PY
  done

  set +e
  output="$("$CLI" status --json unexpected 2>/dev/null)"
  exit_code=$?
  set -e
  [ "$exit_code" -eq 1 ]
  OUTPUT="$output" python3 - <<'PY'
import json
import os

payload = json.loads(os.environ["OUTPUT"])
assert payload["command"] == "status"
assert payload["ok"] is False
assert payload["error"]["code"] == 1
PY
}

test_status_preserves_newline_worktree_paths() {
  local repo="$1"
  cd "$repo"
  git config user.name "wtcraft-smoke"
  git config user.email "wtcraft-smoke@example.com"
  echo "seed" > .wtcraft-seed
  git add .wtcraft-seed
  git commit -q -m "seed"

  local unusual_worktree="${repo}/worktree"$'\n'"newline"
  git worktree add -q "$unusual_worktree" -b chore/newline

  local registered_worktree status_json
  registered_worktree="$(cd "$unusual_worktree" && pwd -P)"
  status_json="$("$CLI" status --json)"
  STATUS_JSON="$status_json" UNUSUAL_WORKTREE="$registered_worktree" python3 - <<'PY'
import json
import os

payload = json.loads(os.environ["STATUS_JSON"])
assert any(item["worktree"] == os.environ["UNUSUAL_WORKTREE"] for item in payload)
PY

  git worktree remove --force "$unusual_worktree"
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

test_check_rejects_task_state_changes() {
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
  WTCRAFT_BASE_BRANCH="$current_branch" "$CLI" new chore/task-state

  (
    cd worktrees/chore/task-state
    git add -f .worktree-state.json
    git commit -q -m "accidentally commit task state"
  )

  ! "$CLI" check chore/task-state 2>/dev/null
}

test_status_reads_legacy_frontmatter_without_sidecar() {
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
  WTCRAFT_BASE_BRANCH="$current_branch" "$CLI" new chore/legacy

  local task_file="${repo}/worktrees/chore/legacy/.worktree-task.md"
  rm "${repo}/worktrees/chore/legacy/.worktree-state.json"
  awk '
    { print }
    /^state_file:/ {
      print "stage: executing"
      print "role: executor"
      print "agent: claude"
      print "status: ready"
      print "verify_result: pass"
      print "verified: legacy-time"
    }
  ' "$task_file" >"${task_file}.tmp"
  mv "${task_file}.tmp" "$task_file"

  "$CLI" status --json | grep -q '"state_present":false'
  "$CLI" status --json | grep -q '"stage":"executing"'
  "$CLI" status --json | grep -q '"agent":"claude"'
  "$CLI" status --json | grep -q '"verified":"legacy-time"'
}

test_new_absorbs_legacy_plan_into_sidecar() {
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
  cat >.worktree-task.md <<EOF
---
branch: chore/legacy-plan
agent: claude
stage: planned
role: executor
status: ready
created: 2026-01-01
priority: medium
base: ${current_branch}
verify_result: pass
verified: legacy-time
---

## Scope
- src/

## Off-limits
- docs/

## Verification
- [ ] echo ok
EOF

  WTCRAFT_BASE_BRANCH="$current_branch" "$CLI" new chore/legacy-plan
  local task_file="${repo}/worktrees/chore/legacy-plan/.worktree-task.md"
  local state_file="${repo}/worktrees/chore/legacy-plan/.worktree-state.json"

  grep -q '^task_id: chore/legacy-plan' "$task_file"
  grep -q '^state_file: .worktree-state.json' "$task_file"
  grep -q '<!-- wtcraft:state-sidecar -->' "$task_file"
  ! grep -qE '^(stage|role|agent|status|verify_result|verified):' "$task_file"
  grep -q '"agent": "claude"' "$state_file"
  grep -q '"verify_result": "pass"' "$state_file"
  grep -q '"verified": "legacy-time"' "$state_file"
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

  "$CLI" new --base master 'chore/ampersand&branch'
  grep -qxF 'branch: chore/ampersand&branch' \
    "${repo}/worktrees/chore/ampersand&branch/.worktree-task.md"

  rm -rf "$remote_repo"
}

run_in_temp_repo test_new_verify_check
run_in_temp_repo test_machine_mode_fatal_errors_are_json
run_in_temp_repo test_status_preserves_newline_worktree_paths
run_in_temp_repo test_check_rejects_task_contract_changes
run_in_temp_repo test_check_rejects_task_state_changes
run_in_temp_repo test_status_reads_legacy_frontmatter_without_sidecar
run_in_temp_repo test_new_absorbs_legacy_plan_into_sidecar
run_in_temp_repo test_new_defaults_to_master_or_main
run_in_temp_repo test_new_prefers_origin_head_and_accepts_base_override

echo "[PASS] e2e_lifecycle"
