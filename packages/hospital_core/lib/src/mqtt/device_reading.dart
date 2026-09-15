/// What a connected device actually puts on the wire.
///
/// Not a FHIR Observation. A bedside monitor sends the smallest thing that
/// carries the measurement, because it may be doing so every few seconds over
/// a link it does not control; building a clinical resource is the receiving
/// system's job. Keeping the two apart is the point of the exercise, and it
/// is why the integration canvas has a node that turns one into the other
/// rather than the devices publishing FHIR directly.
library;

import 'dart:convert';

import '../models/codes.dart';
import '../models/observation.dart';
import '../util/json.dart';
import 'mqtt_topics.dart';

/// One measurement as published by a device.
class DeviceReading {
  const DeviceReading({
    required this.deviceId,
    required this.patientId,
    required this.metric,
    required this.value,
    required this.unit,
    required this.at,
    this.location = DeviceLocation.nowhere,
    this.sequence,
  });

  /// `DEV1`..`DEV10`, or `apple-watch`.
  final String deviceId;
  final String patientId;

  /// Matches a [VitalSignType] name.
  final String metric;
  final double value;
  final String unit;
  final DateTime at;
  final DeviceLocation location;

  /// The device's own counter. A gap in it is how a receiver learns that
  /// something was lost, which QoS 0 makes possible and nothing else reveals.
  final int? sequence;

  /// The reading as an [Observation], resolving the metric against the
  /// platform's vital sign catalogue.
  ///
  /// [id] has to be supplied: a device does not know what the record will
  /// call this measurement, and inventing one here would produce a different
  /// resource every time the same message was processed twice.
  Observation toObservation({required String id, String? encounterId}) =>
      Observation(
        id: id,
        patientId: patientId,
        type: VitalSignType.fromName(metric),
        value: value,
        effectiveDateTime: at,
        deviceId: deviceId,
        encounterId: encounterId,
      );

  Map<String, dynamic> toJson() => pruneNulls(<String, dynamic>{
    'device': deviceId,
    'patient': patientId,
    'metric': metric,
    'value': value,
    'unit': unit,
    'at': at.toUtc().toIso8601String(),
    'ward': location.wardId,
    'bed': location.bedId,
    'seq': sequence,
  });

  String encode() => jsonEncode(toJson());

  /// Reads a payload back.
  ///
  /// [topic] fills in what the payload leaves out: a device that publishes to
  /// a bed's topic need not repeat the bed in every message, and a receiver
  /// that trusted only the payload would lose the location entirely.
  factory DeviceReading.fromJson(
    Map<String, dynamic> json, {
    ReadingTopic? topic,
  }) => DeviceReading(
    deviceId: asString(json['device'], fallback: topic?.deviceId ?? ''),
    patientId: asString(json['patient']),
    metric: asString(json['metric'], fallback: topic?.metric ?? ''),
    value: asDouble(json['value']),
    unit: asString(json['unit']),
    at: asDateTime(json['at']),
    location: DeviceLocation(
      wardId: asStringOrNull(json['ward']) ?? topic?.location.wardId,
      bedId: asStringOrNull(json['bed']) ?? topic?.location.bedId,
    ),
    sequence: asIntOrNull(json['seq']),
  );

  /// Builds a reading from an [Observation], for the simulators.
  factory DeviceReading.of(
    Observation observation, {
    DeviceLocation location = DeviceLocation.nowhere,
    int? sequence,
  }) => DeviceReading(
    deviceId: observation.deviceId ?? 'unknown',
    patientId: observation.patientId,
    metric: observation.type.name,
    value: observation.value,
    unit: observation.type.ucum,
    at: observation.effectiveDateTime,
    location: location,
    sequence: sequence,
  );

  /// The topic this reading belongs on.
  String get topic => MqttTopics.reading(
    deviceId: deviceId,
    metric: metric,
    location: location,
  );
}

/// Whether a device is talking.
enum DevicePresence {
  online,
  offline;

  static DevicePresence fromName(String value) =>
      value == 'online' ? DevicePresence.online : DevicePresence.offline;
}

/// A device's liveness, as published on the broker.
///
/// Named for the message rather than the state, because [DeviceStatus] in the
/// domain model already means something else - whether a device is in
/// service, in standby or under maintenance. What a broker knows is narrower:
/// whether anything is currently talking.
///
/// Published retained so a subscriber that arrives late
/// still learns the current state, and registered as the last will so the
/// broker publishes `offline` when the device stops answering.
///
/// This is the part of MQTT with no HTTP equivalent, and the part that
/// matters clinically: a monitor that has gone quiet is not a missing
/// measurement, it is a patient nobody is watching.
class PresenceMessage {
  const PresenceMessage({
    required this.deviceId,
    required this.presence,
    required this.at,
  });

  final String deviceId;
  final DevicePresence presence;
  final DateTime at;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'device': deviceId,
    'state': presence.name,
    'at': at.toUtc().toIso8601String(),
  };

  String encode() => jsonEncode(toJson());

  factory PresenceMessage.fromJson(Map<String, dynamic> json) => PresenceMessage(
    deviceId: asString(json['device']),
    presence: DevicePresence.fromName(asString(json['state'])),
    at: asDateTime(json['at']),
  );

  String get topic => MqttTopics.status(deviceId);
}
