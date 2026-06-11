#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

if ! command -v python3 >/dev/null 2>&1; then
  echo "[SKIP] unit_codegen (python3 not available)"
  exit 0
fi

# Syntax check
python3 -m py_compile "${REPO_ROOT}/scripts/gen-presets.py"

# Execution check: run gen-presets.py in a temp workspace and assert outputs
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

cp -r "${REPO_ROOT}/templates" "${tmpdir}/"
cp "${REPO_ROOT}/README.md" "${tmpdir}/"

(cd "$tmpdir" && python3 "${REPO_ROOT}/scripts/gen-presets.py")

for preset in balanced anthropic openai google; do
  preset_file="${tmpdir}/templates/.agent-harness/presets/preset-${preset}.yml"
  if [ ! -f "$preset_file" ]; then
    echo "[FAIL] gen-presets.py did not generate preset-${preset}.yml"
    exit 1
  fi
  if ! grep -q "^  orchestrator:" "$preset_file"; then
    echo "[FAIL] preset-${preset}.yml missing orchestrator role"
    exit 1
  fi
done

if ! grep -q "wtcraft:models:start" "${tmpdir}/README.md"; then
  echo "[FAIL] gen-presets.py did not update README.md markers"
  exit 1
fi

echo "[PASS] unit_codegen"
