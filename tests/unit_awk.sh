#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/framework.sh"

# Source the script to test the functions directly
source "${CLI}"

echo "=== Running unit_awk tests ==="

test_extract_frontmatter() {
  local tmpdir="$1"
  local file="${tmpdir}/test.md"
  
  cat <<'EOF' > "$file"
---
key1: value1
key2: value with spaces
---
# Content
EOF

  local val1
  val1="$(extract_frontmatter "$file" "key1")"
  if [ "$val1" != "value1" ]; then
    echo "[FAIL] extract_frontmatter key1. Expected 'value1', got '$val1'"
    exit 1
  fi

  local val2
  val2="$(extract_frontmatter "$file" "key2")"
  if [ "$val2" != "value with spaces" ]; then
    echo "[FAIL] extract_frontmatter key2. Expected 'value with spaces', got '$val2'"
    exit 1
  fi
}

test_set_frontmatter() {
  local tmpdir="$1"
  local file="${tmpdir}/test.md"
  
  cat <<'EOF' > "$file"
---
key1: old
---
# Content
EOF

  set_frontmatter "$file" "key1" "new_val"
  set_frontmatter "$file" "key2" "added_val"

  local val1
  val1="$(extract_frontmatter "$file" "key1")"
  if [ "$val1" != "new_val" ]; then
    echo "[FAIL] set_frontmatter key1. Expected 'new_val', got '$val1'"
    exit 1
  fi

  local val2
  val2="$(extract_frontmatter "$file" "key2")"
  if [ "$val2" != "added_val" ]; then
    echo "[FAIL] set_frontmatter key2. Expected 'added_val', got '$val2'"
    exit 1
  fi
}

test_collect_section_items() {
  local tmpdir="$1"
  local file="${tmpdir}/test.md"
  
  cat <<'EOF' > "$file"
## Scope
- src/
- tests/

## Off-limits
- src/core
EOF

  local items
  items=()
  mapfile -t items < <(collect_section_items "$file" "Scope")

  if [ "${#items[@]}" -ne 2 ] || [ "${items[0]}" != "src/" ] || [ "${items[1]}" != "tests/" ]; then
    echo "[FAIL] collect_section_items Scope. Got: ${items[*]}"
    exit 1
  fi
}

test_collect_verification_commands() {
  local tmpdir="$1"
  local file="${tmpdir}/test.md"
  
  cat <<'EOF' > "$file"
## Verification
- [ ] npm run test
- [x] echo "done"
EOF

  local cmds
  cmds=()
  mapfile -t cmds < <(collect_verification_commands "$file")

  if [ "${#cmds[@]}" -ne 2 ] || [ "${cmds[0]}" != "npm run test" ] || [ "${cmds[1]}" != "echo \"done\"" ]; then
    echo "[FAIL] collect_verification_commands. Got: ${cmds[*]}"
    exit 1
  fi
}

run_in_temp_repo test_extract_frontmatter
run_in_temp_repo test_set_frontmatter
run_in_temp_repo test_collect_section_items
run_in_temp_repo test_collect_verification_commands

echo "[PASS] unit_awk"
