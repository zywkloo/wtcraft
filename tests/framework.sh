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
    # Pin the initial branch instead of inheriting init.defaultBranch. Tests
    # that assert a default base of `master` otherwise pass or fail according
    # to the developer's global git config: they are green on CI, where git
    # still defaults to master, and red on any machine configured for main.
    # symbolic-ref works before the first commit and on every git version.
    git symbolic-ref HEAD refs/heads/master
    "$fn_name" "$tmpdir"
  )
  rm -rf "$tmpdir"
}
