#!/usr/bin/env bash
# Creates the mini-hospital's PostgreSQL in Google Cloud, inside the same
# project as Firebase Hosting, and loads the schema and the fictive patients
# into one database per application.
#
#   ./infrastructure/cloud/provision_cloud_sql.sh
#   ./infrastructure/cloud/provision_cloud_sql.sh --schema-only
#
# Safe to re-run: every step checks for what it is about to create, and the
# schema and seed are themselves idempotent.
#
# WHAT THIS COSTS. Firebase has no PostgreSQL of its own - "Firebase
# PostgreSQL" is Cloud SQL underneath, whether you reach it through Data
# Connect or directly, as here. Cloud SQL is billed by the hour whether or not
# anyone is using it, so the project must be on the Blaze plan with billing
# enabled. This script asks for the smallest instance that is still a real
# managed PostgreSQL. Check current Cloud SQL pricing before running it, and
# see the "Turning it off" section in FIREBASE.md - a stopped instance bills
# only for its storage.
set -euo pipefail

PROJECT="${FIREBASE_PROJECT:-my-hospital-2026}"
REGION="${REGION:-europe-west1}"
INSTANCE="${INSTANCE:-mini-hospital-2026-sql}"
DB_USER="${DB_USER:-hospital}"
SECRET="${SECRET:-mini-hospital-db-password}"
TIER="${TIER:-db-f1-micro}"

DATABASES=(EHR_DB ADT_DB PHARM_DB EAI_DB DEV_DB)

SEED=1
[ "${1:-}" = "--schema-only" ] && SEED=0

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

command -v gcloud >/dev/null || {
  echo "gcloud is not installed: https://cloud.google.com/sdk/docs/install" >&2
  exit 69
}
command -v psql >/dev/null || {
  echo "psql is not installed (postgresql-client)" >&2
  exit 69
}

echo "Project:  $PROJECT"
echo "Region:   $REGION"
echo "Instance: $INSTANCE ($TIER)"
echo

# ---------------------------------------------------------------- services --
echo "Enabling the APIs this needs..."
gcloud services enable \
  sqladmin.googleapis.com \
  secretmanager.googleapis.com \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com \
  --project "$PROJECT"

# ---------------------------------------------------------------- password --
if gcloud secrets describe "$SECRET" --project "$PROJECT" >/dev/null 2>&1; then
  echo "Password secret $SECRET already exists, reusing it"
else
  echo "Creating the password secret $SECRET..."
  # Generated here and never printed: the only copies are Secret Manager and
  # the Cloud SQL user itself.
  #
  # Not `tr </dev/urandom | head -c 32`: head closes the pipe after 32 bytes,
  # tr dies of SIGPIPE, and `set -o pipefail` then fails the whole script.
  # Both of these read a bounded amount and exit on their own.
  if command -v openssl >/dev/null; then
    generated="$(openssl rand -hex 24)"
  else
    generated="$(LC_ALL=C head -c 24 /dev/urandom | od -An -tx1 | tr -d ' \n')"
  fi
  printf '%s' "$generated" |
    gcloud secrets create "$SECRET" --project "$PROJECT" --data-file=- \
      --replication-policy=automatic
  unset generated
fi
DB_PASSWORD="$(gcloud secrets versions access latest --secret "$SECRET" --project "$PROJECT")"

# ---------------------------------------------------------------- instance --
if gcloud sql instances describe "$INSTANCE" --project "$PROJECT" >/dev/null 2>&1; then
  echo "Instance $INSTANCE already exists"
else
  echo "Creating $INSTANCE - this takes several minutes..."
  # ZONAL rather than REGIONAL: no high availability, because a teaching
  # hospital that is down for ten minutes costs nobody anything, and HA
  # doubles the bill.
  gcloud sql instances create "$INSTANCE" \
    --project "$PROJECT" \
    --database-version=POSTGRES_16 \
    --region="$REGION" \
    --tier="$TIER" \
    --edition=ENTERPRISE \
    --availability-type=ZONAL \
    --storage-size=10GB \
    --storage-type=HDD \
    --storage-auto-increase \
    --no-backup
fi

CONNECTION_NAME="$(gcloud sql instances describe "$INSTANCE" \
  --project "$PROJECT" --format='value(connectionName)')"
echo "Connection name: $CONNECTION_NAME"

# -------------------------------------------------------------------- user --
if gcloud sql users list --instance "$INSTANCE" --project "$PROJECT" \
  --format='value(name)' | grep -qx "$DB_USER"; then
  echo "User $DB_USER already exists, resetting its password to the secret"
  gcloud sql users set-password "$DB_USER" --instance "$INSTANCE" \
    --project "$PROJECT" --password "$DB_PASSWORD"
