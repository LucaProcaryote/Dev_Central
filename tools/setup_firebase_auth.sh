#!/usr/bin/env bash
# Creates and manages the hospital's accounts in Firebase Authentication,
# including the role each one signs in as.
#
#   ./tools/setup_firebase_auth.sh                        create the whole cast
#   ./tools/setup_firebase_auth.sh --password X           with your own password
#   ./tools/setup_firebase_auth.sh --list                 who exists, and as what
#   ./tools/setup_firebase_auth.sh --add EMAIL ROLE [PW]  one new account
#   ./tools/setup_firebase_auth.sh --set-role EMAIL ROLE  change someone's role
#   ./tools/setup_firebase_auth.sh --reset-password EMAIL PW
#   ./tools/setup_firebase_auth.sh --delete EMAIL
#   ./tools/setup_firebase_auth.sh --show-config          only print the defines
#
# Safe to re-run: an account that already exists is left alone and only its
# role claim is refreshed.
#
# This is the bootstrap. It is how the FIRST administrator comes into being,
# because the administration console in the portal will only talk to someone
# who is already an administrator - and something has to break that circle.
# After that, day-to-day account work is easier in the console.
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
ACTION=seed

# The roles an account may hold. Same list as UserRole in hospital_core and as
# AdminApi.defaultRoles in the server.
ROLES="physician nurse pharmacist admissionClerk integrationEngineer biomedicalTechnician student admin"

# The seeded cast, and the role each one signs in as. Keep in step with
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
  "admin@mini-hospital.be:admin"
)

ARG_EMAIL=""
ARG_ROLE=""
ARG_PASSWORD=""

while [ $# -gt 0 ]; do
  case "$1" in
    --project)     PROJECT="$2"; shift 2 ;;
    --password)    PASSWORD="$2"; shift 2 ;;
    --show-config) ACTION=config; shift ;;
    --list)        ACTION=list; shift ;;
    --add)
      ACTION=add
      ARG_EMAIL="${2:-}"; ARG_ROLE="${3:-}"; ARG_PASSWORD="${4:-}"
      [ -n "$ARG_EMAIL" ] && [ -n "$ARG_ROLE" ] || {
        echo "usage: --add EMAIL ROLE [PASSWORD]" >&2; exit 64; }
      if [ -n "$ARG_PASSWORD" ]; then shift 4; else shift 3; fi
      ;;
    --set-role)
      ACTION=set-role
      ARG_EMAIL="${2:-}"; ARG_ROLE="${3:-}"
      [ -n "$ARG_EMAIL" ] && [ -n "$ARG_ROLE" ] || {
        echo "usage: --set-role EMAIL ROLE" >&2; exit 64; }
      shift 3 ;;
    --reset-password)
      ACTION=reset-password
      ARG_EMAIL="${2:-}"; ARG_PASSWORD="${3:-}"
      [ -n "$ARG_EMAIL" ] && [ -n "$ARG_PASSWORD" ] || {
        echo "usage: --reset-password EMAIL PASSWORD" >&2; exit 64; }
      shift 3 ;;
    --delete)
      ACTION=delete
      ARG_EMAIL="${2:-}"
      [ -n "$ARG_EMAIL" ] || { echo "usage: --delete EMAIL" >&2; exit 64; }
      shift 2 ;;
    -h|--help)     sed -n '2,27p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 64 ;;
  esac
done

command -v gcloud >/dev/null || { echo "gcloud is not installed" >&2; exit 69; }
command -v python3 >/dev/null || { echo "python3 is not installed" >&2; exit 69; }

TOKEN="$(gcloud auth print-access-token)"
IDENTITY="https://identitytoolkit.googleapis.com/v1/projects/$PROJECT"

# x-goog-user-project is not optional here. A token from
# `gcloud auth print-access-token` is a *user* credential with no project
# attached, so without this header Identity Toolkit bills the call to Google's
# own gcloud client project (32555940559), where the API is of course not
# enabled - and the 403 that comes back talks about quota projects rather than
# about this hospital, which is thoroughly confusing.
post() { # endpoint, json  -> response body, never failing the script
  curl -sS -X POST "$IDENTITY/$1" \
    -H "Authorization: Bearer $TOKEN" \
    -H "x-goog-user-project: $PROJECT" \
    -H "Content-Type: application/json" \
    -d "$2" || true
}

error_of() { python3 -c "import json,sys
try: print(json.load(sys.stdin)['error']['message'])
except Exception: print('')"; }

# One call before anything else, so a refusal is reported once, in full, with
# what to do about it - rather than nine times as 'FAILED', or worse, as an
# empty account list that reads like 'there is nobody here'.
preflight() {
  message="$(post accounts:query '{}' | error_of)"
  [ -z "$message" ] && return 0

  echo "The Firebase Authentication API refused the call." >&2
  echo >&2
  echo "  $message" >&2
  echo >&2
  case "$message" in
    *"has not been used"*|*SERVICE_DISABLED*|*"is disabled"*)
      echo "Enable it once for this project, then re-run:" >&2
      echo "  gcloud services enable identitytoolkit.googleapis.com --project $PROJECT" >&2
      echo >&2
      echo "It is also enabled for you the moment you turn on Email/Password" >&2
      echo "sign-in in the console, under Authentication -> Sign-in method." >&2 ;;
    *"quota project"*)
      echo "Your gcloud credential has no project attached. Either:" >&2
      echo "  gcloud config set project $PROJECT" >&2
      echo "  gcloud auth application-default set-quota-project $PROJECT" >&2 ;;
    *PERMISSION_DENIED*|*permission*|*Permission*)
      echo "The account you are logged in as needs Firebase Authentication" >&2
      echo "Admin on $PROJECT. Check who that is with:" >&2
      echo "  gcloud auth list" >&2 ;;
  esac
  exit 77
}

