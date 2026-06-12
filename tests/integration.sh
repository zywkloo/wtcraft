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

test_npm_package_integration() {
  local repo="$1"
  cd "$repo"

  # 1. Pack the package to create a tarball (wtcraft-x.y.z.tgz)
  local tarball
  tarball="$(cd "$REPO_ROOT" && npm pack --quiet)"
  local tarball_path="${REPO_ROOT}/${tarball}"

  # 2. Create a clean temp prefix for global installation simulation
  local npm_prefix
  npm_prefix="$(mktemp -d)"

  # 3. Install the packaged tarball into the prefix
  npm install -g --prefix "$npm_prefix" "$tarball_path" --quiet --no-audit --no-fund

  # 4. Find the installed binary path
  local wt_binary="${npm_prefix}/bin/wtcraft"
  local wtc_binary="${npm_prefix}/bin/wtc"

  if [ ! -f "$wt_binary" ]; then
    echo "NPM packaged binary was not installed at expected path: $wt_binary"
    rm -f "$tarball_path"
    rm -rf "$npm_prefix"
    exit 1
  fi
  if [ ! -f "$wtc_binary" ]; then
    echo "NPM packaged alias was not installed at expected path: $wtc_binary"
    rm -f "$tarball_path"
    rm -rf "$npm_prefix"
    exit 1
  fi

  # 5. Run init using the packaged binary
  "$wtc_binary" init

  # 6. Verify templates were successfully copied
  if [ ! -f ".agent-harness/planner.md" ]; then
    echo "NPM packaged alias init failed to create planner.md"
    rm -f "$tarball_path"
    rm -rf "$npm_prefix"
    exit 1
  fi

  # Cleanup
  rm -f "$tarball_path"
  rm -rf "$npm_prefix"
}

test_pip_package_integration() {
  local repo="$1"
  cd "$repo"

  # 1. Create a clean virtualenv
  local venv_dir
  venv_dir="$(mktemp -d)"
  python3 -m venv "$venv_dir"

  # 2. Install the local python package inside the virtualenv
  local pip_log
  pip_log="$(mktemp)"
  if ! "$venv_dir/bin/pip" install "$REPO_ROOT" --quiet >"$pip_log" 2>&1; then
    if grep -Eiq \
      "Failed to establish a new connection|Temporary failure in name resolution|nodename nor servname provided|Could not find a version that satisfies the requirement setuptools>=61|No matching distribution found for setuptools>=61" \
      "$pip_log"; then
      echo "SKIP: pip package integration (offline/network-restricted environment)"
      rm -f "$pip_log"
      rm -rf "$venv_dir"
      return 0
    fi

    echo "FAIL: pip package integration install error"
    cat "$pip_log"
    rm -f "$pip_log"
    rm -rf "$venv_dir"
    exit 1
  fi
  rm -f "$pip_log"

  # 3. Find the installed binary path
  local wt_binary="${venv_dir}/bin/wtcraft"
  local wtc_binary="${venv_dir}/bin/wtc"

  if [ ! -f "$wt_binary" ]; then
    echo "Pip packaged binary was not installed at expected path: $wt_binary"
    rm -rf "$venv_dir"
    exit 1
  fi
  if [ ! -f "$wtc_binary" ]; then
    echo "Pip packaged alias was not installed at expected path: $wtc_binary"
    rm -rf "$venv_dir"
    exit 1
  fi

  # 4. Run init using the packaged binary
  "$wtc_binary" init

  # 5. Verify templates were successfully copied
  if [ ! -f ".agent-harness/planner.md" ]; then
    echo "Pip packaged alias init failed to create planner.md"
    rm -rf "$venv_dir"
    exit 1
  fi

  # Cleanup
  rm -rf "$venv_dir"
}

echo "Running integration tests..."
run_in_temp_repo test_symlink_execution
run_in_temp_repo test_pip_entrypoint_execution
run_in_temp_repo test_npm_package_integration
run_in_temp_repo test_pip_package_integration

echo "Integration tests passed."