else
  echo "Creating user $DB_USER..."
  gcloud sql users create "$DB_USER" --instance "$INSTANCE" \
    --project "$PROJECT" --password "$DB_PASSWORD"
fi

# --------------------------------------------------------------- databases --
for db in "${DATABASES[@]}"; do
  if gcloud sql databases describe "$db" --instance "$INSTANCE" \
    --project "$PROJECT" >/dev/null 2>&1; then
    echo "Database $db already exists"
  else
    echo "Creating database $db..."
    gcloud sql databases create "$db" --instance "$INSTANCE" --project "$PROJECT"
  fi
done

# The proxy authenticates with Application Default Credentials, which are a
# different thing from the credentials `gcloud auth login` gives the CLI.
# Check before starting it: otherwise its one-line complaint scrolls past
# between the waiting dots, and what you read instead is a wall of
# "connection refused" that says nothing about credentials.
if ! gcloud auth application-default print-access-token >/dev/null 2>&1; then
  echo >&2
  echo "error: the Cloud SQL Auth Proxy has no Application Default Credentials." >&2
  echo >&2
  echo "  These are separate from the ones gcloud itself uses, so being logged" >&2
  echo "  in is not enough. Run this once, then run this script again:" >&2
  echo >&2
  echo "    gcloud auth application-default login" >&2
  exit 77
fi

# ------------------------------------------------------------------- proxy --
# The instance has no public IP, so the schema is loaded through the Cloud SQL
# Auth Proxy: it authenticates with the caller's own gcloud credentials and
# presents the instance on 127.0.0.1, which lets db/apply.sh - the same script
# the local stack and CI use - run unchanged against it.
PROXY="${TMPDIR:-/tmp}/cloud-sql-proxy"
if [ ! -x "$PROXY" ]; then
  echo "Fetching the Cloud SQL Auth Proxy..."
  case "$(uname -s)/$(uname -m)" in
    Darwin/arm64) asset=darwin.arm64 ;;
    Darwin/*)     asset=darwin.amd64 ;;
    Linux/aarch64) asset=linux.arm64 ;;
    *)            asset=linux.amd64 ;;
  esac
  curl -fsSL -o "$PROXY" \
    "https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.14.1/cloud-sql-proxy.$asset"
  chmod +x "$PROXY"
fi

PROXY_PORT="${PROXY_PORT:-5433}"
PROXY_LOG="$(mktemp)"
"$PROXY" --port "$PROXY_PORT" "$CONNECTION_NAME" >"$PROXY_LOG" 2>&1 &
PROXY_PID=$!
trap 'kill "$PROXY_PID" 2>/dev/null || true; rm -f "$PROXY_LOG"' EXIT

echo -n "Waiting for the proxy on 127.0.0.1:$PROXY_PORT"
READY=0
for _ in $(seq 1 30); do
  # A proxy that has died will never be ready, and waiting the full minute
  # for it to prove that helps nobody.
  if ! kill -0 "$PROXY_PID" 2>/dev/null; then
    echo
    echo "error: the proxy exited. What it said:" >&2
    sed 's/^/  /' "$PROXY_LOG" >&2
    exit 78
  fi
  if PGPASSWORD="$DB_PASSWORD" psql -h 127.0.0.1 -p "$PROXY_PORT" \
    -U "$DB_USER" -d postgres -c 'SELECT 1' >/dev/null 2>&1; then
    echo " - ready"
    READY=1
    break
  fi
  echo -n .
  sleep 2
done

if [ "$READY" -eq 0 ]; then
  echo
  echo "error: the proxy never accepted a connection. What it said:" >&2
  sed 's/^/  /' "$PROXY_LOG" >&2
  exit 78
fi

# ------------------------------------------------------- schema and patients --
export PGHOST=127.0.0.1
export PGPORT="$PROXY_PORT"
export PGUSER="$DB_USER"
export PGPASSWORD="$DB_PASSWORD"

if [ "$SEED" -eq 1 ]; then
  "$HERE/db/apply.sh"
else
  "$HERE/db/apply.sh" --schema-only
fi

echo
echo "PostgreSQL is ready."
echo
echo "  instance         $INSTANCE"
echo "  connection name  $CONNECTION_NAME"
echo "  databases        ${DATABASES[*]}"
echo "  user             $DB_USER (password in Secret Manager: $SECRET)"
echo
echo "Next: ./infrastructure/cloud/deploy_api.sh"
