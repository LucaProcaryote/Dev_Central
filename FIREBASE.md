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

The applications expect the same cast of characters the demo mode uses, so
that switching between the two does not change who is on the ward.

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

Give each student their own account too — `student01@…` through
`student10@…` — with the `student` role, which can do everything.

### Roles

Firebase owns identity. It does not own **role**: the applications read a
`role` custom claim from the ID token. A hospital would drive those claims
from its HR directory; here you set them once with the Admin SDK.

```bash
npm install firebase-admin
```

```js
// set_roles.js — run once, with a service-account key from
// Project settings → Service accounts → Generate new private key
const admin = require('firebase-admin');
admin.initializeApp({
  credential: admin.credential.cert(require('./serviceAccountKey.json')),
});

const roles = {
  'anne.dubois@mini-hospital.be': 'physician',
  'jan.peeters@mini-hospital.be': 'physician',
  'marie.lambert@mini-hospital.be': 'nurse',
  'sofie.declercq@mini-hospital.be': 'nurse',
  'paul.mertens@mini-hospital.be': 'pharmacist',
  'fatima.elamrani@mini-hospital.be': 'admissionClerk',
  'tom.vandenberg@mini-hospital.be': 'integrationEngineer',
  'lucas.moreau@mini-hospital.be': 'biomedicalTechnician',
  'student@mini-hospital.be': 'student',
};

(async () => {
  for (const [email, role] of Object.entries(roles)) {
    const user = await admin.auth().getUserByEmail(email);
    await admin.auth().setCustomUserClaims(user.uid, { role });
    console.log(`${email} → ${role}`);
  }
})();
```

Never commit `serviceAccountKey.json`. It is a master key to the project, and
the `.gitignore` in each repository already excludes it.

A user whose claim is missing or unreadable falls back to `student`, which is
the safe default in a teaching environment. The valid values are the names in
`UserRole` (`packages/hospital_core/lib/src/models/hospital_user.dart`).

### Connect the applications

Once per repository:

```bash
dart pub global activate flutterfire_cli
cd EHR && flutterfire configure --project=my-hospital-2026
```

That writes `lib/firebase_options.dart`. It is **git-ignored on purpose** — it
belongs to your Firebase project, not to this repository.

Then:

```bash
flutter run -d chrome --dart-define=AUTH=firebase
```

The demo-account buttons disappear from the login screen and the e-mail and
password fields become real.

### Authorised domains

Firebase Auth rejects sign-in from an origin it does not know. Under
**Authentication → Settings → Authorised domains**, `localhost` is there by
default. Add any other host you serve the applications from.

---

## 2. PostgreSQL in the cloud (optional)

Only if you want the hospital to outlive the laptop it was demonstrated on.

**This requires the Blaze plan.** Data Connect provisions a Cloud SQL
instance, and Cloud SQL is not free. A small instance is inexpensive, but it
is not zero, and it will keep costing while it exists.

```bash
npm install -g firebase-tools
firebase login
cd Dev_Central/infrastructure
firebase deploy --only dataconnect --project my-hospital-2026
```

The schema and operations are in `infrastructure/dataconnect/`. Then:

```bash
flutter run -d chrome --dart-define=BACKEND=dataConnect --dart-define=AUTH=firebase
```

Two things there are worth discussing with the students:

- `dataconnect/schema/schema.gql` and `db/schema.sql` describe the same tables
  and must be kept in step **by hand**. That is part of what a managed backend
  costs you.
- Data Connect generates one mutation per table, so there is no single "admit
  patient" operation — the three writes an admission implies are composed on
  the client. That is exactly the transactional gap `AdtService` documents in
  the ADT application, and it is a good place to talk about what a database
  transaction actually buys.

### Turning it off

Data Connect keeps charging while the Cloud SQL instance exists. When the
course is over, delete the instance in the Google Cloud console — deleting the
Firebase Data Connect service alone does not remove it.

---

## 3. Hosting the applications (optional)

To give the students URLs instead of local builds:

```bash
cd EHR
flutter build web --release --dart-define=AUTH=firebase --dart-define=BACKEND=restApi \
  --dart-define=API_BASE=https://your-api-host
firebase deploy --only hosting --project my-hospital-2026
```

If you do this, the back end has to be reachable from the browser too, and
**every CORS setting in this project is currently wide open**. That is right
for a classroom laptop and wrong for anything on the public internet. Narrow
`Access-Control-Allow-Origin` in `infrastructure/server/lib/src/api.dart` and
`HAPI_FHIR_CORS_ALLOWED_ORIGIN_PATTERNS` in the compose file before exposing
anything.

---

## Costs

| | Plan | Cost |
|---|---|---|
| Authentication for ~15 accounts | Spark (free) | none |
| Hosting the five web builds | Spark (free) | none within the free quota |
| Data Connect / Cloud SQL | Blaze | per-hour, while the instance exists |

Everything the course needs works on the free plan. Only the cloud database
requires billing, and the local Docker stack does the same job for nothing.
