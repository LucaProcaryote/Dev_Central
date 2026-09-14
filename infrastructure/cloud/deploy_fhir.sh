#!/usr/bin/env bash
# Deploys the HAPI FHIR server to Cloud Run, beside the five application APIs.
#
#   FIREBASE_PROJECT=my-hospital-2026 ./infrastructure/cloud/deploy_fhir.sh
#
# Run provision_cloud_sql.sh first: this reuses that instance, adding one more
# database for HAPI to keep its resources in.
#
# WHAT THIS IS. The same hapiproject/hapi image the classroom compose stack
# runs, with the same settings, so a student who has read fhir-server/ knows
# exactly what is in front of them. It is a real R4 JPA server: proper search
# parameters, _include, history, validation, a capability statement.
#
# WHAT IT COSTS. A Java server wants far more memory than our Dart binaries -
# 2 GiB against 512 MiB - and it is slow to start. With MIN_INSTANCES=0 it
# costs nothing while nobody is using it, and the first request after an idle
# period waits about a minute for it to wake. Set MIN_INSTANCES=1 for a
# lecture, and back to 0 afterwards; that is the whole trade.
set -euo pipefail

PROJECT="${FIREBASE_PROJECT:-my-hospital-2026}"
REGION="${REGION:-europe-west1}"
INSTANCE="${INSTANCE:-mini-hospital-2026-sql}"
DB_USER="${DB_USER:-hospital}"
DB_NAME="${DB_NAME:-FHIR_DB}"
SECRET="${SECRET:-mini-hospital-db-password}"
SERVICE="${SERVICE:-mini-hospital-fhir}"
HAPI_IMAGE="${HAPI_IMAGE:-hapiproject/hapi:v7.4.0}"
PROXY_IMAGE="${PROXY_IMAGE:-gcr.io/cloud-sql-connectors/cloud-sql-proxy:2.14.1}"
MIN_INSTANCES="${MIN_INSTANCES:-0}"

command -v gcloud >/dev/null || { echo "gcloud is not installed" >&2; exit 69; }

CONNECTION_NAME="$(gcloud sql instances describe "$INSTANCE" \
  --project "$PROJECT" --format='value(connectionName)')" || {
  echo "error: instance $INSTANCE not found - run provision_cloud_sql.sh first" >&2
  exit 78
}
PROJECT_NUMBER="$(gcloud projects describe "$PROJECT" --format='value(projectNumber)')"
RUNTIME_SA="${RUNTIME_SA:-$PROJECT_NUMBER-compute@developer.gserviceaccount.com}"

# Cloud Run publishes a service at a name derived from the service, the project
# number and the region, so the public address is knowable before the first
# deploy - which matters because HAPI has to be told its own address, and it
# puts that address into every Bundle it returns.
BASE_URL="https://$SERVICE-$PROJECT_NUMBER.$REGION.run.app"

echo "Project:  $PROJECT"
echo "Service:  $SERVICE"
echo "Database: $DB_NAME on $INSTANCE"
echo "Address:  $BASE_URL/fhir"
echo

# ------------------------------------------------------------------- database --
# Deliberately not in provision_cloud_sql.sh's list: that script applies the
# hospital schema and the fictive patients to every database it knows about,
# and HAPI builds and owns its own schema. The two must not meet.
if gcloud sql databases describe "$DB_NAME" --instance "$INSTANCE" \
  --project "$PROJECT" >/dev/null 2>&1; then
  echo "Database $DB_NAME already exists"
else
  echo "Creating database $DB_NAME..."
  gcloud sql databases create "$DB_NAME" --instance "$INSTANCE" --project "$PROJECT"
fi

# ------------------------------------------------------------------- identity --
echo "Granting $RUNTIME_SA what the proxy needs..."
gcloud secrets add-iam-policy-binding "$SECRET" --project "$PROJECT" \
  --member "serviceAccount:$RUNTIME_SA" \
  --role roles/secretmanager.secretAccessor >/dev/null
gcloud projects add-iam-policy-binding "$PROJECT" \
  --member "serviceAccount:$RUNTIME_SA" \
  --role roles/cloudsql.client \
  --condition=None >/dev/null

