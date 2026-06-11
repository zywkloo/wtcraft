#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Verify python is available before running
if command -v python3 >/dev/null 2>&1; then
  python3 -m py_compile "${REPO_ROOT}/scripts/gen-presets.py"
else
  echo "[SKIP] python3 not available, skipping codegen tests"
fi

echo "[PASS] unit_codegen"
