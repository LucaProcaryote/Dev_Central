# Infrastructure

The back end of Mini-Hospital 2026: five PostgreSQL databases, one API per
application, and the HAPI FHIR repository.

The Flutter applications are **not** in here. They run from their own
repositories, because a student needs hot reload far more than another
container.

## Start everything

```bash
docker compose up -d
docker compose logs -f          # HAPI takes ~3 minutes on first boot
```

| Service | URL | Database |
|---|---|---|
| EHR API | <http://localhost:8081> | `EHR_DB` |
| ADT API | <http://localhost:8082> | `ADT_DB` |
| PHARM API | <http://localhost:8083> | `PHARM_DB` |
| EAI API | <http://localhost:8084> | `EAI_DB` |
| Device API | <http://localhost:8085> | `DEV_DB` |
| PostgreSQL | `localhost:5432` | user `hospital`, password `hospital` |
| HAPI FHIR | <http://localhost:8080/fhir> | its own `hapi` database |

Check it came up:

```bash
for p in 8081 8082 8083 8084 8085; do curl -s localhost:$p/health; echo; done
```

Then run any application against it:

```bash
cd ../../EHR && flutter run -d chrome --dart-define=BACKEND=restApi
```

## Five databases, on purpose

Each application owns its own database. The schema is identical in all five;
each application writes only the tables its job requires, and the integration
flows keep the shared entities in step.

That is not a shortcut — it is how hospital IT actually works. Every system
keeps its own copy of the patient master and an ADT feed reconciles them. A
student who admits a patient in ADT and then cannot find them in the EHR has
just discovered why interface engines exist, which is the point of the course.

|  | Tables it owns |
|---|---|
| `EHR_DB` | patients, allergies, encounters, observations, prescriptions, clinical_notes |
| `ADT_DB` | patients, wards, rooms, beds, encounters, movements |
| `PHARM_DB` | patients, medications, prescriptions, dispenses, cabinets, stock_items |
| `EAI_DB` | integration_flows, integration_messages (+ patients, for the enricher) |
| `DEV_DB` | devices, observations, patients |

## The schema does real work

`db/schema.sql` is not a bag of nullable text columns. It enforces:

- a patient cannot be admitted twice at once *(partial unique index)*
- two patients cannot occupy one bed *(partial unique index)*
- an occupied bed must name its occupant, and a free bed must not
- a stay cannot end before it began; a finished stay has a discharge date
- a dispensed dose records when and by whom; a refused one records why
- stock cannot go negative; one drawer holds one product
- gender and patient language are restricted to their value sets

Every one of those is a bug the application layer could have shipped. Prove
they hold:

```bash
psql -h localhost -U hospital -d EHR_DB -v ON_ERROR_STOP=1 -f db/test_schema.sql
```

The test runs in a transaction and rolls back, so it is safe against a
database with data in it. Eighteen assertions: fourteen things the schema must
refuse, four it must allow.

The API turns those violations into something readable rather than passing the
driver's message through:

```
409  That patient is already admitted. Discharge the current stay first.
409  That bed is already occupied by another patient.
422  A stay cannot end before it began.
422  A refused dose must record why it was refused.
```

## Without Docker

If you have a PostgreSQL already:

```bash
PGHOST=localhost PGPORT=5432 PGUSER=hospital ./db/apply.sh
cd server && dart run bin/server.dart --app EHR --port 8081 --db-name EHR_DB
```

`apply.sh` is safe to re-run: it resets the hospital rather than duplicating
it. `--schema-only` skips the fictive patients.

## The seed data

`db/seed.sql` is **generated**, never hand-edited. Its source is the Dart seed
in `packages/hospital_core/lib/src/seed/`, and a test fails if the two drift
apart — otherwise a student switching `BACKEND=restApi` would find different
patients and reasonably conclude the software was broken.

```bash
cd ../packages/hospital_core
UPDATE_SEED_SQL=1 flutter test test/seed_sql_test.dart
```

Timestamps are written as `now() - interval '…'`, so the seeded hospital is
always as current as the in-memory one rather than frozen on the day it was
generated.

Everything in it is invented. The Belgian national register numbers carry
correctly computed check digits so format-validation exercises have something
honest to work on, but the numbers belong to nobody.

## The API

One binary, launched once per application — same code, five deployments, which
is how a hospital runs one vendor product for several departments.

The routes mirror `RestHospitalRepository` in `hospital_core` one for one. If
you can read that class you can read `server/lib/src/api.dart`, and adding an
endpoint means touching exactly those two files.

```bash
curl -s 'localhost:8081/patients?query=damme' | jq '.[0].family_name'
curl -s 'localhost:8081/patients/pat-008/latest-vitals' | jq 'length'
curl -s 'localhost:8081/beds?wardId=ward-icu&status=free' | jq 'length'
curl -s 'localhost:8084/messages' | jq '.[0].message_type'
```

`POST /messages` is the integration engine's inbox — the one route without a
repository twin. ADT and the device simulators post events to it. It stores
and acknowledges immediately: the sender must not wait for downstream
processing, and must not fail because a destination is down.

CORS is wide open on every service. The Flutter web applications are served
from a different origin and the browser would refuse every request otherwise.
That is right for a classroom laptop and wrong for anything else.

## Firebase Data Connect

`dataconnect/` is the cloud path: the same schema as GraphQL types, plus the
queries and mutations the applications need.

Data Connect is Firebase's PostgreSQL offering — managed Cloud SQL with a
generated typed API in front — and it **requires the Blaze plan**. The local
stack is the course default precisely so nobody has to enable billing to
attend a lab.

```bash
firebase deploy --only dataconnect --project my-hospital-2026
```

Two things there are worth showing students side by side with the SQL:

- The GraphQL schema and `db/schema.sql` describe the same tables and must be
  kept in step **by hand**. That is what a managed backend costs.
- There is no "admit patient" mutation. Data Connect generates one mutation
  per table, so a multi-table operation is composed on the client — exactly
  the transactional gap `AdtService` documents in the ADT application.

## Credentials

Every password in this directory is `hospital` or `hapi`. This holds fictive
data on a classroom network. Treat all of them as placeholders.
