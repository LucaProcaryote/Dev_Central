import 'package:flutter/foundation.dart';

import '../util/json.dart';
import 'codes.dart';

/// A single measured value (FHIR `Observation`).
///
/// This is the join point between the connected devices and the record: a
/// simulator in Dev_Central produces one, the EAI routes it, the EHR displays
/// it on the patient fiche.
@immutable
class Observation {
  const Observation({
    required this.id,
    required this.patientId,
    required this.type,
    required this.value,
    required this.effectiveDateTime,
    this.encounterId,
    this.deviceId,
    this.performer,
    this.status = ObservationStatus.finalised,
    this.note,
  });

  final String id;
  final String patientId;
  final VitalSignType type;
  final double value;
  final DateTime effectiveDateTime;

  final String? encounterId;

  /// `DEV1`..`DEV10`, or `apple-watch` when the reading was pushed from
  /// HealthKit rather than produced by a simulator.
  final String? deviceId;

  final String? performer;
  final ObservationStatus status;
  final String? note;

  String get unit => type.unit;
  bool get isAbnormal => type.isAbnormal(value);
  String get formatted => type.format(value);

  /// FHIR `interpretation` code: high, low, or normal.
  String get interpretationCode {
    if (value > type.normalHigh) return 'H';
    if (value < type.normalLow) return 'L';
    return 'N';
  }

  factory Observation.fromJson(Map<String, dynamic> json) => Observation(
    id: asString(json['id']),
    patientId: asString(json['patient_id'] ?? json['patientId']),
    type: VitalSignType.fromName(asString(json['type'])),
    value: asDouble(json['value']),
    effectiveDateTime: asDateTime(
      json['effective_date_time'] ?? json['effectiveDateTime'],
    ),
    encounterId: asStringOrNull(json['encounter_id'] ?? json['encounterId']),
    deviceId: asStringOrNull(json['device_id'] ?? json['deviceId']),
    performer: asStringOrNull(json['performer']),
    status: ObservationStatus.fromFhir(asStringOrNull(json['status'])),
    note: asStringOrNull(json['note']),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'patient_id': patientId,
    'type': type.name,
    'value': value,
    'unit': type.unit,
    'effective_date_time': effectiveDateTime.toIso8601String(),
    'encounter_id': encounterId,
    'device_id': deviceId,
    'performer': performer,
    'status': status.fhirCode,
    'note': note,
  };

  Map<String, dynamic> toFhir() => pruneNulls(<String, dynamic>{
    'resourceType': 'Observation',
    'id': id,
    'status': status.fhirCode,
    'category': <dynamic>[
      <String, dynamic>{
        'coding': <dynamic>[
          <String, dynamic>{
            'system': CodeSystems.observationCategory,
            'code': type == VitalSignType.activitySteps
                ? 'activity'
                : 'vital-signs',
          },
        ],
      },
    ],
    'code': <String, dynamic>{
      'coding': <dynamic>[
        <String, dynamic>{
          'system': CodeSystems.loinc,
          'code': type.loincCode,
          'display': type.display.en,
        },
      ],
      'text': type.display.en,
    },
    'subject': <String, dynamic>{'reference': 'Patient/$patientId'},
    if (encounterId != null)
      'encounter': <String, dynamic>{'reference': 'Encounter/$encounterId'},
    'effectiveDateTime': toFhirDateTime(effectiveDateTime),
    'valueQuantity': <String, dynamic>{
      'value': value,
      'unit': type.unit,
      'system': CodeSystems.ucum,
      'code': type.ucum,
    },
    'interpretation': <dynamic>[
      <String, dynamic>{
        'coding': <dynamic>[
          <String, dynamic>{
            'system':
                'http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation',
            'code': interpretationCode,
          },
        ],
      },
    ],
    if (deviceId != null)
      'device': <String, dynamic>{'reference': 'Device/$deviceId'},
    if (note != null)
      'note': <dynamic>[
        <String, dynamic>{'text': note},
      ],
  });

  factory Observation.fromFhir(Map<String, dynamic> resource) {
    final codings = asMapList((resource['code'] as Map?)?['coding']);
    final loinc = codings.isNotEmpty ? asString(codings.first['code']) : '';
    final quantity =
        (resource['valueQuantity'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final subject = asString((resource['subject'] as Map?)?['reference']);
    final deviceRef = asStringOrNull(
      (resource['device'] as Map?)?['reference'],
    );

    return Observation(
      id: asString(resource['id']),
      patientId: subject.startsWith('Patient/')
          ? subject.substring(8)
          : subject,
      type: VitalSignType.fromLoinc(loinc) ?? VitalSignType.heartRate,
      value: asDouble(quantity['value']),
      effectiveDateTime: asDateTime(resource['effectiveDateTime']),
      status: ObservationStatus.fromFhir(asStringOrNull(resource['status'])),
      deviceId: deviceRef != null && deviceRef.startsWith('Device/')
          ? deviceRef.substring(7)
          : deviceRef,
    );
  }
}
