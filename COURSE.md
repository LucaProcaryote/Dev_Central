# Mini-Hospital 2026 — course guide

A working hospital in six repositories, for the course on hospital, e-health
and connected medical device informatics.

Everything in it is fictive. Twenty invented patients, their stays,
measurements, prescriptions and notes; a bed board with real occupancy; a
pharmacy cabinet that refuses unsafe releases; an interface engine you build
flows in by dragging blocks; and ten device simulators, one per student.

Everything is in **English, French and Dutch**, switchable while the
application is running.

---

## The six repositories

| Repository | What it is | Port |
|---|---|---|
| [EHR](https://github.com/LucaProcaryote/EHR) | The clinical record: patient fiche, prescriptions, notes | 8081 |
| [ADT](https://github.com/LucaProcaryote/ADT) | Admission, transfer, discharge; the bed board | 8082 |
| [PHARM](https://github.com/LucaProcaryote/PHARM) | The automated dispensing cabinet | 8083 |
| [EAI](https://github.com/LucaProcaryote/EAI) | Interface engine, FHIR repository, visual flow builder | 8084 |
| [Dev_Central](https://github.com/LucaProcaryote/Dev_Central) | Device simulators, the shared package, the back end | 8085 |
| HAPI FHIR | The FHIR R4 repository (in `Dev_Central/infrastructure`) | 8080 |

Each application is a Flutter app that runs as a web app and on Android and
iOS from the same code.

---

## Day one: get something on screen

The only prerequisite is the [Flutter SDK](https://docs.flutter.dev/get-started/install)
(3.24 or newer). No database, no Docker, no Firebase account.

```bash
git clone https://github.com/LucaProcaryote/EHR
cd EHR
flutter pub get
flutter run -d chrome
```

That is the whole setup. The application opens on the in-memory dataset with
the hospital already half full. Sign in with any account on the login screen —
the password is not checked, and a yellow strip across the top says so, because
demo data that looks live is how demonstrations go wrong.

Do the same for `ADT`, `PHARM`, `EAI` and `Dev_Central`.

> In this mode each application has its **own** copy of the data in its own
> browser tab. Admitting a patient in ADT will not make them appear in the EHR.
> Connecting them is the second half of the course.

---

## Day two: the real back end

```bash
cd Dev_Central/infrastructure
docker compose up -d
docker compose logs -f          # HAPI FHIR takes ~3 minutes on first boot
```

That gives you PostgreSQL with five databases, an API for each application, and
the HAPI FHIR server. Check it:

```bash
for p in 8081 8082 8083 8084 8085; do curl -s localhost:$p/health; echo; done
curl -s localhost:8080/fhir/metadata | head -c 80
```

Now point the applications at it:

```bash
cd EHR && flutter run -d chrome --dart-define=BACKEND=restApi
```

The yellow strip disappears. The applications are now reading real PostgreSQL,
through a real HTTP API, and what one writes another can see.

---

## What each application teaches

### EHR — the record
The patient fiche, one chart per vital sign, prescriptions with live allergy
checking, and clinical notes shown in the language they were written in.

Notice: the allergy banner is pinned above the tabs and repeated in the
prescribing dialog. A high-risk allergy blocks the prescription outright; a
low-risk one has to be acknowledged in writing.

Notice also: notes are never machine-translated. A French discharge summary
read as approximate Dutch is a clinical risk, not a convenience — so the note
is labelled with its language instead.

### ADT — movement
Admission, transfer, discharge, and the bed board everyone else reads.

Each movement touches three things that must agree: the encounter, the bed and
the movement log. Every row in the log is labelled with the HL7 v2 trigger
event it corresponds to (`ADT^A01`, `A02`, `A03`) — the same codes you will see
in the EAI message log.

A discharged bed goes to **cleaning**, not straight to free.

### PHARM — the cabinet
Locked until someone unlocks it. One drawer at a time. The drawer closes itself
after eight seconds and says that it did.

Every safety check runs **before** the drawer will open. A cabinet that lets
you take the drug and then tells you the patient is allergic to it has
prevented nothing.

### EAI — the plumbing
Drag blocks onto a canvas, wire them together, and press **Run** to watch a
message pass through every step with its payload before and after.

Three worked flows ship with it. Read them before running them.

### Dev_Central — the devices
Ten simulators, one per student. Scenarios that move a patient's vitals in
consistent clinical directions — deteriorating drops the saturation *and*
raises the heart rate, together.

Apple Watch readings come in through the same pipeline. Downstream, nothing
can tell a watch reading from a simulated one. That is the lesson.

---

## Suggested lab exercises

### Lab 1 — Read the record *(EHR)*
1. Find Pieter De Smet. What is he in for, how long has he been in, and what
   does the ICU note say about his allergy?
2. Open his vital signs. The temperature curve falls across the window. Find
   the sentence in the notes that explains why.
3. Switch to Dutch. Which parts of the screen change, and which do not? Why
   not?
4. Find the two patients who are children. What is different about their
   normal heart-rate ranges, and where does the application get that from?

### Lab 2 — Move a patient *(ADT)*
1. Admit Amina Haddad to internal medicine.
2. Transfer her to the ICU, then discharge her.
3. Open the movement log. Confirm each movement's origin is the previous
   movement's destination.
4. Try to admit her again while she is still in. Read the error.
5. Try to put a second patient in her bed. Read that error too.
6. **Now find those two rules in `infrastructure/db/schema.sql`.** They are
   partial unique indexes. Why partial?

### Lab 3 — Refuse a drug *(PHARM)*
1. Open the dispensing queue. Try to dispense anything. Why is it refused?
2. Unlock the cabinet and dispense one dose. Watch the stock fall.
3. Go to *Stock*. Find the empty slot, the expired lot, and the slots below
   par. Restock one — what happens to the lot number, and why?
4. In the EHR, prescribe **amoxicillin** for Émile Van Damme. It will be
   blocked. Now try **ceftriaxone** — a different drug. It is flagged too.
   Find out why in `packages/hospital_core/lib/src/clinical/safety_checks.dart`.
5. That check is deliberately simple. What would a real hospital use instead,
   and what does the simple version miss?

### Lab 4 — Build a flow *(EAI + Dev_Central)*
1. Open *Low SpO2 alert*. Press **Run**. Read the trace: what did each block
   do?
2. Change the threshold from 92 to 99 and run it again. Same payload, different
   outcome — find the step where it diverges.
3. Load the *Broken · not FHIR* sample. What does the validator say, and which
   block stops it?
4. Build a new flow from scratch: device feed → filter for body temperature
   above 38.5 → mapper → log. Test it.
5. Start your device simulator, point it at a patient, and send a manual
   reading that should trigger your flow. Find it in the message log.

### Lab 5 — Speak FHIR *(EAI)*
1. Start the FHIR server and press *Load the fictive patients into FHIR*.
2. Find every oxygen saturation below 92:
   ```bash
   curl -s 'http://localhost:8080/fhir/Observation?code=2708-6&value-quantity=lt92&_sort=-date' | jq '.total'
   ```
3. Pull one patient's entire record in one request:
   ```bash
   curl -s 'http://localhost:8080/fhir/Patient/pat-008/$everything' | jq '.total'
   ```
4. Ask the server to validate an incomplete resource:
   ```bash
   curl -s -X POST http://localhost:8080/fhir/Observation/\$validate \
     -H 'Content-Type: application/fhir+json' -d '{"resourceType":"Observation"}' | jq '.issue[].diagnostics'
   ```
   Compare what it says with what the *FHIR validator* block in the flow editor
   checks. What is the difference, and does it matter?
5. Search for a patient by Belgian national register number. Why does that
   work, and what identifier type makes it possible?

### Lab 6 — Break something *(all)*
1. Stop the EAI API (`docker compose stop eai-api`). Now admit a patient in
   ADT. What happens, and what does the snackbar say?
2. Was the admission lost? Check the movement log. Why was it built that way?
3. Start EAI again. Is the message there? Should it be? What would a real
   interface engine do differently — and what is that pattern called?

---

## Configuration reference

Every application takes the same `--dart-define` values:

| Define | Values | Default |
|---|---|---|
| `BACKEND` | `memory`, `restApi`, `dataConnect` | `memory` |
| `AUTH` | `demo`, `firebase` | `demo` |
| `API_BASE` | that application's API | per application |
| `FHIR_BASE` | the HAPI FHIR endpoint | `http://localhost:8080/fhir` |
| `EAI_BASE` | the integration engine | `http://localhost:8084` |
| `DEVICE_ID` | `DEV1`..`DEV10` *(Dev_Central only)* | `DEV1` |

---

## Firebase

Real authentication against the `my-hospital-2026` project, and optionally
PostgreSQL in the cloud. Neither is needed for any lab above — see
[FIREBASE.md](FIREBASE.md) when you want them.

---

## The shared package

All five applications depend on `hospital_core` and on nothing else in common:
the domain model and its FHIR mapping, the three-language strings,
authentication, the data-access layer, the clinical safety checks and the
design system.

The canonical copy is `Dev_Central/packages/hospital_core`. Every application
repository carries a byte-identical vendored copy, so cloning one repository is
enough to run it. After changing the canonical copy:

```bash
cd packages/hospital_core && flutter test    # 56 tests
```

then in each other repository:

```bash
./tools/sync_core.sh
```

---

## Running the tests

```bash
cd EHR         && flutter test    #  7
cd ADT         && flutter test    # 17
cd PHARM       && flutter test    # 22
cd EAI         && flutter test    # 25
cd Dev_Central && flutter test    # 13
cd Dev_Central/packages/hospital_core && flutter test   # 56

# The schema enforces its own rules
psql -h localhost -U hospital -d EHR_DB -v ON_ERROR_STOP=1 \
  -f Dev_Central/infrastructure/db/test_schema.sql
```

---

## A note on the data

Every patient, address, telephone number and national register number is
invented. The `example.be` domain is reserved for exactly this purpose. The
Belgian NISS check digits are computed correctly so that format-validation
exercises have something honest to work on — but the numbers belong to nobody.

Every password in this project is a placeholder. `hospital`, `hapi`, and a
demo login that accepts anything. This is a teaching hospital on a classroom
network; none of it is a security control, and all of it says so on screen.
