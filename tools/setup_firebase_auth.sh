#!/usr/bin/env bash
# Creates the hospital's staff accounts in Firebase Authentication and gives
# each one its role.
#
#   ./tools/setup_firebase_auth.sh                 # create, then print the config
#   ./tools/setup_firebase_auth.sh --password X    # a password of your choosing
#   ./tools/setup_firebase_auth.sh --show-config   # only print the dart-defines
#
# Safe to re-run: an account that already exists is left alone and only its
# role claim is refreshed.
#
# Firebase owns identity here - email, password, session. It does not own
# *role*: that is a custom claim on the account, which is what
# FirebaseAuthService reads. A real hospital drives those claims from its HR
# directory; this script is the teaching stand-in for that.
#
# Requires: gcloud, authenticated as someone with Firebase Authentication
# Admin on the project. Enable Email/Password sign-in first, in the console
# under Authentication -> Sign-in method.
set -euo pipefail

PROJECT="${FIREBASE_PROJECT:-my-hospital-2026}"
PASSWORD="${STAFF_PASSWORD:-Hospital2026!}"
SHOW_CONFIG_ONLY=0

while [ $# -gt 0 ]; do
  case "$1" in
    --project)     PROJECT="$2"; shift 2 ;;
    --password)    PASSWORD="$2"; shift 2 ;;
    --show-config) SHOW_CONFIG_ONLY=1; shift ;;
    -h|--help)     sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 64 ;;
  esac
done

command -v gcloud >/dev/null || { echo "gcloud is not installed" >&2; exit 69; }
command -v python3 >/dev/null || { echo "python3 is not installed" >&2; exit 69; }

# The nine seeded staff, and the role each one signs in as. Keep in step with
# packages/hospital_core/lib/src/seed/seed_users.dart - the e-mail is the join.
STAFF=(
  "anne.dubois@mini-hospital.be:physician"
  "jan.peeters@mini-hospital.be:physician"
  "marie.lambert@mini-hospital.be:nurse"
  "sofie.declercq@mini-hospital.be:nurse"
  "paul.mertens@mini-hospital.be:pharmacist"
  "fatima.elamrani@mini-hospital.be:admissionClerk"
  "tom.vandenberg@mini-hospital.be:integrationEngineer"
  "lucas.moreau@mini-hospital.be:biomedicalTechnician"
  "student@mini-hospital.be:student"
)

TOKEN="$(gcloud auth print-access-token)"
IDENTITY="https://identitytoolkit.googleapis.com/v1/projects/$PROJECT"

post() { # endpoint, json  -> response body, never failing the script
  curl -sS -X POST "$IDENTITY/$1" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "$2" || true
}

json_field() { python3 -c "import json,sys
try: print(json.load(sys.stdin).get('$1',''))
except Exception: print('')"; }

if [ "$SHOW_CONFIG_ONLY" -eq 0 ]; then
  echo "Project: $PROJECT"
  echo "Creating ${#STAFF[@]} staff accounts..."
  echo

  for entry in "${STAFF[@]}"; do
    email="${entry%%:*}"
    role="${entry##*:}"
    printf '%-40s %-22s ' "$email" "$role"

    created="$(post accounts '{"email":"'"$email"'","password":"'"$PASSWORD"'","returnSecureToken":false}')"
    uid="$(printf '%s' "$created" | json_field localId)"

    if [ -z "$uid" ]; then
      # Already there. Look it up so the role can still be refreshed.
      found="$(post accounts:lookup '{"email":["'"$email"'"]}')"
      uid="$(printf '%s' "$found" | python3 -c "import json,sys
try: print(json.load(sys.stdin)['users'][0]['localId'])
except Exception: print('')")"
      state="exists"
    else
      state="created"
    fi

    if [ -z "$uid" ]; then
      echo "FAILED"
      echo "  $created" >&2
      continue
    fi

    # The claim FirebaseAuthService.defaultRoleResolver reads.
    post accounts:update \
      '{"localId":"'"$uid"'","customAttributes":"{\"role\":\"'"$role"'\"}"}' >/dev/null
    echo "$state"
  done

  echo
  echo "Password for every account: $PASSWORD"
  echo "Change it before anyone outside the course can reach these URLs."
  echo
fi

# ------------------------------------------------------------------ config --
echo "Register a Web app per application if you have not already:"
echo "  https://console.firebase.google.com/project/$PROJECT/settings/general"
echo
echo "Then set these repository variables in each application repository"
echo "(Settings -> Secrets and variables -> Actions -> Variables):"
echo
echo "  FIREBASE_API_KEY               the web app's apiKey"
echo "  FIREBASE_APP_ID                the web app's appId - DIFFERENT per app"
echo "  FIREBASE_MESSAGING_SENDER_ID   the project number, same for all"
echo
echo "The deploy workflow switches AUTH to firebase as soon as those three are"
echo "present. None of them is a secret: a web API key identifies the project,"
echo "it does not authorise anything. What protects the hospital is the sign-in"
echo "itself and the authorised-domains list."
