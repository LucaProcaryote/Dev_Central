import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../hl7/hl7_builder.dart';
import '../models/encounter.dart';
import '../models/observation.dart';
import '../models/patient.dart';

/// Result of trying to hand an event to the integration engine.
class PublishResult {
  const PublishResult({required this.delivered, this.error});

  final bool delivered;
  final String? error;

  static const PublishResult ok = PublishResult(delivered: true);
}

/// Posts events from an application to the EAI integration engine.
///
/// Delivery is best-effort by design. An ADT admission must be recorded in the
/// ADT database whether or not the integration engine happens to be running:
/// losing the transfer because a downstream system is down is exactly the
/// failure mode hospitals build interface engines to avoid. The caller commits
/// its own write first, then publishes, and shows the user which of the two
/// happened.
class EventPublisher {
  EventPublisher({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  /// Base URL of the integration engine, e.g. `http://localhost:8084`.
  final String baseUrl;
  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 4);

  /// Posts a raw message. [messageType] is what the flows filter on, such as
  /// `ADT^A01` or `Observation`.
  Future<PublishResult> publish({
    required HospitalApp source,
    required String messageType,
    required Map<String, dynamic> payload,
    String? patientId,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/messages'),
            headers: const <String, String>{'Content-Type': 'application/json'},
            body: jsonEncode(<String, dynamic>{
              'source_app': source.code,
              'message_type': messageType,
              'patient_id': patientId,
              'payload': payload,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return PublishResult.ok;
      }
      return PublishResult(
        delivered: false,
        error: 'HTTP ${response.statusCode}',
      );
    } catch (error) {
      return PublishResult(delivered: false, error: '$error');
    }
  }

  /// Publishes an ADT movement, tagged with the HL7 v2 trigger event so the
  /// students see the same `A01`/`A02`/`A03` codes an interface engine would.
  ///
  /// When [patient] is supplied the payload also carries the movement written
  /// out as a real `ADT^A0x` message under `hl7`, so a flow can be built
  /// either way: on the JSON, as before, or on the v2 segments. Both describe
  /// the same event, which is the comparison worth making.
  Future<PublishResult> publishMovement({
    required Movement movement,
    required Encounter encounter,
    Patient? patient,
    String? wardName,
    String? bedName,
  }) => publish(
    source: HospitalApp.adt,
    messageType: 'ADT^${movement.type.hl7EventCode}',
    patientId: movement.patientId,
    payload: <String, dynamic>{
      ...movement.toJson(),
      'encounter': encounter.toJson(),
      if (patient != null)
        'hl7': _builder
            .adt(
              patient: patient,
              encounter: encounter,
              movement: movement,
              wardName: wardName,
              bedName: bedName,
            )
            .toEr7(),
    },
  );

  /// Publishes a device reading as a FHIR Observation, which is what the
  /// seeded vitals flow expects to receive.
  ///
  /// With [patient], an `ORU^R01` rides along under `hl7` - the message an
  /// actual bedside monitor would put on the wire for the same reading.
  Future<PublishResult> publishObservation(
    Observation observation, {
    HospitalApp source = HospitalApp.device,
    Patient? patient,
  }) => publish(
    source: source,
    messageType: 'Observation',
    patientId: observation.patientId,
    payload: <String, dynamic>{
      ...observation.toFhir(),
      if (patient != null)
        'hl7': _oruBuilder
            .oru(patient: patient, observations: <Observation>[observation])
            .toEr7(),
    },
  );

  static const Hl7Builder _builder = Hl7Builder();

  /// Same encoding, different MSH-3: a receiving system routes on who sent
  /// the message, so a device feed must not claim to be the ADT.
  static const Hl7Builder _oruBuilder = Hl7Builder(
    sendingApplication: 'MINI-DEV',
  );

  void close() => _client.close();
}
