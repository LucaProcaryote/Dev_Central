#!/usr/bin/env bash
# Deploys the API server to Cloud Run - one service per application, all five
# talking to the Cloud SQL instance provision_cloud_sql.sh created.
#
#   ./infrastructure/cloud/deploy_api.sh
#   ./infrastructure/cloud/deploy_api.sh EHR      # just one of them
#
# Run provision_cloud_sql.sh first. Prints the five URLs at the end; those are
# what the Flutter applications need as their API base.
set -euo pipefail

PROJECT="${FIREBASE_PROJECT:-my-hospital-2026}"
REGION="${REGION:-europe-west1}"
INSTANCE="${INSTANCE:-mini-hospital-2026-sql}"
DB_USER="${DB_USER:-hospital}"
SECRET="${SECRET:-mini-hospital-db-password}"
IMAGE="${IMAGE:-$REGION-docker.pkg.dev/$PROJECT/mini-hospital/api}"

# The administration API (account creation, roles) is mounted on exactly one
# of the five services - one door rather than five - and the portal's console
# talks to that one. Set ADMIN_APP=none to mount it nowhere.
ADMIN_APP="${ADMIN_APP:-EHR}"
FIREBASE_API_KEY="${FIREBASE_API_KEY:-}"

APPS=(EHR ADT PHARM EAI DEV)
[ $# -gt 0 ] && APPS=("$@")

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

command -v gcloud >/dev/null || { echo "gcloud is not installed" >&2; exit 69; }

CONNECTION_NAME="$(gcloud sql instances describe "$INSTANCE" \
  --project "$PROJECT" --format='value(connectionName)')" || {
  echo "error: instance $INSTANCE not found - run provision_cloud_sql.sh first" >&2
  exit 78
}

# ------------------------------------------------------------------- image --
if ! gcloud artifacts repositories describe mini-hospital \
  --location "$REGION" --project "$PROJECT" >/dev/null 2>&1; then
  echo "Creating the Artifact Registry repository..."
  gcloud artifacts repositories create mini-hospital \
    --repository-format=docker --location "$REGION" --project "$PROJECT" \
    --description="Mini-Hospital 2026 container images"
fi

echo "Building the API image..."
gcloud builds submit "$HERE/server" --tag "$IMAGE" --project "$PROJECT"

# ----------------------------------------------------------- admin identity --
# Writing a role means writing a custom claim, which needs a service account
# with Firebase Authentication Admin. The service uses its own identity for
# that - no key is issued, downloaded or stored anywhere.
if [ "$ADMIN_APP" != "none" ] && [ -n "$FIREBASE_API_KEY" ]; then
  PROJECT_NUMBER="$(gcloud projects describe "$PROJECT" --format='value(projectNumber)')"
  RUNTIME_SA="${RUNTIME_SA:-$PROJECT_NUMBER-compute@developer.gserviceaccount.com}"
  echo "Granting Firebase Authentication Admin to $RUNTIME_SA..."
  gcloud projects add-iam-policy-binding "$PROJECT" \
    --member "serviceAccount:$RUNTIME_SA" \
    --role roles/firebaseauth.admin \
    --condition=None >/dev/null
elif [ "$ADMIN_APP" != "none" ]; then
  echo
  echo "note: FIREBASE_API_KEY is not set, so no administration API will be"
  echo "      mounted. Re-run with the web API key from the Firebase console:"
  echo "        FIREBASE_API_KEY=AIza... ./infrastructure/cloud/deploy_api.sh"
  echo
  ADMIN_APP=none
fi

# --------------------------------------------------------- the five services --
# Cloud Run mounts the Cloud SQL socket under /cloudsql. The server treats a
# DB_HOST beginning with "/" as a socket directory, the same convention psql
# uses, so no proxy sidecar is needed.
SERVICE_ACCOUNT="${SERVICE_ACCOUNT:-}"
for app in "${APPS[@]}"; do
  service="mini-hospital-api-$(echo "$app" | tr '[:upper:]' '[:lower:]')"
  echo
  echo "=== $service ==="
  env_vars="APP=$app,DB_HOST=/cloudsql/$CONNECTION_NAME,DB_USER=$DB_USER"
  if [ "$app" = "$ADMIN_APP" ]; then
    env_vars="$env_vars,FIREBASE_PROJECT=$PROJECT,FIREBASE_API_KEY=$FIREBASE_API_KEY"
    echo "    (this one also serves /admin)"
  fi
  # shellcheck disable=SC2086
  gcloud run deploy "$service" \
    --project "$PROJECT" \
    --region "$REGION" \
    --image "$IMAGE" \
    --platform managed \
    --allow-unauthenticated \
    --add-cloudsql-instances "$CONNECTION_NAME" \
    --set-env-vars "$env_vars" \
    --set-secrets "DB_PASSWORD=$SECRET:latest" \
    --min-instances 0 \
    --max-instances 2 \
    --memory 512Mi \
    ${SERVICE_ACCOUNT:+--service-account "$SERVICE_ACCOUNT"}
done

echo
echo "API base URLs:"
for app in "${APPS[@]}"; do
  service="mini-hospital-api-$(echo "$app" | tr '[:upper:]' '[:lower:]')"
  url="$(gcloud run services describe "$service" --project "$PROJECT" \
    --region "$REGION" --format='value(status.url)')"
  printf '  %-6s %s\n' "$app" "$url"
done

cat <<'NEXT'

Point an application at its API without rebuilding anything:

  https://my-hospital-ehr.procaryote.com/?backend=restApi&api=<the EHR URL>

To make it the default for everyone, set the API_BASE repository variable in
each repository (Settings -> Secrets and variables -> Actions -> Variables)
and push: the deploy workflow compiles it in.

The administration console is the portal, pointed at the service that serves
/admin - the EHR one unless ADMIN_APP said otherwise:

  https://my-hospital-2026.web.app/?admin=<that URL>

Make it permanent by setting ADMIN_API_URL in the my-hospital repository.
NEXT
