import 'dart:math';

import 'package:hospital_core/hospital_core.dart';

/// What the patient is doing over the course of the simulation.
///
/// The scenario is what turns a random-number generator into a teaching tool:
/// a student watching a deteriorating patient should see the saturation fall
/// and the heart rate climb together, the way they actually do, and should be
/// able to point at the moment the alert flow fired.
enum SimulationScenario {
  stable(LocalizedText(en: 'Stable', fr: 'Stable', nl: 'Stabiel')),
  deteriorating(
    LocalizedText(en: 'Deteriorating', fr: 'Dégradation', nl: 'Verslechterend'),
  ),
  recovering(
    LocalizedText(en: 'Recovering', fr: 'Amélioration', nl: 'Herstellend'),
  ),
  artefact(
    LocalizedText(
      en: 'Noisy signal',
      fr: 'Signal bruité',
      nl: 'Ruisachtig signaal',
    ),
  );

  const SimulationScenario(this.display);
  final LocalizedText display;
}

/// Produces plausible vital-sign values.
///
/// Two things make the output convincing rather than merely random: each
/// measurement moves from where it was, not from its baseline, so the trace is
/// continuous; and the scenario pushes all of a patient's measurements in a
/// consistent physiological direction, so heart rate and saturation tell the
/// same story.
class SignalGenerator {
  SignalGenerator({
    required this.scenario,
    Map<VitalSignType, double>? initial,
    int? seed,
  }) : _random = Random(seed),
       _current = <VitalSignType, double>{
         ..._baselines,
         if (initial != null) ...initial,
       },
       _elapsed = Duration.zero;

  /// Healthy starting values, used when the caller has nothing better.
  static const Map<VitalSignType, double> _baselines = <VitalSignType, double>{
    VitalSignType.heartRate: 74,
    VitalSignType.oxygenSaturation: 97,
    VitalSignType.bodyTemperature: 36.8,
    VitalSignType.respiratoryRate: 15,
    VitalSignType.bodyWeight: 72,
    VitalSignType.activitySteps: 3400,
    VitalSignType.systolicBloodPressure: 122,
    VitalSignType.diastolicBloodPressure: 76,
  };

  SimulationScenario scenario;
  final Random _random;
  final Map<VitalSignType, double> _current;
  Duration _elapsed;

  /// The value each measurement is currently sitting at.
  Map<VitalSignType, double> get current =>
      Map<VitalSignType, double>.unmodifiable(_current);

  void setValue(VitalSignType type, double value) => _current[type] = value;

  /// How far each measurement drifts per minute under the current scenario.
  ///
  /// The sign is physiological, not arithmetic: deteriorating means the
  /// saturation goes *down* and the heart rate goes *up*.
  double _driftPerMinute(VitalSignType type) => switch (scenario) {
    SimulationScenario.stable || SimulationScenario.artefact => 0,
    SimulationScenario.deteriorating => switch (type) {
      VitalSignType.oxygenSaturation => -0.9,
      VitalSignType.heartRate => 1.8,
      VitalSignType.respiratoryRate => 0.5,
      VitalSignType.bodyTemperature => 0.06,
      VitalSignType.systolicBloodPressure => -1.4,
      VitalSignType.diastolicBloodPressure => -0.9,
      VitalSignType.activitySteps => -40,
      VitalSignType.bodyWeight => 0.01,
    },
    SimulationScenario.recovering => switch (type) {
      VitalSignType.oxygenSaturation => 0.5,
      VitalSignType.heartRate => -1.1,
      VitalSignType.respiratoryRate => -0.3,
      VitalSignType.bodyTemperature => -0.05,
      VitalSignType.systolicBloodPressure => 0.8,
      VitalSignType.diastolicBloodPressure => 0.5,
      VitalSignType.activitySteps => 60,
      VitalSignType.bodyWeight => -0.01,
    },
  };

  /// Beat-to-beat variation, which is what makes a trace look measured rather
  /// than computed. Wider in the artefact scenario, where the point is to see
  /// what a noisy sensor does to a downstream alert rule.
  double _jitter(VitalSignType type) {
    final double base = switch (type) {
      VitalSignType.heartRate => 3.0,
      VitalSignType.oxygenSaturation => 0.8,
      VitalSignType.bodyTemperature => 0.12,
      VitalSignType.respiratoryRate => 1.0,
      VitalSignType.bodyWeight => 0.15,
      VitalSignType.activitySteps => 40.0,
      _ => 2.5,
    };
    return scenario == SimulationScenario.artefact ? base * 6.0 : base;
  }

  static double _clampFor(VitalSignType type, double value) => switch (type) {
    VitalSignType.oxygenSaturation => value.clamp(60, 100),
    VitalSignType.bodyTemperature => value.clamp(33, 42.5),
    VitalSignType.heartRate => value.clamp(28, 220),
    VitalSignType.respiratoryRate => value.clamp(4, 50),
    VitalSignType.activitySteps => value.clamp(0, 40000),
    VitalSignType.bodyWeight => value.clamp(2, 300),
    _ => value.clamp(30, 260),
  };

  /// Advances the simulated clock and returns the next value for [type].
  double next(VitalSignType type, Duration since) {
    _elapsed += since;
    final minutes = since.inMilliseconds / 60000.0;
    final drift = _driftPerMinute(type) * minutes;
    // Symmetric noise around zero.
    final noise = (_random.nextDouble() - 0.5) * 2 * _jitter(type);

    final value = _clampFor(type, (_current[type] ?? 0) + drift + noise);
    _current[type] = value;
    return double.parse(value.toStringAsFixed(type.decimals));
  }

  /// Produces one reading of every measurement the device supports.
  List<Observation> sample({
    required MedicalDevice device,
    required String patientId,
    String? encounterId,
    required Duration since,
    required DateTime at,
    required String Function() nextId,
  }) => <Observation>[
    for (final type in device.kind.measures)
      Observation(
        id: nextId(),
        patientId: patientId,
        encounterId: encounterId,
        type: type,
        value: next(type, since),
        effectiveDateTime: at,
        deviceId: device.code,
        status: ObservationStatus.finalised,
      ),
  ];

  Duration get elapsed => _elapsed;
}
