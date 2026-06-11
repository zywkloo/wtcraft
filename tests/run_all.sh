#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Running wtcraft test suite ==="

bash "${SCRIPT_DIR}/unit_codegen.sh"
bash "${SCRIPT_DIR}/unit_awk.sh"
bash "${SCRIPT_DIR}/e2e_init_patch.sh"
bash "${SCRIPT_DIR}/e2e_lifecycle.sh"

# Integration tests require npm and python3 (skip gracefully if unavailable)
if command -v npm >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
  bash "${SCRIPT_DIR}/integration.sh"
else
  echo "[SKIP] integration tests (npm or python3 not available)"
fi

echo "=================================="
echo "All tests passed successfully!"
