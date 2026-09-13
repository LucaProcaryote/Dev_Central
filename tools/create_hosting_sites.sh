#!/usr/bin/env bash
# Creates the five Firebase Hosting sites. Run once, after `firebase login`.
#
#   ./tools/create_hosting_sites.sh
#
# A Firebase project has one default site and any number of extra ones. The
# mini-hospital needs five, so that each application gets its own URL and can
# be redeployed without touching the others.
#
# Site ids are globally unique across all of Firebase Hosting, so if one is
# taken, edit SITES here and the matching `.firebaserc` in that repository.
set -euo pipefail

PROJECT="${FIREBASE_PROJECT:-my-hospital-2026}"

# "target:site" pairs rather than an associative array: macOS still ships bash
# 3.2, which has no associative arrays, and this has to run on a laptop.
SITES=(
  "ehr:my-hospital-2026-ehr"
  "adt:my-hospital-2026-adt"
  "pharm:my-hospital-2026-pharm"
  "eai:my-hospital-2026-eai"
  "dev:my-hospital-2026-dev"
)

command -v firebase >/dev/null || { echo "npm i -g firebase-tools" >&2; exit 69; }

echo "Project: $PROJECT"
for entry in "${SITES[@]}"; do
  target="${entry%%:*}"
  site="${entry##*:}"
  printf '%-8s %-28s ' "$target" "$site"
  if firebase hosting:sites:list --project "$PROJECT" 2>/dev/null | grep -q "$site"; then
    echo "already exists"
  elif firebase hosting:sites:create "$site" --project "$PROJECT" >/dev/null 2>&1; then
    echo "created"
  else
    echo "COULD NOT CREATE - the id may be taken globally; pick another"
  fi
done

echo
echo "Now deploy:  ./tools/deploy_all_hosting.sh"
