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

That creates all ten and sets each one's role. It is safe to re-run: an
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
| `admin@mini-hospital.be` | Hospital Administrator | **admin** |

**Change the shared password before these URLs are reachable by anyone outside
the course.** Ten known addresses behind one known password is a real door,
not a pretend one — and one of them is the administrator. Give that one a
password of its own straight away:

```bash
./tools/setup_firebase_auth.sh --reset-password admin@mini-hospital.be 'something long'
```
 Give each student their own account too — `student01@…`
through `student10@…`, role `student`, which can do everything.

The e-mail address is the join between Firebase and the seeded staff in
`packages/hospital_core/lib/src/seed/seed_users.dart`. Keep the two in step.

#### If it says something about a quota project

```
The identitytoolkit.googleapis.com API requires a quota project, which is not
set by default ... consumer: projects/32555940559
```

That project number is not yours — it is Google's own gcloud client. A token
from `gcloud auth print-access-token` is a *user* credential with no project
attached, so the call gets billed to gcloud's project instead of to
`my-hospital-2026`, where it is naturally not enabled. The script now sends
`x-goog-user-project` on every call, which fixes it; if you hit this from your
own `curl`, add the same header, or:

```bash
gcloud config set project my-hospital-2026
gcloud auth application-default set-quota-project my-hospital-2026
```

The script makes one probe call before doing anything and prints the refusal in
full, once, with the remedy — including the case where the API is genuinely off
(`gcloud services enable identitytoolkit.googleapis.com --project my-hospital-2026`,
though turning on Email/Password sign-in in the console does it for you).

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
`UserRole` (`packages/hospital_core/lib/src/models/hospital_user.dart`):

`physician`, `nurse`, `pharmacist`, `admissionClerk`, `integrationEngineer`,
`biomedicalTechnician`, `student`, `admin`.

`admin` is the only role that can manage accounts, and it is deliberately the
only one with **no clinical rights at all** — it cannot prescribe, dispense,
admit or write notes. Being able to hand out every permission is not the same
as holding them, and keeping the two apart is worth pointing out to the
students. `student` is the opposite: every clinical right, so the exercises
work, and no way to promote itself.

### Administrators, and where accounts come from

There are two ways to create an account, and they are for different moments.

**The script is the bootstrap.** It is how the *first* administrator comes
into being, because the console will only talk to somebody who is already an
administrator — and something has to break that circle. It also does the bulk
work at the start of a course, where ten identical student accounts are one
loop rather than ten dialogs.

```bash
./tools/setup_firebase_auth.sh --list                          # who exists, and as what
./tools/setup_firebase_auth.sh --add student01@mini-hospital.be student
./tools/setup_firebase_auth.sh --set-role tom.vandenberg@mini-hospital.be admin
./tools/setup_firebase_auth.sh --reset-password student01@mini-hospital.be 'new one'
./tools/setup_firebase_auth.sh --delete student01@mini-hospital.be
```

**The console is for everything after that.** The portal
(`my-hospital-2026.web.app`) has an **Administration** page: sign in as an
account whose role is `admin` and it lists every account, with its role, its
last sign-in and whether it is disabled. From there you can create an account,
change a role, reset a password, disable someone for the afternoon, or delete
them.

#### Why the console needs a server

Setting a role means writing a custom claim, and custom claims can only be
written with service-account credentials. Those cannot go into a Flutter web
build — every byte of it is downloadable — so the console does not talk to
Firebase directly. It asks `/admin` on the API server, carrying the
administrator's own Firebase ID token; the server hands that token to Google
to be checked, confirms the account's role really is `admin`, and only then
uses its own Cloud Run identity to make the change.

Consequences worth knowing:

* **The console does nothing in demo mode.** A demo session is a Dart object
  in the browser; a server that trusted it would be trusting the browser.
* **No key is issued or stored anywhere.** On Cloud Run the service uses the
  identity it already runs as. `deploy_api.sh` grants that identity
  `roles/firebaseauth.admin` and nothing else.
* **`/admin` is mounted on one service only** — the EHR API unless
  `ADMIN_APP` said otherwise. One door rather than five.
* **Nobody can demote, disable or delete their own account.** The console
  greys those out and the server refuses them anyway. Locking the last
  administrator out is the classic way to lose an installation.

#### Turning the console on

`deploy_api.sh` mounts `/admin` when it is given the web API key:

```bash
FIREBASE_API_KEY=AIza... ./infrastructure/cloud/deploy_api.sh
```

Then point the portal at that service. Per visitor, for a quick look:

```
https://my-hospital-2026.web.app/?admin=https://mini-hospital-api-ehr-xxxx.run.app
```

Permanently: set `ADMIN_API_URL` to the same URL as a repository variable in
`my-hospital`, along with `FIREBASE_API_KEY`, `FIREBASE_APP_ID`,
`FIREBASE_MESSAGING_SENDER_ID` and `FIREBASE_PROJECT_ID` — the console signs
the administrator in before it calls anything, so the portal needs the
Firebase values too. Without `ADMIN_API_URL` the page loads and explains what
is missing rather than showing buttons that cannot work.

Running it locally against the classroom stack:

```bash
export GOOGLE_ACCESS_TOKEN=$(gcloud auth print-access-token)
cd infrastructure/server
dart run bin/server.dart --app EHR \
  --firebase-project my-hospital-2026 --firebase-api-key AIza...
# then open the portal with ?admin=http://localhost:8081
```

A role change reaches the applications when the ID token refreshes, which in
practice means the user signs out and back in.

### Authorised domains

Firebase Auth rejects sign-in from an origin it does not know. Under
**Authentication -> Settings -> Authorised domains**, `localhost` and the
project's own `.web.app` and `.firebaseapp.com` domains are there by default.

