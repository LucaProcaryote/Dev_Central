# Firebase setup

The mini-hospital runs entirely without Firebase. This describes what to do
when you want real sign-in, and optionally PostgreSQL in the cloud.

Project: **`my-hospital-2026`**
(<https://console.firebase.google.com/project/my-hospital-2026/overview>)

---

## What Firebase is used for, and what it is not

| | |
|---|---|
| **Authentication** | Yes — real accounts, real passwords, real sessions. Works on the free Spark plan. |
| **The databases** | Optional. Firebase's PostgreSQL offering is **Data Connect** (managed Cloud SQL), which needs the paid Blaze plan. The local Docker stack is the course default so nobody has to enable billing to attend a lab. |
| **Firestore** | Not used. It is NoSQL, and a hospital-informatics course should show relational modelling. |

---

## 1. Authentication

### Enable it

In the Firebase console → **Build → Authentication → Get started** → enable
**Email/Password**. Leave everything else off.

### Create the staff accounts

The applications expect the same cast of characters demo mode uses, so that
switching between the two does not change who is on the ward.

```bash
gcloud auth login
cd Dev_Central
./tools/setup_firebase_auth.sh
```

That creates all nine and sets each one's role. It is safe to re-run: an
existing account is left alone and only its role is refreshed. `--password`
chooses the shared password instead of the default.

| E-mail | Name | Role |
|---|---|---|
| `anne.dubois@mini-hospital.be` | Dr. Anne Dubois | physician |
| `jan.peeters@mini-hospital.be` | Dr. Jan Peeters | physician |
| `marie.lambert@mini-hospital.be` | Marie Lambert | nurse |
| `sofie.declercq@mini-hospital.be` | Sofie De Clercq | nurse |
| `paul.mertens@mini-hospital.be` | Paul Mertens | pharmacist |
| `fatima.elamrani@mini-hospital.be` | Fatima El Amrani | admissionClerk |
| `tom.vandenberg@mini-hospital.be` | Tom Van den Berg | integrationEngineer |
| `lucas.moreau@mini-hospital.be` | Lucas Moreau | biomedicalTechnician |
| `student@mini-hospital.be` | Student | student |

**Change the shared password before these URLs are reachable by anyone outside
the course.** Nine known addresses behind one known password is a real door,
not a pretend one. Give each student their own account too — `student01@…`
through `student10@…`, role `student`, which can do everything.

The e-mail address is the join between Firebase and the seeded staff in
`packages/hospital_core/lib/src/seed/seed_users.dart`. Keep the two in step.

### Connect the applications

The project configuration arrives as `--dart-define`s, not through a generated
`firebase_options.dart`. That keeps the repository compilable for someone who
has never run `flutterfire configure` — which matters when ten students clone
it on the first morning — and it means one build can be pointed at a teaching
project or a throwaway one without regenerating a file.

Register a **Web app per application** in the console, under
[Project settings → General](https://console.firebase.google.com/project/my-hospital-2026/settings/general),
then read three values off each one:

| Value | Where it comes from | Same for all five? |
| --- | --- | --- |
| `FIREBASE_API_KEY` | the web app's `apiKey` | yes |
| `FIREBASE_APP_ID` | the web app's `appId` | **no — one per application** |
| `FIREBASE_MESSAGING_SENDER_ID` | the project number | yes |

Locally:

```bash
flutter run -d chrome \
  --dart-define=AUTH=firebase \
  --dart-define=FIREBASE_API_KEY=AIza… \
  --dart-define=FIREBASE_APP_ID=1:123456789:web:abc… \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=123456789
```

Hosted: set those three as **repository variables** in each application
repository (Settings → Secrets and variables → Actions → Variables) and push.
The deploy workflow switches `AUTH` to `firebase` on its own as soon as all
three are present — and warns, rather than half-working, if only some are.

The demo-account buttons disappear from the sign-in screen and the e-mail and
password fields become real.

**None of these three is a secret.** A Firebase web API key identifies the
project; it does not authorise anything on its own. What protects the hospital
is the sign-in itself, the authorised-domains list, and the rules on the data.
Storing them as *variables* rather than *secrets* is deliberate: it makes them
readable in the workflow log, which is where you want them when a build signs
in against the wrong project.

If `AUTH=firebase` is set without those values, the application stops on its
startup screen and names exactly which ones are missing, with a Retry button.
It does not crash.

### Roles

Firebase owns identity — e-mail, password, session. It does not own **role**.
`UserRole` comes from a custom claim called `role` on the account, which is
what `FirebaseAuthService.defaultRoleResolver` reads; `setup_firebase_auth.sh`
sets it. A real hospital would drive those claims from its HR directory, and
that difference is worth a minute of discussion with the students.

A user whose claim is missing or unreadable falls back to `student`, which is
the safe default in a teaching environment. The valid values are the names in
`UserRole` (`packages/hospital_core/lib/src/models/hospital_user.dart`).

### Authorised domains

Firebase Auth rejects sign-in from an origin it does not know. Under
**Authentication → Settings → Authorised domains**, `localhost` and the
project's own `.web.app` and `.firebaseapp.com` domains are there by default,
so the six hosted sites work with no action. Add any other host you serve from.

---

## 2. PostgreSQL in the cloud

Only if you want the hospital to outlive the laptop it was demonstrated on.
The local `docker-compose` stack is the course default precisely so nobody has
to enable billing to attend a lab.

**Firebase has no PostgreSQL of its own.** What is marketed as Firebase
PostgreSQL is Cloud SQL underneath, reached either through Data Connect or
directly. Both put a Cloud SQL instance in your project, and **both require
the Blaze plan with billing enabled.** Cloud SQL bills by the hour whether or
not anyone is connected.

We go at Cloud SQL directly rather than through Data Connect, for one reason
that matters clinically: Data Connect generates its own DDL from the GraphQL
schema, so the CHECK constraints and partial unique indexes in
`db/schema.sql` — the ones that make it impossible to put two patients in one
bed, or to give a patient two active encounters — would not survive the trip.
Those invariants belong in the database, not in application code that a
student can bypass. `dataconnect/` is kept as a worked example of the other
path; see the note at the end of this section.

### Create it

```bash
gcloud auth login
cd Dev_Central
./infrastructure/cloud/provision_cloud_sql.sh
```

That script is idempotent, and it:

1. enables the APIs (Cloud SQL Admin, Secret Manager, Cloud Run, Cloud Build,
   Artifact Registry);
2. generates a database password straight into Secret Manager — it is never
   printed and never written to disk;
3. creates the smallest real PostgreSQL 16 instance: shared core, zonal, 10 GB
   HDD, no high availability, no backups, in `europe-west1`;
4. creates the five databases — `EHR_DB`, `ADT_DB`, `PHARM_DB`, `EAI_DB`,
   `DEV_DB`;
5. runs `db/apply.sh` against each of them through the Cloud SQL Auth Proxy —
   the same schema and the same twenty fictive patients the local stack and CI
   use, so there is exactly one definition of the hospital.

Pass `--schema-only` to skip the patients.

### Put the API in front of it

```bash
./infrastructure/cloud/deploy_api.sh
```

Five Cloud Run services, one per application, all against the one instance. It
prints the five URLs.

The server reaches Cloud SQL over the **unix socket Cloud Run mounts** at
`/cloudsql/PROJECT:REGION:INSTANCE`, with no Auth Proxy sidecar: a `DB_HOST`
beginning with `/` is treated as a socket directory, the same convention
`psql` uses, and the socket file is `<dir>/.s.PGSQL.<port>`. The database
password arrives from Secret Manager as `DB_PASSWORD`; it is not baked into
the image and does not appear in the service description.

### Point the applications at it

Per visitor, with no rebuild:

```
https://my-hospital-2026-ehr.web.app/?backend=restApi&api=<the EHR Cloud Run URL>
```

As the default for everyone: set an `API_BASE` **repository variable** in each
repository (Settings → Secrets and variables → Actions → Variables) and push.
The deploy workflow compiles it in and switches the backend to `restApi`
automatically; with no such variable it keeps building the in-browser demo,
which is the right default for a page that cannot reach a student's localhost.

### Turning it off

Cloud SQL charges while the instance exists, running or not.

```bash
gcloud sql instances patch mini-hospital-2026-sql --activation-policy NEVER   # stop
gcloud sql instances patch mini-hospital-2026-sql --activation-policy ALWAYS  # start
```

A stopped instance bills only for its storage, so stopping it between labs is
worth doing. When the course is over, delete it outright:

```bash
gcloud sql instances delete mini-hospital-2026-sql
```

### The Data Connect path, if you want to show it

`infrastructure/dataconnect/` holds a schema and connector for Firebase Data
Connect. It is not what the scripts above use, and two things about it are
worth discussing with the students:

- `dataconnect/schema/schema.gql` and `db/schema.sql` describe the same tables
  and must be kept in step **by hand**. That is part of what a managed backend
  costs you.
- Data Connect generates one mutation per table, so there is no single "admit
  patient" operation — the three writes an admission implies are composed on
  the client. That is exactly the transactional gap `AdtService` documents in
  the ADT application, and a good place to talk about what a database
  transaction actually buys.

---

## 3. Hosting

Five applications, five URLs, one Firebase project. Everything needed is
already checked in: `firebase.json` and `.firebaserc` in each repository, a
deploy script, and a GitHub Actions workflow.

| Application | URL |
|---|---|
| EHR | `https://my-hospital-2026-ehr.web.app` |
| ADT | `https://my-hospital-2026-adt.web.app` |
| PHARM | `https://my-hospital-2026-pharm.web.app` |
| EAI | `https://my-hospital-2026-eai.web.app` |
| Devices | `https://my-hospital-2026-dev.web.app` |

### One-off setup

```bash
npm install -g firebase-tools
firebase login

cd Dev_Central
./tools/create_hosting_sites.sh
```

A Firebase project has one default site and any number of extra ones. The
mini-hospital uses five, so each application has its own URL and can be
redeployed without touching the others.

Site ids are globally unique across all of Firebase Hosting. If
`create_hosting_sites.sh` reports one as taken, pick another id and change it
in that repository's `.firebaserc` and in `tools/deploy_hosting.sh`.

### Deploy

All five, from a directory holding all five checkouts:

```bash
cd Dev_Central
./tools/deploy_all_hosting.sh
```

Or one at a time, from inside any repository:

```bash
cd EHR
./tools/deploy_hosting.sh
```

### What the hosted build talks to

**Nothing on localhost.** A page served from `web.app` cannot reach a database
on a student's laptop, so the deployed build uses the in-memory dataset by
default: every visitor gets their own complete hospital in their own browser,
with no infrastructure at all. For a class that is often exactly right — send
five links and start the lab.

Any of it can be redirected per visitor with a query string, without
rebuilding:

| Parameter | Example |
|---|---|
| `?device=` | `…-dev.web.app/?device=DEV3` |
| `?backend=` | `?backend=restApi` |
| `?api=` | `?api=https://lab-api.example` |
| `?fhir=` | `?fhir=https://fhir.example/fhir` |
| `?eai=` | `?eai=https://eai.example` |
| `?auth=` | `?auth=firebase` |

That is what makes one hosted device simulator serve ten students:

```
https://my-hospital-2026-dev.web.app/?device=DEV1     → student 1
https://my-hospital-2026-dev.web.app/?device=DEV2     → student 2
…
```

To compile a different default in instead:

```bash
./tools/deploy_hosting.sh --backend restApi --api https://your-api-host
./tools/deploy_hosting.sh --auth firebase        # needs firebase_options.dart
```

### Deploying from GitHub

Each repository has `.github/workflows/deploy-hosting.yml`, which publishes on
every push to `main` and can also be run by hand with a chosen backend and auth
mode.

It needs one repository secret, **`FIREBASE_SERVICE_ACCOUNT`**:

1. Google Cloud console → IAM & Admin → Service accounts, in the
   `my-hospital-2026` project.
2. Create one, give it the **Firebase Hosting Admin** role.
3. Keys → Add key → JSON.
4. Paste the whole file into the repository's
   Settings → Secrets and variables → Actions.

The same secret goes in all five repositories. `ci.yml` runs the analyser,
formatter and tests on every push and needs no secret at all.

### Two things the web build needs, and why

Both are already applied; this is so you know why they are there.

**CanvasKit is self-hosted.** `flutter build web` bundles the CanvasKit
renderer into `build/web/canvaskit/` — and then, by default, fetches it from
`https://www.gstatic.com/flutter-canvaskit/…` at runtime anyway. On a campus or
hospital network that blocks gstatic, the result is a blank white page with
nothing on screen to explain it. Every build here passes
`--no-web-resources-cdn`, which uses the bundled copy we are hosting regardless.

**The browser locale is normalised.** Some Linux desktops report a POSIX-style
locale such as `en-US@posix`. `Intl.Locale` rejects that, Flutter's engine does
not guard against it, and the application dies during start-up with
*"Incorrect locale information provided"* — again, a blank page. A short script
at the top of each `web/index.html` cleans the value before Flutter reads it.
Worth knowing about if you ever see a lab machine where one browser works and
another does not.

### Before exposing any of this publicly

**Every CORS setting in this project is wide open.** The API server sends
`Access-Control-Allow-Origin: *` and HAPI FHIR is configured the same way. That
is right for a classroom laptop and wrong for anything reachable from the
internet.

If you put the back end on a public host, narrow both first:

- `infrastructure/server/lib/src/api.dart` — the `_corsHeaders` map
- `infrastructure/docker-compose.yml` — `HAPI_FHIR_CORS_ALLOWED_ORIGIN_PATTERNS`

And add the hosting domains to Firebase Auth's authorised-domains list, or
sign-in will be rejected from them.

## Costs

| | Plan | Cost |
|---|---|---|
| Authentication for ~15 accounts | Spark (free) | none |
| Hosting the five web builds | Spark (free) | none within the free quota |
| Data Connect / Cloud SQL | Blaze | per-hour, while the instance exists |

Everything the course needs works on the free plan. Only the cloud database
requires billing, and the local Docker stack does the same job for nothing.
