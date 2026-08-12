#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/framework.sh"

# Regression: `lang install` with no extra args crashed on macOS bash 3.2 due to
# empty-array expansion under set -u (remaining[@]: unbound variable).

test_lang_install_claude_only() {
  local repo="$1"
  printf '# Project\n' > "${repo}/CLAUDE.md"

  "$CLI" lang install --repo "$repo"

  grep -qF "wtcraft:lang:start" "${repo}/CLAUDE.md" || {
    echo "[FAIL] lang install: block missing from CLAUDE.md"; exit 1
  }
  [ ! -f "${repo}/AGENTS.md" ] || {
    echo "[FAIL] lang install: should not create AGENTS.md when absent"; exit 1
  }
  echo "[PASS] lang install patches CLAUDE.md only when AGENTS.md absent"

  # idempotent
  "$CLI" lang install --repo "$repo"
  local count
  count="$(grep -c "wtcraft:lang:start" "${repo}/CLAUDE.md")"
  [ "$count" -eq 1 ] || { echo "[FAIL] lang install: idempotent check failed (count=$count)"; exit 1; }
  echo "[PASS] lang install is idempotent"
}

test_lang_install_agents_only() {
  local repo="$1"
  printf '# Agents\n' > "${repo}/AGENTS.md"

  "$CLI" lang install --repo "$repo"

  grep -qF "wtcraft:lang:start" "${repo}/AGENTS.md" || {
    echo "[FAIL] lang install: block missing from AGENTS.md"; exit 1
  }
  [ ! -f "${repo}/CLAUDE.md" ] || {
    echo "[FAIL] lang install: should not create CLAUDE.md when absent"; exit 1
  }
  echo "[PASS] lang install patches AGENTS.md only when CLAUDE.md absent"
}

test_lang_install_both() {
  local repo="$1"
  printf '# Project\n' > "${repo}/CLAUDE.md"
  printf '# Agents\n'  > "${repo}/AGENTS.md"

  "$CLI" lang install --repo "$repo"

  grep -qF "wtcraft:lang:start" "${repo}/CLAUDE.md" || {
    echo "[FAIL] lang install both: block missing from CLAUDE.md"; exit 1
  }
  grep -qF "wtcraft:lang:start" "${repo}/AGENTS.md" || {
    echo "[FAIL] lang install both: block missing from AGENTS.md"; exit 1
  }
  echo "[PASS] lang install patches both when both exist"

  "$CLI" lang remove --repo "$repo"

  grep -qF "wtcraft:lang:start" "${repo}/CLAUDE.md" && {
    echo "[FAIL] lang remove: block still in CLAUDE.md"; exit 1
  } || true
  grep -qF "wtcraft:lang:start" "${repo}/AGENTS.md" && {
    echo "[FAIL] lang remove: block still in AGENTS.md"; exit 1
  } || true
  echo "[PASS] lang remove strips both files"
}

test_lang_install_neither() {
  local repo="$1"
  local out rc
  set +e
  out="$("$CLI" lang install --repo "$repo" 2>&1)"
  rc=$?
  set -e
  [ "$rc" -ne 0 ] || { echo "[FAIL] lang install neither: expected non-zero exit, got 0"; exit 1; }
  echo "$out" | grep -qi "wtcraft agent init" || {
    echo "[FAIL] lang install neither: error should mention 'wtcraft agent init'"; exit 1
  }
  [ ! -f "${repo}/CLAUDE.md" ] && [ ! -f "${repo}/AGENTS.md" ] || {
    echo "[FAIL] lang install neither: should not create any files"; exit 1
  }
  echo "[PASS] lang install exits 1 and mentions 'wtcraft agent init' when neither file exists"
}

run_in_temp_repo test_lang_install_claude_only
run_in_temp_repo test_lang_install_agents_only
run_in_temp_repo test_lang_install_both
run_in_temp_repo test_lang_install_neither

echo "[PASS] e2e_lang"
