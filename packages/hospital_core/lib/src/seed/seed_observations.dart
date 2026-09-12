import '../models/codes.dart';
import '../models/encounter.dart';
import '../models/observation.dart';

/// Deterministic pseudo-random source.
///
/// `Random(seed)` would do, but a tiny LCG written out here keeps the generated
/// history byte-identical across Dart versions and platforms - which matters
/// when a lecturer and ten students compare screens.
class _Lcg {
  _Lcg(this.seed);
  int seed;

  /// Uniform in [0, 1).
  double next() {
    seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF;
    return seed / 0x7FFFFFFF;
  }

  /// Roughly normal, via the mean of three uniforms. Good enough for vitals
  /// and far cheaper than a Box-Muller transform.
  double noise() => (next() + next() + next()) / 3 * 2 - 1;
}

/// The clinical picture a patient's vitals should paint over the stay.
class _Profile {
  const _Profile({
    required this.baselines,
    this.trends = const <VitalSignType, double>{},
  });

  /// Starting value per vital, at the moment of admission.
  final Map<VitalSignType, double> baselines;

  /// Change per day. Negative means improving for a fever, worsening for SpO2 -
  /// the sign is in the clinical direction of the value itself.
  final Map<VitalSignType, double> trends;
}

/// Per-patient physiology, so the graphs in the EHR tell the same story as the
/// clinical notes. A student who reads pat-008's note about resolving sepsis
/// should see the temperature curve come down to match.
const Map<String, _Profile> _profiles = <String, _Profile>{
  // Heart failure, improving on diuretics: weight falling, saturation rising.
  'pat-001': _Profile(
    baselines: <VitalSignType, double>{
      VitalSignType.bodyWeight: 88.0,
      VitalSignType.heartRate: 96,
      VitalSignType.oxygenSaturation: 91,
      VitalSignType.bodyTemperature: 36.6,
      VitalSignType.respiratoryRate: 22,
      VitalSignType.systolicBloodPressure: 148,
      VitalSignType.diastolicBloodPressure: 92,
    },
    trends: <VitalSignType, double>{
      VitalSignType.bodyWeight: -1.4,
      VitalSignType.heartRate: -4,
      VitalSignType.oxygenSaturation: 1.1,
      VitalSignType.respiratoryRate: -1.5,
      VitalSignType.systolicBloodPressure: -6,
    },
  ),
  // Pneumonia on antibiotics: fever breaking, saturation recovering.
  'pat-002': _Profile(
    baselines: <VitalSignType, double>{
      VitalSignType.bodyTemperature: 39.2,
      VitalSignType.heartRate: 104,
      VitalSignType.oxygenSaturation: 93,
      VitalSignType.respiratoryRate: 24,
      VitalSignType.bodyWeight: 68.0,
    },
    trends: <VitalSignType, double>{
      VitalSignType.bodyTemperature: -0.9,
      VitalSignType.heartRate: -6,
      VitalSignType.oxygenSaturation: 1.4,
      VitalSignType.respiratoryRate: -2,
    },
  ),
  // Day one after surgery: mild tachycardia settling.
  'pat-003': _Profile(
    baselines: <VitalSignType, double>{
      VitalSignType.bodyTemperature: 37.4,
      VitalSignType.heartRate: 88,
      VitalSignType.oxygenSaturation: 96,
      VitalSignType.respiratoryRate: 16,
      VitalSignType.bodyWeight: 81.5,
    },
    trends: <VitalSignType, double>{
      VitalSignType.heartRate: -5,
      VitalSignType.bodyTemperature: -0.3,
    },
  ),
  // Chest pain in the emergency department: everything normal, which is the point.
  'pat-005': _Profile(
    baselines: <VitalSignType, double>{
      VitalSignType.heartRate: 78,
      VitalSignType.oxygenSaturation: 98,
      VitalSignType.bodyTemperature: 36.8,
      VitalSignType.systolicBloodPressure: 124,
      VitalSignType.diastolicBloodPressure: 76,
      VitalSignType.activitySteps: 4200,
    },
  ),
  'pat-006': _Profile(
    baselines: <VitalSignType, double>{
      VitalSignType.heartRate: 84,
      VitalSignType.oxygenSaturation: 98,
      VitalSignType.bodyTemperature: 36.9,
    },
  ),
  // Septic shock, day six, recovering. Started febrile and tachycardic.
  'pat-008': _Profile(
    baselines: <VitalSignType, double>{
      VitalSignType.bodyTemperature: 39.6,
      VitalSignType.heartRate: 126,
      VitalSignType.oxygenSaturation: 89,
      VitalSignType.respiratoryRate: 28,
      VitalSignType.systolicBloodPressure: 82,
      VitalSignType.diastolicBloodPressure: 48,
      VitalSignType.bodyWeight: 74.0,
    },
    trends: <VitalSignType, double>{
      VitalSignType.bodyTemperature: -0.55,
      VitalSignType.heartRate: -7,
      VitalSignType.oxygenSaturation: 1.3,
      VitalSignType.respiratoryRate: -2.2,
      VitalSignType.systolicBloodPressure: 7,
      VitalSignType.diastolicBloodPressure: 4,
    },
  ),
  // Ten year old with asthma. Paediatric heart rate runs higher.
  'pat-010': _Profile(
    baselines: <VitalSignType, double>{
      VitalSignType.heartRate: 118,
      VitalSignType.oxygenSaturation: 93,
      VitalSignType.bodyTemperature: 37.1,
      VitalSignType.respiratoryRate: 26,
      VitalSignType.bodyWeight: 32.0,
    },
    trends: <VitalSignType, double>{
      VitalSignType.heartRate: -8,
      VitalSignType.oxygenSaturation: 1.8,
      VitalSignType.respiratoryRate: -3,
    },
  ),
  // Geriatric rehabilitation: the interesting signal is the step count rising.
  'pat-013': _Profile(
    baselines: <VitalSignType, double>{
      VitalSignType.activitySteps: 180,
      VitalSignType.heartRate: 72,
      VitalSignType.oxygenSaturation: 96,
      VitalSignType.bodyTemperature: 36.5,
      VitalSignType.bodyWeight: 52.4,
    },
    trends: <VitalSignType, double>{
      VitalSignType.activitySteps: 95,
      VitalSignType.bodyWeight: -0.14,
    },
  ),
  // Rapid atrial fibrillation being rate-controlled.
  'pat-015': _Profile(
    baselines: <VitalSignType, double>{
      VitalSignType.heartRate: 148,
      VitalSignType.oxygenSaturation: 96,
      VitalSignType.bodyTemperature: 36.7,
      VitalSignType.systolicBloodPressure: 132,
      VitalSignType.diastolicBloodPressure: 84,
      VitalSignType.bodyWeight: 71.2,
    },
    trends: <VitalSignType, double>{
      VitalSignType.heartRate: -32,
    },
  ),
  'pat-016': _Profile(
    baselines: <VitalSignType, double>{
      VitalSignType.bodyTemperature: 37.9,
      VitalSignType.heartRate: 96,
      VitalSignType.oxygenSaturation: 98,
      VitalSignType.bodyWeight: 58.0,
    },
  ),
  'pat-018': _Profile(
    baselines: <VitalSignType, double>{
      VitalSignType.heartRate: 88,
      VitalSignType.oxygenSaturation: 97,
      VitalSignType.bodyTemperature: 36.8,
      VitalSignType.bodyWeight: 94.6,
      VitalSignType.systolicBloodPressure: 146,
      VitalSignType.diastolicBloodPressure: 88,
    },
    trends: <VitalSignType, double>{
      VitalSignType.bodyWeight: -0.35,
      VitalSignType.systolicBloodPressure: -5,
    },
  ),
  // Post infarction, on a beta blocker. Note the low-ish blood pressure the
  // clinical note mentions as the reason amlodipine was put on hold.
  'pat-020': _Profile(
    baselines: <VitalSignType, double>{
      VitalSignType.heartRate: 68,
      VitalSignType.oxygenSaturation: 96,
      VitalSignType.bodyTemperature: 36.6,
      VitalSignType.systolicBloodPressure: 118,
      VitalSignType.diastolicBloodPressure: 70,
      VitalSignType.bodyWeight: 79.8,
    },
    trends: <VitalSignType, double>{
      VitalSignType.systolicBloodPressure: -3.5,
      VitalSignType.diastolicBloodPressure: -2.5,
    },
  ),
};

