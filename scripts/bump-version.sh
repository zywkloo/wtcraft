#!/usr/bin/env bash
#
# Single entry point for bumping the wtcraft version.
#
# The version unavoidably lives in three build manifests (each build system
# reads its own): pyproject.toml, package.json, and the Homebrew formula's
# release tag. This script is the one command that keeps them in sync, so the
# version is bumped from a single place instead of edited by hand in three.
#
# The Python package (__init__.py) and the installed shell (read_cli_version)
# derive their version at runtime, so they are not edited here.
#
# Usage: scripts/bump-version.sh <semver>    e.g. scripts/bump-version.sh 0.4.2
#
set -euo pipefail

new="${1:-}"
case "$new" in
  "")        echo "usage: bump-version.sh <semver>  (e.g. 0.4.2)" >&2; exit 1 ;;
  *[!0-9.]*) echo "version must contain only digits and dots: $new" >&2; exit 1 ;;
esac

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# pyproject.toml:  version = "x"
sed -i.bak -E "s/^version = \"[^\"]*\"/version = \"${new}\"/" "${root}/pyproject.toml"
# package.json:    "version": "x"  (the sole top-level version key)
sed -i.bak -E "s/(\"version\"[[:space:]]*:[[:space:]]*\")[^\"]*(\")/\1${new}\2/" "${root}/package.json"
# Formula:         .../tags/v<x>.tar.gz  (Homebrew derives #{version} from this)
sed -i.bak -E "s#(archive/refs/tags/v)[0-9][0-9.]*(\.tar\.gz)#\1${new}\2#" "${root}/Formula/wtcraft.rb"

rm -f "${root}/pyproject.toml.bak" "${root}/package.json.bak" "${root}/Formula/wtcraft.rb.bak"

echo "Bumped wtcraft to ${new} in:"
echo "  pyproject.toml"
echo "  package.json"
echo "  Formula/wtcraft.rb (release tag)"
echo
echo "Still manual: Formula sha256 must be updated for the new tarball:"
echo "  curl -sL https://github.com/zywkloo/wtcraft/archive/refs/tags/v${new}.tar.gz | shasum -a 256"
