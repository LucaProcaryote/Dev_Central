#!/usr/bin/env bash
# Builds the simulator once and serves ten copies of it, DEV1..DEV10, on ports
# 9001..9010. Useful when one machine has to stand in for the whole class -
# a demonstration, or a student who wants to watch several devices at once.
#
#   ./tools/run_fleet.sh
#   ./tools/run_fleet.sh --eai http://localhost:8084
#
# Stop everything with Ctrl-C.
set -euo pipefail

EAI_BASE="http://localhost:8084"
BACKEND="memory"
COUNT=10

while [ $# -gt 0 ]; do
  case "$1" in
    --eai)     EAI_BASE="$2"; shift 2 ;;
    --backend) BACKEND="$2";  shift 2 ;;
    --count)   COUNT="$2";    shift 2 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

command -v python3 >/dev/null || { echo "python3 is required to serve the builds" >&2; exit 1; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/build/fleet"
rm -rf "$OUT"
mkdir -p "$OUT"

PIDS=()
cleanup() {
  echo
  echo "Stopping ${#PIDS[@]} simulators…"
  for pid in "${PIDS[@]}"; do kill "$pid" 2>/dev/null || true; done
}
trap cleanup EXIT INT TERM

for i in $(seq 1 "$COUNT"); do
  device="DEV$i"
  port=$((9000 + i))
  echo "Building $device …"
  flutter build web --release \
    --dart-define=DEVICE_ID="$device" \
    --dart-define=EAI_BASE="$EAI_BASE" \
    --dart-define=BACKEND="$BACKEND" \
    --output "$OUT/$device" >/dev/null
  (cd "$OUT/$device" && python3 -m http.server "$port" >/dev/null 2>&1) &
  PIDS+=($!)
  echo "  $device  →  http://localhost:$port"
done

echo
echo "All $COUNT simulators are up. Ctrl-C to stop."
wait
