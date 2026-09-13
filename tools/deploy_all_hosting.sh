#!/usr/bin/env bash
# Builds and deploys all five applications to Firebase Hosting.
#
#   ./tools/deploy_all_hosting.sh
#   ./tools/deploy_all_hosting.sh --auth firebase
#
# Expects the five repositories to be checked out side by side:
#
#   somewhere/
#     EHR/  ADT/  PHARM/  EAI/  Dev_Central/
#
# Requires the Firebase CLI and `firebase login` (once). The hosting sites must
# exist first - see the one-off setup in FIREBASE.md.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE="$(cd "$HERE/.." && pwd)"

REPOS=(EHR ADT PHARM EAI Dev_Central)

missing=()
for repo in "${REPOS[@]}"; do
  [ -d "$WORKSPACE/$repo" ] || missing+=("$repo")
done
if [ ${#missing[@]} -gt 0 ]; then
  echo "error: not checked out beside Dev_Central: ${missing[*]}" >&2
  echo "       expected them under $WORKSPACE" >&2
  exit 66
fi

echo "Deploying ${#REPOS[@]} applications from $WORKSPACE"
echo

failed=()
for repo in "${REPOS[@]}"; do
  echo "=== $repo ==="
  if (cd "$WORKSPACE/$repo" && ./tools/deploy_hosting.sh "$@"); then
    echo
  else
    echo "  $repo FAILED" >&2
    failed+=("$repo")
    echo
  fi
done

if [ ${#failed[@]} -gt 0 ]; then
  echo "Failed: ${failed[*]}" >&2
  exit 1
fi

cat <<'URLS'
All five deployed:

  EHR      https://my-hospital-ehr.procaryote.com
  ADT      https://my-hospital-adt.procaryote.com
  PHARM    https://my-hospital-pharm.procaryote.com
  EAI      https://my-hospital-eai.procaryote.com
  Devices  https://my-hospital-dev.procaryote.com

Each student opens the device simulator with their own number:

  https://my-hospital-dev.procaryote.com/?device=DEV3
URLS
