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
  echo "Creating the Artifact Registry repository…"
  gcloud artifacts repositories create mini-hospital \
    --repository-format=docker --location "$REGION" --project "$PROJECT" \
    --description="Mini-Hospital 2026 container images"
fi

echo "Building the API image…"
gcloud builds submit "$HERE/server" --tag "$IMAGE" --project "$PROJECT"

# --------------------------------------------------------- the five services --
# Cloud Run mounts the Cloud SQL socket under /cloudsql. The server treats a
# DB_HOST beginning with "/" as a socket directory, the same convention psql
# uses, so no proxy sidecar is needed.
SERVICE_ACCOUNT="${SERVICE_ACCOUNT:-}"
for app in "${APPS[@]}"; do
  service="mini-hospital-api-$(echo "$app" | tr '[:upper:]' '[:lower:]')"
  echo
  echo "═══ $service ═══"
  # shellcheck disable=SC2086
  gcloud run deploy "$service" \
    --project "$PROJECT" \
    --region "$REGION" \
    --image "$IMAGE" \
    --platform managed \
    --allow-unauthenticated \
    --add-cloudsql-instances "$CONNECTION_NAME" \
    --set-env-vars "APP=$app,DB_HOST=/cloudsql/$CONNECTION_NAME,DB_USER=$DB_USER" \
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

  https://my-hospital-2026-ehr.web.app/?backend=restApi&api=<the EHR URL>

To make it the default for everyone, set the API_BASE repository variable in
each repository (Settings -> Secrets and variables -> Actions -> Variables)
and push: the deploy workflow compiles it in.
NEXT