/// Which simulator is feeding which patient, so the observations carry a
/// plausible `device` reference rather than appearing from nowhere.
const Map<String, String> _deviceByPatient = <String, String>{
  'pat-001': 'DEV2',
  'pat-002': 'DEV3',
  'pat-005': 'WATCH-1',
  'pat-008': 'DEV1',
  'pat-010': 'DEV5',
  'pat-013': 'DEV6',
  'pat-015': 'DEV7',
  'pat-016': 'DEV9',
  'pat-018': 'DEV8',
  'pat-020': 'DEV10',
};

/// Generates the vital-sign history for every active encounter.
///
/// Readings are taken every four hours, back to admission or 72 hours,
/// whichever is shorter. Weight and step count are daily instead - nobody
/// weighs a patient six times a day.
List<Observation> buildSeedObservations(
  DateTime now,
  List<Encounter> encounters,
) {
  final observations = <Observation>[];
  var counter = 0;

  for (final encounter in encounters) {
    if (!encounter.status.isActive) continue;
    final profile = _profiles[encounter.patientId];
    if (profile == null) continue;

    final device = _deviceByPatient[encounter.patientId];

    // How long the patient has actually been in, and how far back we plot.
    // These are different numbers: a six-day stay still only shows the last
    // three days of readings, but the values in that window must reflect six
    // days of treatment, not three. Conflating the two made long stays look
    // like they had only just been admitted.
    final hoursSinceAdmission =
        now.difference(encounter.admissionDate).inHours.clamp(1, 100000);
    final windowHours = hoursSinceAdmission > 72 ? 72 : hoursSinceAdmission;
    final random = _Lcg(encounter.patientId.hashCode.abs() % 100000 + 7);

    for (final entry in profile.baselines.entries) {
      final type = entry.key;
      final baseline = entry.value;
      final perDay = profile.trends[type] ?? 0.0;

      // Daily cadence for weight and activity, four-hourly for the rest.
      final intervalHours =
          (type == VitalSignType.bodyWeight || type == VitalSignType.activitySteps)
              ? 24
              : 4;

      for (var hoursAgo = windowHours; hoursAgo >= 0; hoursAgo -= intervalHours) {
        // Days of treatment completed at the moment of this reading.
        final elapsedDays = (hoursSinceAdmission - hoursAgo) / 24.0;
        final drift = perDay * elapsedDays;

        // Amplitude of the random jitter, proportional to what the measurement
        // plausibly varies by between readings.
        final jitter = switch (type) {
          VitalSignType.bodyTemperature => 0.25,
          VitalSignType.bodyWeight => 0.3,
          VitalSignType.oxygenSaturation => 1.2,
          VitalSignType.activitySteps => 60,
          VitalSignType.heartRate => 6,
          VitalSignType.respiratoryRate => 1.5,
          _ => 5,
        };

        var value = baseline + drift + random.noise() * jitter;

        // Keep the generated values physiologically possible.
        value = switch (type) {
          VitalSignType.oxygenSaturation => value.clamp(70, 100),
          VitalSignType.bodyTemperature => value.clamp(34.0, 42.0),
          VitalSignType.heartRate => value.clamp(35, 200),
          VitalSignType.respiratoryRate => value.clamp(6, 45),
          VitalSignType.activitySteps => value.clamp(0, 30000),
          VitalSignType.bodyWeight => value.clamp(2, 250),
          _ => value.clamp(30, 260),
        };

        value = double.parse(value.toStringAsFixed(type.decimals));
        counter++;

        observations.add(Observation(
          id: 'obs-${counter.toString().padLeft(5, '0')}',
          patientId: encounter.patientId,
          encounterId: encounter.id,
          type: type,
          value: value,
          effectiveDateTime: now.subtract(Duration(hours: hoursAgo)),
          deviceId: device,
          performer: device == null ? 'Marie Lambert' : null,
        ));
      }
    }
  }

  observations.sort(
    (a, b) => b.effectiveDateTime.compareTo(a.effectiveDateTime),
  );
  return observations;
}
