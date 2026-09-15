#!/usr/bin/env bash
# Deploys the MQTT broker the connected devices publish to.
#
#   ./infrastructure/cloud/deploy_mqtt.sh
#
# Prints the wss:// URL and the credentials at the end. Those are what the
# Flutter applications need as MQTT_URL, MQTT_USERNAME and MQTT_PASSWORD.
#
# Why a broker at all, when the simulators already POST their readings over
# HTTP: because a bedside monitor does not. MQTT is what the estate speaks -
# a topic tree, retained last values, and a last will that announces a device
# has gone quiet. None of those have an HTTP equivalent worth teaching.
set -euo pipefail

PROJECT="${FIREBASE_PROJECT:-my-hospital-2026}"
REGION="${REGION:-europe-west1}"
SERVICE="${SERVICE:-mini-hospital-mqtt}"
IMAGE="${IMAGE:-$REGION-docker.pkg.dev/$PROJECT/mini-hospital/mqtt}"
SECRET="${SECRET:-mini-hospital-mqtt-password}"
MQTT_USERNAME="${MQTT_USERNAME:-hospital}"

# Must match `listener` in mosquitto.conf. Mosquitto cannot read $PORT, so the
# number is fixed in two places and this is the second.
PORT=9001

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

command -v gcloud >/dev/null || { echo "gcloud is not installed" >&2; exit 69; }

echo "Project:  $PROJECT"
echo "Region:   $REGION"
echo "Service:  $SERVICE"
echo

gcloud services enable run.googleapis.com cloudbuild.googleapis.com \
  artifactregistry.googleapis.com secretmanager.googleapis.com \
  --project "$PROJECT"

# ------------------------------------------------------------------ secret --
if gcloud secrets describe "$SECRET" --project "$PROJECT" >/dev/null 2>&1; then
  echo "Password secret $SECRET already exists, reusing it"
else
  echo "Creating the password secret $SECRET..."
  # Generated rather than chosen: a broker reachable from the open internet
  # behind a password somebody typed is a broker behind no password.
  LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32 \
    | gcloud secrets create "$SECRET" --project "$PROJECT" --data-file=- \
      --replication-policy=automatic
fi

# ------------------------------------------------------------------- image --
if ! gcloud artifacts repositories describe mini-hospital \
  --location "$REGION" --project "$PROJECT" >/dev/null 2>&1; then
  echo "Creating the Artifact Registry repository..."
  gcloud artifacts repositories create mini-hospital \
    --repository-format=docker --location "$REGION" --project "$PROJECT" \
    --description="Mini-Hospital 2026 container images"
fi

echo "Building the broker image..."
gcloud builds submit "$HERE/mqtt" --tag "$IMAGE" --project "$PROJECT"

# -------------------------------------------------------- runtime identity --
PROJECT_NUMBER="$(gcloud projects describe "$PROJECT" --format='value(projectNumber)')"
RUNTIME_SA="$PROJECT_NUMBER-compute@developer.gserviceaccount.com"

gcloud secrets add-iam-policy-binding "$SECRET" \
  --project "$PROJECT" --member "serviceAccount:$RUNTIME_SA" \
  --role roles/secretmanager.secretAccessor >/dev/null
echo "Granted the runtime service account access to $SECRET"
sleep 20

# ------------------------------------------------------------------ deploy --
# --max-instances 1 is not a cost decision, it is a correctness one. A broker
# holds its subscriptions in memory; two instances would be two brokers, and a
# student subscribed to one would never see what another published to the
# other. --min-instances 1 keeps that one alive, because a broker that scales
# to zero drops every subscription it was holding.
#
# --no-cpu-throttling for the same reason the API needs it: a frozen instance
# cannot answer a keepalive, and the connections die quietly.
#
# --timeout is the cap on how long one request may last, and a WebSocket is
# one request. An hour is the maximum Cloud Run allows; the client reconnects
# after it, which the students will see in the connection log.
echo "Deploying $SERVICE..."
gcloud run deploy "$SERVICE" \
  --image "$IMAGE" \
  --project "$PROJECT" \
  --region "$REGION" \
  --platform managed \
  --allow-unauthenticated \
  --port "$PORT" \
  --memory 512Mi \
  --min-instances 1 \
  --max-instances 1 \
  --no-cpu-throttling \
  --timeout 3600 \
  --session-affinity \
  --set-env-vars "MQTT_USERNAME=$MQTT_USERNAME" \
  --set-secrets "MQTT_PASSWORD=$SECRET:latest"

URL="$(gcloud run services describe "$SERVICE" --project "$PROJECT" \
  --region "$REGION" --format='value(status.url)')"
WSS="${URL/https:\/\//wss://}"
PASSWORD="$(gcloud secrets versions access latest --secret "$SECRET" \
  --project "$PROJECT")"

cat <<EOF

Broker ready.

  MQTT_URL       $WSS
  MQTT_USERNAME  $MQTT_USERNAME
  MQTT_PASSWORD  $PASSWORD

Set those three as repository Variables in Dev_Central and EAI - the password
is a secret in the ordinary sense, but it is compiled into a web build and
therefore readable by anyone who opens the page. Treat it as what it is: a
lock on the front door of a teaching broker, not a credential.

Change it before the URLs circulate outside the course:

  gcloud secrets versions add $SECRET --project $PROJECT --data-file=-
  gcloud run services update $SERVICE --project $PROJECT --region $REGION \\
    --set-secrets MQTT_PASSWORD=$SECRET:latest

Check it is answering (a WebSocket upgrade, so a plain GET is rejected - that
is the broker working, not failing):

  curl -sS -o /dev/null -w '%{http_code}\\n' $URL

EOF
