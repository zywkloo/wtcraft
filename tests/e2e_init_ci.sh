#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/framework.sh"

WORKFLOW=".github/workflows/wtcraft-trusted-change.yml"
ADAPTER=".wtcraft/policy_git_adapter.py"
EVALUATOR=".wtcraft/policy_evaluator.py"

# The vendored copies under templates/ are what ship to users; scripts/ is what
# this repository tests and fixes. npm skips symlinks, so the two cannot be
# linked and must be real files -- which makes silent drift possible, and a
# stale vendored evaluator would keep bugs (such as the rename bypass) that
# scripts/ already fixes. Fail the build instead.
test_vendored_copies_match_scripts() {
  cmp "${REPO_ROOT}/scripts/policy_evaluator.py" \
      "${REPO_ROOT}/templates/.wtcraft/policy_evaluator.py"
  cmp "${REPO_ROOT}/scripts/policy_git_adapter.py" \
      "${REPO_ROOT}/templates/.wtcraft/policy_git_adapter.py"
}

test_init_ci_installs_check_and_adapter() {
  local repo="$1"
  cd "$repo"
  "$CLI" init-ci

  test -f "$WORKFLOW"
  test -f "$ADAPTER"
  test -f "$EVALUATOR"

  # The workflow must run the vendored adapter: a user repository has no
  # scripts/ directory, and the privileged job may not install one.
  grep -qF 'python3 .wtcraft/policy_git_adapter.py' "$WORKFLOW"
  # Load-bearing per the setup guide; a shallow clone breaks every PR whose
  # base advanced.
  grep -qF 'fetch-depth: 0' "$WORKFLOW"
  # The job must never execute pull-request code.
  ! grep -qF 'head.sha }}' <(grep -A2 'actions/checkout' "$WORKFLOW")
}

test_init_ci_is_idempotent() {
  local repo="$1"
  cd "$repo"
  "$CLI" init-ci >/dev/null
  printf 'local edit\n' >> "$WORKFLOW"
  local before
  before="$(cat "$WORKFLOW")"

  "$CLI" init-ci > out.txt
  # An edited file is reported, never silently replaced.
  grep -qF 'NOT changed' out.txt
  test "$(cat "$WORKFLOW")" = "$before"
}

test_init_ci_force_refreshes_drifted_files() {
  local repo="$1"
  cd "$repo"
  "$CLI" init-ci >/dev/null
  printf '# stale\n' >> "$ADAPTER"

  "$CLI" init-ci --force >/dev/null
  cmp "${REPO_ROOT}/scripts/policy_git_adapter.py" "$ADAPTER"
}

test_init_ci_requires_a_git_repository() {
  local dir
  dir="$(mktemp -d)"
  if (cd "$dir" && "$CLI" init-ci >/dev/null 2>&1); then
    rm -rf "$dir"
    echo "init-ci should refuse a non-repository" >&2
    return 1
  fi
  rm -rf "$dir"
}

# The point of the command is an enforcement path that actually runs. Drive the
# vendored adapter exactly as the workflow does, on a real policy branch.
test_vendored_adapter_authorizes_and_fails_closed() {
  local repo="$1"
  cd "$repo"
  git config user.email t@e.st
  git config user.name t
  mkdir -p src
  echo base > src/a.txt
  git add -A
  git commit -qm base
  "$CLI" init-ci >/dev/null
  git add -A
  git commit -qm "install check"
  local base
  base="$(git rev-parse HEAD)"

  git checkout -q --orphan wtcraft-policy
  git rm -rqf .
  mkdir -p .wtcraft/policies
  printf '{"schema_version":1,"policy_id":"p-1","task_id":"t","repository":"acme/widget","head_ref":"refs/heads/feat/x","base_sha":"%s","allowed_paths":["src/**"],"off_limits":[".github/**"],"verification":[{"name":"unit","command":"true","timeout_seconds":60}]}\n' "$base" > .wtcraft/policies/p-1.json
  git add -A
  git commit -qm policy

  git checkout -q master
  git checkout -q -b feat/x
  echo change >> src/a.txt
  git commit -qam "authorized"

  local evidence
  evidence="$(python3 .wtcraft/policy_git_adapter.py --repo . \
    --repository acme/widget --head-ref refs/heads/feat/x \
    --head-sha "$(git rev-parse HEAD)" --base-sha "$base" \
    --policy-ref refs/heads/wtcraft-policy)"
  printf '%s' "$evidence" | grep -qF '"result":"pass"'
  # Authorization is never a claim about verification.
  printf '%s' "$evidence" | grep -qF '"status":"not_executed"'
  # Provenance must name the policy source, not just the verdict.
  printf '%s' "$evidence" | grep -qF '"source_ref":"refs/heads/wtcraft-policy"'

  # Renaming a protected file out of an off-limits directory must fail closed.
  git checkout -q -b feat/rename master
  git mv "$WORKFLOW" src/sneaky.yml
  git commit -qm rename
  local denied status
  set +e
  denied="$(python3 .wtcraft/policy_git_adapter.py --repo . \
    --repository acme/widget --head-ref refs/heads/feat/x \
    --head-sha "$(git rev-parse HEAD)" --base-sha "$base" \
    --policy-ref refs/heads/wtcraft-policy)"
  status=$?
  set -e
  test "$status" -ne 0
  printf '%s' "$denied" | grep -qF '"result":"fail"'
  printf '%s' "$denied" | grep -qF '.github/workflows/wtcraft-trusted-change.yml'
}

test_vendored_copies_match_scripts
run_in_temp_repo test_init_ci_installs_check_and_adapter
run_in_temp_repo test_init_ci_is_idempotent
run_in_temp_repo test_init_ci_force_refreshes_drifted_files
test_init_ci_requires_a_git_repository
if command -v python3 >/dev/null 2>&1; then
  run_in_temp_repo test_vendored_adapter_authorizes_and_fails_closed
else
  echo "[SKIP] vendored adapter end-to-end (python3 not available)"
fi

echo "[PASS] e2e_init_ci"
