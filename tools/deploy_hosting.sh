#!/usr/bin/env bash
# Builds this application for the web and deploys it to Firebase Hosting.
#
#   ./tools/deploy_hosting.sh                    # demo data, demo sign-in
#   ./tools/deploy_hosting.sh --auth firebase    # real Firebase sign-in
#   ./tools/deploy_hosting.sh --api https://lab-api.example --backend restApi
#
# The default build carries no backend URLs at all, because a hosted page
# cannot reach anything on a student's localhost. Each visitor gets their own
# in-browser hospital, which is the right classroom default - and any of it can
# still be overridden per visitor with a query string:
#
#   https://my-hospital-2026-dev.web.app/?backend=restApi&api=https://lab-api.example
#
# Requires: the Firebase CLI, and `firebase login` (once).
set -euo pipefail

TARGET="dev"
SITE="my-hospital-2026-dev"
PROJECT="${FIREBASE_PROJECT:-my-hospital-2026}"

BACKEND="memory"
AUTH="demo"
API=""
FHIR=""
EAI=""
DEVICE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --backend) BACKEND="$2"; shift 2 ;;
    --auth)    AUTH="$2";    shift 2 ;;
    --api)     API="$2";     shift 2 ;;
    --fhir)    FHIR="$2";    shift 2 ;;
    --eai)     EAI="$2";     shift 2 ;;
    --device)  DEVICE="$2";  shift 2 ;;
    --project) PROJECT="$2"; shift 2 ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 64 ;;
  esac
done

command -v flutter  >/dev/null || { echo "flutter is not on PATH" >&2; exit 69; }
command -v firebase >/dev/null || { echo "the Firebase CLI is not installed: npm i -g firebase-tools" >&2; exit 69; }

if [ "$AUTH" = "firebase" ] && [ ! -f lib/firebase_options.dart ]; then
  echo "error: --auth firebase needs lib/firebase_options.dart" >&2
  echo "       generate it once with:  flutterfire configure --project=$PROJECT" >&2
  exit 78
fi

DEFINES=(--dart-define=BACKEND="$BACKEND" --dart-define=AUTH="$AUTH")
[ -n "$API" ]    && DEFINES+=(--dart-define=API_BASE="$API")
[ -n "$FHIR" ]   && DEFINES+=(--dart-define=FHIR_BASE="$FHIR")
[ -n "$EAI" ]    && DEFINES+=(--dart-define=EAI_BASE="$EAI")
[ -n "$DEVICE" ] && DEFINES+=(--dart-define=DEVICE_ID="$DEVICE")

echo "Building device simulator for the web (backend: $BACKEND, auth: $AUTH)..."
# --no-web-resources-cdn makes Flutter load the CanvasKit renderer from
# the copy it already bundles, instead of fetching it from gstatic.com at
# runtime. Without it, a campus or hospital network that blocks gstatic
# leaves the application showing a blank page with no explanation - and we
# are hosting that copy either way.
flutter build web --release --no-web-resources-cdn "${DEFINES[@]}"

echo "Deploying to $SITE..."
firebase deploy --only "hosting:$TARGET" --project "$PROJECT"

echo
echo "  https://$SITE.web.app"
