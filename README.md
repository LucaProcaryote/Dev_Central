# Dev_Central — Connected medical device simulators

Part of **Mini-Hospital 2026**, a teaching hospital built for the course on
hospital, e-health and connected-medical-device informatics.

This repository is two things:

1. the **device simulator** — one Flutter application that becomes `DEV1`
   through `DEV10` depending on how it is launched;
2. the **canonical copy of `hospital_core`**, the shared package every other
   application vendors.

## Run your device

Each student runs the same code with a different identity:

```bash
flutter pub get
./tools/run_device.sh 3          # you are DEV3
```

or by hand:

```bash
flutter run -d chrome --dart-define=DEVICE_ID=DEV3
```

To send readings to the integration engine as well as storing them locally:

```bash
./tools/run_device.sh 3 --eai http://localhost:8084
```

One machine can stand in for the whole class:

```bash
./tools/run_fleet.sh             # DEV1..DEV10 on ports 9001..9010
```

## The ten devices

No two students debug the same payload. Between them the class produces every
vital sign the record can display.

| | Device | Measures | Attached to |
|---|---|---|---|
| DEV1 | Multiparameter monitor | HR, SpO2, temperature, respiratory rate | Pieter De Smet (ICU) |
| DEV2 | Cardiac monitor | HR, respiratory rate | Émile Van Damme (cardiology) |
| DEV3 | Pulse oximeter | SpO2, HR | Marie-Claire Dupont (internal medicine) |
| DEV4 | Weight scale | Body weight | Émile Van Damme |
| DEV5 | Thermometer | Temperature | Noah Vermeulen (paediatrics) |
| DEV6 | Activity tracker | Steps, HR | Hélène Legrand (geriatrics) |
| DEV7 | Blood pressure monitor | Systolic, diastolic, HR | Greet Maes (cardiology) |
| DEV8 | Multiparameter monitor | HR, SpO2, temperature, respiratory rate | Rachid Benali (internal medicine) |
| DEV9 | Pulse oximeter | SpO2, HR | Thomas Petit (paediatrics) |
| DEV10 | Cardiac monitor | HR, respiratory rate | Georges Dubois (cardiology) |

Any device can be pointed at any patient from the interface.

## What it does

**Four scenarios.** Stable, deteriorating, recovering, and a noisy signal. The
scenario is what makes this a teaching tool rather than a random-number
generator: under *deteriorating*, the saturation falls **and** the heart rate
climbs, together, the way they actually do. Under *noisy signal* the jitter
widens sixfold, so students can watch what a bad sensor does to a downstream
alert rule.

The trace is continuous — each value moves from where it was, not from a
baseline — so the charts in the EHR look measured rather than computed.

**Adjustable interval**, one to sixty seconds, applied immediately.

**Manual readings.** Type a value and send it. You need this to demonstrate the
low-SpO2 alert flow: enter 86 and watch it fire, rather than waiting for the
deteriorating scenario to get there.

**An outbox** showing the last readings and whether the integration engine
accepted each one. If there is no engine, it says so instead of pretending.
Readings are always written to the local record too, so the simulator is useful
entirely on its own.

**A fleet board** showing every device in the hospital and what it is doing.
This is the screen for the projector during a lab session, as ten simulators
come online one by one.

## Apple Watch

Readings from an Apple Watch go through the same pipeline. On iOS a HealthKit
plugin fills this in directly; everywhere else — including the browser the
students actually use — paste the watch's export and it is parsed and published
exactly like a simulated reading.

```json
[
  {"type": "HKQuantityTypeIdentifierHeartRate", "value": 68, "date": "2026-09-12T08:15:00Z"},
  {"type": "HKQuantityTypeIdentifierOxygenSaturation", "value": 0.97, "date": "2026-09-12T08:15:00Z"}
]
```

The mapping from HealthKit's type identifiers to LOINC-coded vitals is the
whole integration, and it is about fifteen lines in
`lib/src/widgets/healthkit_panel.dart`. Note the unit conversion: HealthKit
reports oxygen saturation as a fraction (`0.97`), the hospital as a percentage
(`97`). Converting at the boundary rather than downstream is the point.

Downstream, nothing can tell a watch reading from a simulator reading — which
is exactly right. A consumer wearable is just another device on the interface.

## `hospital_core`

The canonical copy of the shared package lives at `packages/hospital_core`.
Every other repository carries a byte-identical vendored copy so that cloning
one repository is enough to run it, with no private-repository authentication
and no cross-repository path dependency to get wrong.

After changing it here:

```bash
cd packages/hospital_core && flutter test    # 55 tests
```

then in each other repository:

```bash
./tools/sync_core.sh
```

## Configuration

| Define | Values | Default |
|---|---|---|
| `DEVICE_ID` | `DEV1`..`DEV10` | `DEV1` |
| `BACKEND` | `memory`, `restApi`, `dataConnect` | `memory` |
| `EAI_BASE` | the integration engine | `http://localhost:8084` |

## Tests

```bash
flutter test                                 # 13 simulator tests
cd packages/hospital_core && flutter test    # 55 core tests
```

The simulator tests run every scenario for two thousand samples and assert the
values stay physiologically possible; that a stable patient's heart rate never
jumps ten beats between consecutive samples; that deterioration and recovery
move saturation and heart rate in opposite, clinically correct directions; and
that a watch export is indistinguishable from a generated reading once stored.
