#!/usr/bin/env bash
# Creates the five application databases and loads the schema and seed data
# into each of them.
#
#   ./db/apply.sh                       # against localhost:5432
#   PGHOST=... PGPORT=... ./db/apply.sh     # anywhere else
#   ./db/apply.sh --schema-only         # skip the fictive patients
#
# Safe to re-run: the schema uses CREATE TABLE IF NOT EXISTS and the seed
# truncates before inserting, so this resets the hospital rather than
# duplicating it.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export PGHOST="${PGHOST:-localhost}"
export PGPORT="${PGPORT:-5432}"
export PGUSER="${PGUSER:-hospital}"
export PGPASSWORD="${PGPASSWORD:-hospital}"
# CREATE TABLE IF NOT EXISTS reports every existing object as a NOTICE, which
# buries the useful output on a re-run.
export PGOPTIONS='--client-min-messages=warning'

SEED=1
[ "${1:-}" = "--schema-only" ] && SEED=0

DATABASES=(EHR_DB ADT_DB PHARM_DB EAI_DB DEV_DB)

echo "PostgreSQL at $PGHOST:$PGPORT as $PGUSER"

for db in "${DATABASES[@]}"; do
  echo
  echo "-- $db --"
  if psql -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname = '$db'" | grep -q 1; then
    echo "  database exists"
  else
    psql -d postgres -q -c "CREATE DATABASE \"$db\""
    echo "  database created"
  fi

  psql -d "$db" -q -v ON_ERROR_STOP=1 -f "$HERE/schema.sql"
  echo "  schema applied"

  if [ "$SEED" = "1" ]; then
    psql -d "$db" -q -v ON_ERROR_STOP=1 -f "$HERE/seed.sql"
    count=$(psql -d "$db" -tAc "SELECT count(*) FROM patients")
    echo "  seeded ($count patients)"
  fi
done

echo
echo "Done. Five databases ready."
