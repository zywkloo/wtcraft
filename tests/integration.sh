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

test_symlink_execution() {
  local repo="$1"
  cd "$repo"

  local temp_bin
  temp_bin="$(mktemp -d)"
  ln -s "$CLI" "${temp_bin}/wtcraft-symlinked"

  "${temp_bin}/wtcraft-symlinked" init

  if [ ! -f ".agent-harness/planner.md" ]; then
    echo "Symlinked init failed to create planner.md"
    exit 1
  fi

  rm -rf "$temp_bin"
}

test_pip_entrypoint_execution() {
  local repo="$1"
  cd "$repo"

  python3 "${REPO_ROOT}/src/wtcraft/_cli.py" init

  if [ ! -f ".agent-harness/planner.md" ]; then
    echo "Python entrypoint init failed to create planner.md"
    exit 1
  fi
}

echo "Running integration tests..."
run_in_temp_repo test_symlink_execution
run_in_temp_repo test_pip_entrypoint_execution

echo "Integration tests passed."
