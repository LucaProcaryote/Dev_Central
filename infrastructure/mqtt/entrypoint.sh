#!/bin/sh
# Builds the password file from the environment, then runs the broker.
#
# Mosquitto wants a file of hashed credentials, and Secret Manager hands Cloud
# Run a plain string. Hashing here means the secret is never written into an
# image layer - which it would be if the file were baked in at build time.
set -eu

: "${MQTT_USERNAME:?MQTT_USERNAME is not set}"
: "${MQTT_PASSWORD:?MQTT_PASSWORD is not set}"

PASSWD=/mosquitto/config/passwd
printf '%s:%s\n' "$MQTT_USERNAME" "$MQTT_PASSWORD" > "$PASSWD"
mosquitto_passwd -U "$PASSWD"
chmod 600 "$PASSWD"

echo "mini-hospital MQTT broker: user $MQTT_USERNAME, websockets on 9001"
exec mosquitto -c /mosquitto/config/mosquitto.conf
