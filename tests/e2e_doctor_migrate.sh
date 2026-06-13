#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/framework.sh"

test_version_prints_semver() {
  local repo="$1"
  cd "$repo"
  local ver
  ver="$("$CLI" --version)"
  echo "$ver" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+'
  # "version" subcommand produces the same output
  [ "$("$CLI" version)" = "$ver" ]
}

test_doctor_outside_repo() {
  local repo="$1"
  local tmpdir
  tmpdir="$(mktemp -d)"
  (
    cd "$tmpdir"
    # Not a git repo, doctor should still run and report it
    output="$("$CLI" doctor 2>&1)"
    echo "$output" | grep -q "Not inside a git repository"
    echo "$output" | grep -q "Version:"
    echo "$output" | grep -q "CLI path:"
  )
  rm -rf "$tmpdir"
}

test_doctor_inside_repo() {
  local repo="$1"
  cd "$repo"
  git config user.name "wtcraft-smoke"
  git config user.email "wtcraft-smoke@example.com"

  # Before init: doctor should report missing scaffolds
  output="$("$CLI" doctor 2>&1)"
  echo "$output" | grep -q "Missing scaffold:"

  # After init: doctor should report complete
  "$CLI" init
  git add -A && git commit -q -m "init"
  output="$("$CLI" doctor 2>&1)"
  echo "$output" | grep -q "Scaffold files: Complete"
}

test_doctor_detects_legacy_file() {
  local repo="$1"
  cd "$repo"
  git config user.name "wtcraft-smoke"
  git config user.email "wtcraft-smoke@example.com"
  "$CLI" init
  git add -A && git commit -q -m "init"

  # Create a legacy file
  echo "legacy" > .worktree-task.template.md
  output="$("$CLI" doctor 2>&1)"
  echo "$output" | grep -q "Legacy file detected"
  echo "$output" | grep -q "wtcraft migrate"
}

test_migrate_yes_deletes_legacy() {
  local repo="$1"
  cd "$repo"
  git config user.name "wtcraft-smoke"
  git config user.email "wtcraft-smoke@example.com"
  "$CLI" init
  git add -A && git commit -q -m "init"

  # Create legacy file
  echo "legacy" > .worktree-task.template.md
  test -f .worktree-task.template.md

  # migrate --yes should delete it without prompting
  "$CLI" migrate --yes
  test ! -f .worktree-task.template.md
}

test_migrate_yes_no_legacy() {
  local repo="$1"
  cd "$repo"
  git config user.name "wtcraft-smoke"
  git config user.email "wtcraft-smoke@example.com"
  "$CLI" init
  git add -A && git commit -q -m "init"

  # No legacy file: migrate should report nothing to do
  output="$("$CLI" migrate --yes 2>&1)"
  echo "$output" | grep -q "No legacy files to migrate"
}

test_migrate_non_interactive_skips_without_yes() {
  local repo="$1"
  cd "$repo"
  git config user.name "wtcraft-smoke"
  git config user.email "wtcraft-smoke@example.com"
  "$CLI" init
  git add -A && git commit -q -m "init"

  echo "legacy" > .worktree-task.template.md

  # Pipe stdin to make it non-interactive; without --yes it should not delete
  output="$(echo "" | "$CLI" migrate 2>&1)"
  echo "$output" | grep -q "Run with --yes to delete automatically"
  test -f .worktree-task.template.md
}

test_help_doctor_migrate() {
  local repo="$1"
  cd "$repo"
  "$CLI" help doctor | grep -q "Diagnose"
  "$CLI" help migrate | grep -q "scaffold"
}

run_in_temp_repo test_version_prints_semver
test_doctor_outside_repo ""
run_in_temp_repo test_doctor_inside_repo
run_in_temp_repo test_doctor_detects_legacy_file
run_in_temp_repo test_migrate_yes_deletes_legacy
run_in_temp_repo test_migrate_yes_no_legacy
run_in_temp_repo test_migrate_non_interactive_skips_without_yes
run_in_temp_repo test_help_doctor_migrate

echo "[PASS] e2e_doctor_migrate"