json_field() { python3 -c "import json,sys
try: print(json.load(sys.stdin).get('$1',''))
except Exception: print('')"; }

uid_of() { # email -> uid, empty when there is no such account
  post accounts:lookup '{"email":["'"$1"'"]}' | python3 -c "import json,sys
try: print(json.load(sys.stdin)['users'][0]['localId'])
except Exception: print('')"
}

check_role() { # role -> exits unless it is one the applications know
  for known in $ROLES; do
    [ "$1" = "$known" ] && return 0
  done
  echo "unknown role: $1" >&2
  echo "  one of: $ROLES" >&2
  exit 64
}

set_role() { # uid, role
  post accounts:update \
    '{"localId":"'"$1"'","customAttributes":"{\"role\":\"'"$2"'\"}"}' >/dev/null
}

create_or_update() { # email, role, password -> prints what happened
  created="$(post accounts '{"email":"'"$1"'","password":"'"$3"'","returnSecureToken":false}')"
  uid="$(printf '%s' "$created" | json_field localId)"
  if [ -n "$uid" ]; then
    state="created"
  else
    uid="$(uid_of "$1")"
    state="exists"
  fi
  if [ -z "$uid" ]; then
    echo "FAILED"
    echo "  $(printf '%s' "$created" | error_of)" >&2
    return 1
  fi
  set_role "$uid" "$2"
  echo "$state"
}

case "$ACTION" in
  list)
    preflight
    echo "Accounts in $PROJECT:"
    echo
    post accounts:query '{}' | python3 -c "
import json,sys
try:
    users = json.load(sys.stdin).get('userInfo', [])
except Exception:
    users = []
if not users:
    print('  (none - run the script with no arguments to create them)')
for u in sorted(users, key=lambda x: x.get('email', '')):
    try:
        role = json.loads(u.get('customAttributes', '{}')).get('role', '')
    except Exception:
        role = '?'
    flag = ' [disabled]' if u.get('disabled') else ''
    print('  %-40s %-22s %s%s' % (u.get('email',''), role or '(none = student)', u.get('localId',''), flag))
"
    exit 0 ;;

  add)
    preflight
    check_role "$ARG_ROLE"
    [ -n "$ARG_PASSWORD" ] || ARG_PASSWORD="$PASSWORD"
    printf '%-40s %-22s ' "$ARG_EMAIL" "$ARG_ROLE"
    create_or_update "$ARG_EMAIL" "$ARG_ROLE" "$ARG_PASSWORD"
    exit 0 ;;

  set-role)
    preflight
    check_role "$ARG_ROLE"
    uid="$(uid_of "$ARG_EMAIL")"
    [ -n "$uid" ] || { echo "no such account: $ARG_EMAIL" >&2; exit 78; }
    set_role "$uid" "$ARG_ROLE"
    echo "$ARG_EMAIL is now $ARG_ROLE"
    echo "The change reaches the applications when the token refreshes, which"
    echo "means signing out and back in."
    exit 0 ;;

  reset-password)
    preflight
    uid="$(uid_of "$ARG_EMAIL")"
    [ -n "$uid" ] || { echo "no such account: $ARG_EMAIL" >&2; exit 78; }
    post accounts:update '{"localId":"'"$uid"'","password":"'"$ARG_PASSWORD"'"}' >/dev/null
    echo "password reset for $ARG_EMAIL"
    exit 0 ;;

  delete)
    preflight
    uid="$(uid_of "$ARG_EMAIL")"
    [ -n "$uid" ] || { echo "no such account: $ARG_EMAIL" >&2; exit 78; }
    post accounts:delete '{"localId":"'"$uid"'"}' >/dev/null
    echo "deleted $ARG_EMAIL"
    exit 0 ;;

  seed)
    preflight
    echo "Project: $PROJECT"
    echo "Creating ${#STAFF[@]} accounts..."
    echo

    for entry in "${STAFF[@]}"; do
      email="${entry%%:*}"
      role="${entry##*:}"
      printf '%-40s %-22s ' "$email" "$role"
      create_or_update "$email" "$role" "$PASSWORD" || true
    done

    echo
    echo "Password for every account: $PASSWORD"
    echo "Change it before anyone outside the course can reach these URLs."
    echo
    echo "admin@mini-hospital.be is the administrator. Signed in as that"
    echo "account, the portal shows an Administration page where the rest of"
    echo "the accounts can be managed without this script."
    echo
    ;;
esac

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