**The five `procaryote.com` domains are not**, and must be added by hand:

```
my-hospital-ehr.procaryote.com
my-hospital-adt.procaryote.com
my-hospital-pharm.procaryote.com
my-hospital-eai.procaryote.com
my-hospital-dev.procaryote.com
```

Miss this and sign-in works on the `.web.app` address and fails on the custom
one, with an error that never mentions domains - a genuinely confusing hour if
you are not expecting it.

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

### When something is wrong

`/ping` touches nothing and answers `pong`. It exists to settle one question
before any other: is the server stuck, or is the database stuck?

| | |
| --- | --- |
| `/ping` answers, `/health` says `degraded` | the API is fine; the database is not |
| `/ping` answers, `/health` says `ok` | everything works |
| `/ping` does not answer | the instance is saturated or not starting - look at the Cloud Run logs |

`The request was aborted because there was no available instance` in those
logs is worth recognising. It does not mean the service is down; it means
every instance is busy, usually holding a request that hangs. That is why the
services are deployed with `--timeout 60` rather than the default 300: an
instance held for five minutes by one stuck request is what turns a database
problem into a total outage.

**The API opens its port before it looks at the database, and never exits if
the database is missing.** A server that holds its port hostage to a
dependency turns any problem with that dependency into "the container failed
to start and listen on PORT" - a message that names the symptom and not one
cause. If PostgreSQL is unreachable the service still starts, `/health`
answers `degraded`, and every other route returns the driver's own error.
Look there first.

The server talks to the database through a **connection pool**, and on Cloud
Run that is not a performance decision. Between requests an instance's CPU is
frozen and Cloud SQL drops what it sees as an idle client; the socket is then
dead, but nothing says so until a query is written into it and no answer comes
back. The driver's default query timeout is five minutes, so the symptom is
not an error - it is silence, and `curl` simply times out. The pool retires a
connection after five minutes rather than handing a dead one to a request, and
every query has a thirty-second ceiling.

The script grants the Cloud Run runtime identity the three roles it needs
before deploying anything:

| Role | Scope | For |
| --- | --- | --- |
| `roles/secretmanager.secretAccessor` | the one secret | reading `DB_PASSWORD` |
| `roles/cloudsql.client` | the project | opening the socket |
| `roles/firebaseauth.admin` | the project | writing role claims, `/admin` only |

On projects created since 2024 the default compute service account starts with
**no roles at all**, so none of this is redundant. A missing grant does not
fail early — it fails several minutes in, on the first `gcloud run deploy`,
with a message about `env[5].value_from.secret_key_ref`. That message means
exactly one thing: the service account cannot read the secret. Re-running the
script fixes it.

### Point the applications at it

Per visitor, with no rebuild:

```
https://my-hospital-ehr.procaryote.com/?backend=restApi&api=<the EHR Cloud Run URL>
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

| Application | Address | Firebase site |
|---|---|---|
| Portal | `https://my-hospital-2026.web.app` | `my-hospital-2026` (the default site) |
| EHR | `https://my-hospital-ehr.procaryote.com` | `my-hospital-2026-ehr` |
| ADT | `https://my-hospital-adt.procaryote.com` | `my-hospital-2026-adt` |
| PHARM | `https://my-hospital-pharm.procaryote.com` | `my-hospital-2026-pharm` |
| EAI | `https://my-hospital-eai.procaryote.com` | `my-hospital-2026-eai` |
| Devices | `https://my-hospital-dev.procaryote.com` | `my-hospital-2026-dev` |

A custom domain is *attached* to a site; it does not rename it. The site ids
stay as they are in `.firebaserc` and `create_hosting_sites.sh`, the
`.web.app` addresses keep working, and nothing needs redeploying when a
domain is added or changed.

### Custom domains

The Firebase CLI cannot attach a domain, so this part is the console:
**Hosting -> the site -> Add custom domain**, once per site, at
<https://console.firebase.google.com/project/my-hospital-2026/hosting/sites>.

Firebase asks for a TXT record to prove you own `procaryote.com`, then gives
two A records per host. Add them at whoever runs the DNS for the domain.
Certificates are issued automatically once the records propagate - usually
minutes, occasionally a day. Until then the domain shows a certificate
warning while the `.web.app` address keeps serving normally.

**Two things break quietly if you forget them.**

Firebase Auth rejects a sign-in from an origin it does not know, and a new
custom domain is not known. Add all five under **Authentication -> Settings ->
Authorised domains**, or sign-in works on `.web.app` and fails on
`procaryote.com` with an error that does not mention domains at all.

The portal has no custom domain yet, so it stays on `my-hospital-2026.web.app`
- it is the project's default site. If you add one, say
`my-hospital.procaryote.com`, it needs no code change: the portal's own
address is nowhere in its source.

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
https://my-hospital-dev.procaryote.com/?device=DEV1     → student 1
https://my-hospital-dev.procaryote.com/?device=DEV2     → student 2
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

**The administration API is only as safe as the administrator's password.**
`/admin` can create accounts and grant roles in the Firebase project, and the
one thing standing in front of it is one sign-in. Before the URLs are public:
give `admin@mini-hospital.be` a long password of its own (not the shared one),
keep the number of accounts holding the `admin` role to the people who teach
the course, and check `./tools/setup_firebase_auth.sh --list` occasionally to
see who does. If you do not need the console at all, deploy with
`ADMIN_APP=none` and it is not mounted anywhere.

## Costs

| | Plan | Cost |
|---|---|---|
| Authentication for ~15 accounts | Spark (free) | none |
| Hosting the five web builds | Spark (free) | none within the free quota |
| Data Connect / Cloud SQL | Blaze | per-hour, while the instance exists |

Everything the course needs works on the free plan. Only the cloud database
requires billing, and the local Docker stack does the same job for nothing.
