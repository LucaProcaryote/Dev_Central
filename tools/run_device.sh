#!/usr/bin/env bash
# Runs one device simulator.
#
#   ./tools/run_device.sh 3                     # DEV3, in Chrome, demo data
#   ./tools/run_device.sh 3 --eai http://host:8084
#   PORT=9003 ./tools/run_device.sh 3           # fixed port, for a shared laptop
#
# Each student runs a different number. The ten simulators between them cover
# every vital sign the record can display.
set -euo pipefail

NUMBER="${1:-1}"
shift || true

EAI_BASE="http://localhost:8084"
BACKEND="memory"
DEVICE="DEV${NUMBER}"

while [ $# -gt 0 ]; do
  case "$1" in
    --eai)     EAI_BASE="$2"; shift 2 ;;
    --backend) BACKEND="$2";  shift 2 ;;
    --device)  DEVICE="$2";   shift 2 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

if ! [[ "$NUMBER" =~ ^([1-9]|10)$ ]] && [ "$DEVICE" = "DEV${NUMBER}" ]; then
  echo "error: device number must be 1..10 (got '$NUMBER')" >&2
  exit 1
fi

ARGS=(
  -d chrome
  --dart-define=DEVICE_ID="$DEVICE"
  --dart-define=EAI_BASE="$EAI_BASE"
  --dart-define=BACKEND="$BACKEND"
)
[ -n "${PORT:-}" ] && ARGS+=(--web-port "$PORT")

echo "Starting $DEVICE  (backend: $BACKEND, engine: $EAI_BASE)"
exec flutter run "${ARGS[@]}"
