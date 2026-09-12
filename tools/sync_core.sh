#!/usr/bin/env bash
# Refreshes this repository's vendored copy of the shared hospital_core package.
#
# The canonical copy lives in Dev_Central. Every application repository carries
# a byte-identical copy under packages/hospital_core so that a student can clone
# one repository and run it, with no private-repo authentication and no
# cross-repository path dependency to get wrong.
#
# Run this after hospital_core changes upstream:
#     ./tools/sync_core.sh
set -euo pipefail

CANONICAL_REPO="${CANONICAL_REPO:-https://github.com/LucaProcaryote/Dev_Central.git}"
CANONICAL_REF="${CANONICAL_REF:-main}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="$HERE/packages/hospital_core"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Fetching hospital_core from $CANONICAL_REPO ($CANONICAL_REF)…"
git clone --quiet --depth 1 --branch "$CANONICAL_REF" "$CANONICAL_REPO" "$TMP/central"

if [ ! -d "$TMP/central/packages/hospital_core" ]; then
  echo "error: the canonical repository has no packages/hospital_core" >&2
  exit 1
fi

rm -rf "$TARGET"
mkdir -p "$(dirname "$TARGET")"
cp -R "$TMP/central/packages/hospital_core" "$TARGET"
rm -rf "$TARGET/.dart_tool" "$TARGET/build"

echo "Updated $TARGET"
echo "Run 'flutter pub get' to pick up the change."
