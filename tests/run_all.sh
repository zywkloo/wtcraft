#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Running wtcraft test suite ==="

bash "${SCRIPT_DIR}/unit_codegen.sh"
bash "${SCRIPT_DIR}/e2e_init_patch.sh"
bash "${SCRIPT_DIR}/e2e_lifecycle.sh"

echo "=================================="
echo "All tests passed successfully!"
