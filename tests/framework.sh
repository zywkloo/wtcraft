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