# -------------------------------------------------------------------- service --
# The settings are the ones in fhir-server/docker-compose.yml, so the hosted
# server and the classroom one behave identically. The differences are the
# three that have to differ: where the database is, what the server calls
# itself, and how long Cloud Run should wait for a Java process to boot.
#
# HAPI builds its schema on first boot and that takes minutes. If the start-up
# probe gives up, run this script again: the schema is in Cloud SQL by then and
# the second boot is quick.
ENV_VARS="SPRING_DATASOURCE_URL=jdbc:postgresql://127.0.0.1:5432/$DB_NAME"
ENV_VARS="$ENV_VARS,SPRING_DATASOURCE_USERNAME=$DB_USER"
ENV_VARS="$ENV_VARS,SPRING_DATASOURCE_DRIVERCLASSNAME=org.postgresql.Driver"
ENV_VARS="$ENV_VARS,SPRING_JPA_PROPERTIES_HIBERNATE_DIALECT=ca.uhn.fhir.jpa.model.dialect.HapiFhirPostgres94Dialect"
ENV_VARS="$ENV_VARS,HAPI_FHIR_FHIR_VERSION=R4"
ENV_VARS="$ENV_VARS,HAPI_FHIR_SERVER_ADDRESS=$BASE_URL/fhir"
ENV_VARS="$ENV_VARS,HAPI_FHIR_ALLOW_EXTERNAL_REFERENCES=true"
ENV_VARS="$ENV_VARS,HAPI_FHIR_ENFORCE_REFERENTIAL_INTEGRITY_ON_WRITE=false"
ENV_VARS="$ENV_VARS,HAPI_FHIR_ENFORCE_REFERENTIAL_INTEGRITY_ON_DELETE=false"
ENV_VARS="$ENV_VARS,HAPI_FHIR_ALLOW_MULTIPLE_DELETE=true"
ENV_VARS="$ENV_VARS,HAPI_FHIR_REUSE_CACHED_SEARCH_RESULTS_MILLIS=0"
ENV_VARS="$ENV_VARS,HAPI_FHIR_DEFAULT_PAGE_SIZE=50"
ENV_VARS="$ENV_VARS,HAPI_FHIR_MAX_PAGE_SIZE=200"
ENV_VARS="$ENV_VARS,HAPI_FHIR_ADVANCED_HSEARCH_INDEXING=false"
ENV_VARS="$ENV_VARS,HAPI_FHIR_CORS_ALLOWED_ORIGIN_PATTERNS=*"
ENV_VARS="$ENV_VARS,HAPI_FHIR_CORS_ALLOW_CREDENTIALS=false"

echo
echo "Deploying $SERVICE - the first boot builds the schema and is slow..."
gcloud run deploy "$SERVICE" \
  --project "$PROJECT" \
  --region "$REGION" \
  --platform managed \
  --allow-unauthenticated \
  --min-instances "$MIN_INSTANCES" \
  --max-instances 2 \
  --timeout 300 \
  --no-cpu-throttling \
  --container hapi \
    --image "$HAPI_IMAGE" \
    --port 8080 \
    --memory 2Gi \
    --set-env-vars "$ENV_VARS" \
    --set-secrets "SPRING_DATASOURCE_PASSWORD=$SECRET:latest" \
    --startup-probe "httpGet.path=/fhir/metadata,httpGet.port=8080,initialDelaySeconds=30,periodSeconds=10,timeoutSeconds=5,failureThreshold=24" \
  --container sql-proxy \
    --image "$PROXY_IMAGE" \
    --memory 256Mi \
    --args="--structured-logs,--port=5432,$CONNECTION_NAME"

ACTUAL="$(gcloud run services describe "$SERVICE" --project "$PROJECT" \
  --region "$REGION" --format='value(status.url)')"
if [ "$ACTUAL" != "$BASE_URL" ]; then
  echo
  echo "note: Cloud Run published $ACTUAL, not the $BASE_URL this was"
  echo "      configured with. HAPI will report the wrong address in its"
  echo "      Bundles. Re-run with SERVICE_ADDRESS handling adjusted."
fi

cat <<NEXT

FHIR endpoint: $BASE_URL/fhir
Capability:    $BASE_URL/fhir/metadata
Web console:   $BASE_URL

Point the EAI application at it without rebuilding anything:

  https://my-hospital-eai.procaryote.com/?fhir=$BASE_URL/fhir

To make it the default, set FHIR_BASE to that URL as a repository variable in
the EAI repository and push.

The first request after an idle period waits for the server to wake, which for
a Java process is about a minute. MIN_INSTANCES=1 keeps one warm for a lecture
and costs accordingly; 0 is the default and costs nothing while unused.
NEXT
