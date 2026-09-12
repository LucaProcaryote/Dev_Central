#!/bin/bash
# Runs once, on the PostgreSQL container's first boot, before the SQL files
# beside it. Creates the five application databases and loads the schema and
# seed into each - the official image only applies the SQL files to
# POSTGRES_DB, so the multi-database case has to be scripted.
set -euo pipefail

for db in EHR_DB ADT_DB PHARM_DB EAI_DB DEV_DB; do
  echo "Creating $db"
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres \
    -c "CREATE DATABASE \"$db\""
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$db" \
    -f /docker-entrypoint-initdb.d/schema.sql
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$db" \
    -f /docker-entrypoint-initdb.d/seed.sql
  echo "  $db ready"
done
