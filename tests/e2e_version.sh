#!/usr/bin/env bash
#
# Version resolution: env stamp wins, in-repo reads the manifest, and a
# manifest-less install degrades to "unknown" instead of erroring.
#
source "$(dirname "${BASH_SOURCE[0]}")/framework.sh"

fail() { echo "FAIL: $*" >&2; exit 1; }

# 1. Installer-stamped WTCRAFT_VERSION wins.
out="$(WTCRAFT_VERSION="9.9.9-test" bash "$CLI" --version)"
[ "$out" = "9.9.9-test" ] || fail "env stamp: expected 9.9.9-test, got '$out'"

# 2. In-repo (no env): reads a real manifest version, never "unknown".
out="$(env -u WTCRAFT_VERSION bash "$CLI" --version)"
case "$out" in
  unknown | "") fail "in-repo --version should read a manifest, got '$out'" ;;
esac

# 3. Manifest-less install (script copied away from its manifests, no env):
#    degrades to "unknown" cleanly. Mirrors the brew/pip-without-stamp layout.
base="$(mktemp -d)"
mkdir -p "${base}/sub"
cp "$CLI" "${base}/sub/wtcraft"
out="$(env -u WTCRAFT_VERSION bash "${base}/sub/wtcraft" --version)"
rm -rf "$base"
[ "$out" = "unknown" ] || fail "manifest-less --version should be 'unknown', got '$out'"

echo "Version resolution tests passed."
