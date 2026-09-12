import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/encounter.dart';
import '../models/observation.dart';

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
  Future<PublishResult> publishMovement({
    required Movement movement,
    required Encounter encounter,
  }) => publish(
    source: HospitalApp.adt,
    messageType: 'ADT^${movement.type.hl7EventCode}',
    patientId: movement.patientId,
    payload: <String, dynamic>{
      ...movement.toJson(),
      'encounter': encounter.toJson(),
    },
  );

  /// Publishes a device reading as a FHIR Observation, which is what the
  /// seeded vitals flow expects to receive.
  Future<PublishResult> publishObservation(
    Observation observation, {
    HospitalApp source = HospitalApp.device,
  }) => publish(
    source: source,
    messageType: 'Observation',
    patientId: observation.patientId,
    payload: observation.toFhir(),
  );

  void close() => _client.close();
}
