import 'package:flutter/foundation.dart';

import '../util/json.dart';
import 'codes.dart';

/// A hospital stay or visit (FHIR `Encounter`).
///
/// The ADT application creates one on admission, updates its location on each
/// transfer and closes it on discharge. Every other application - EHR, PHARM,
/// the device simulators - hangs its data off the encounter.
@immutable
class Encounter {
  const Encounter({
    required this.id,
    required this.patientId,
    required this.status,
    required this.encounterClass,
    required this.admissionDate,
    this.wardId,
    this.roomId,
    this.bedId,
    this.dischargeDate,
    this.admittingPractitioner,
    this.attendingPractitioner,
    this.reason,
    this.dischargeDisposition,
    this.visitNumber,
  });

  final String id;
  final String patientId;
  final EncounterStatus status;
  final EncounterClass encounterClass;
  final DateTime admissionDate;

  /// Current location. Null for a patient who is not physically placed
  /// (outpatient visit, or an admission that has not been given a bed yet).
  final String? wardId;
  final String? roomId;
  final String? bedId;

  final DateTime? dischargeDate;
  final String? admittingPractitioner;
  final String? attendingPractitioner;
  final String? reason;
  final String? dischargeDisposition;

  /// Human-facing visit number, e.g. `V2026-0042`.
  final String? visitNumber;

  bool get isActive => status.isActive;
  bool get hasBed => bedId != null;

  /// Length of stay so far, or the final length of stay once discharged.
  Duration get lengthOfStay =>
      (dischargeDate ?? DateTime.now()).difference(admissionDate);

  int get lengthOfStayDays => lengthOfStay.inDays;

  Encounter copyWith({
    EncounterStatus? status,
    EncounterClass? encounterClass,
    String? wardId,
    String? roomId,
    String? bedId,
    DateTime? dischargeDate,
    String? attendingPractitioner,
    String? reason,
    String? dischargeDisposition,
    bool clearLocation = false,
  }) => Encounter(
    id: id,
    patientId: patientId,
    status: status ?? this.status,
    encounterClass: encounterClass ?? this.encounterClass,
    admissionDate: admissionDate,
    wardId: clearLocation ? null : (wardId ?? this.wardId),
    roomId: clearLocation ? null : (roomId ?? this.roomId),
    bedId: clearLocation ? null : (bedId ?? this.bedId),
    dischargeDate: dischargeDate ?? this.dischargeDate,
    admittingPractitioner: admittingPractitioner,
    attendingPractitioner: attendingPractitioner ?? this.attendingPractitioner,
    reason: reason ?? this.reason,
    dischargeDisposition: dischargeDisposition ?? this.dischargeDisposition,
    visitNumber: visitNumber,
  );

  factory Encounter.fromJson(Map<String, dynamic> json) => Encounter(
    id: asString(json['id']),
    patientId: asString(json['patient_id'] ?? json['patientId']),
    status: EncounterStatus.fromFhir(asString(json['status'])),
    encounterClass: EncounterClass.fromCode(
      asString(json['encounter_class'] ?? json['encounterClass']),
    ),
    admissionDate: asDateTime(json['admission_date'] ?? json['admissionDate']),
    wardId: asStringOrNull(json['ward_id'] ?? json['wardId']),
    roomId: asStringOrNull(json['room_id'] ?? json['roomId']),
    bedId: asStringOrNull(json['bed_id'] ?? json['bedId']),
    dischargeDate: asDateTimeOrNull(
      json['discharge_date'] ?? json['dischargeDate'],
    ),
    admittingPractitioner: asStringOrNull(
      json['admitting_practitioner'] ?? json['admittingPractitioner'],
    ),
    attendingPractitioner: asStringOrNull(
      json['attending_practitioner'] ?? json['attendingPractitioner'],
    ),
    reason: asStringOrNull(json['reason']),
    dischargeDisposition: asStringOrNull(
      json['discharge_disposition'] ?? json['dischargeDisposition'],
    ),
    visitNumber: asStringOrNull(json['visit_number'] ?? json['visitNumber']),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'patient_id': patientId,
    'status': status.fhirCode,
    'encounter_class': encounterClass.code,
    'admission_date': admissionDate.toIso8601String(),
    'ward_id': wardId,
    'room_id': roomId,
    'bed_id': bedId,
    'discharge_date': dischargeDate?.toIso8601String(),
    'admitting_practitioner': admittingPractitioner,
    'attending_practitioner': attendingPractitioner,
    'reason': reason,
    'discharge_disposition': dischargeDisposition,
    'visit_number': visitNumber,
  };

  Map<String, dynamic> toFhir() => pruneNulls(<String, dynamic>{
    'resourceType': 'Encounter',
    'id': id,
    'identifier': <dynamic>[
      if (visitNumber != null)
        <String, dynamic>{
          'use': 'official',
          'type': <String, dynamic>{
            'coding': <dynamic>[
              <String, dynamic>{
                'system': CodeSystems.identifierType,
                'code': 'VN',
                'display': 'Visit number',
              },
            ],
          },
          'value': visitNumber,
        },
    ],
    'status': status.fhirCode,
    'class': <String, dynamic>{
      'system': CodeSystems.encounterClass,
      'code': encounterClass.code,
      'display': encounterClass.display.en,
    },
    'subject': <String, dynamic>{'reference': 'Patient/$patientId'},
    'period': pruneNulls(<String, dynamic>{
      'start': toFhirDateTime(admissionDate),
      'end': dischargeDate == null ? null : toFhirDateTime(dischargeDate!),
    }),
    if (reason != null)
      'reasonCode': <dynamic>[
        <String, dynamic>{'text': reason},
      ],
    if (bedId != null)
      'location': <dynamic>[
        <String, dynamic>{
          'location': <String, dynamic>{'reference': 'Location/$bedId'},
          'status': status.isActive ? 'active' : 'completed',
        },
      ],
    if (dischargeDisposition != null)
      'hospitalization': <String, dynamic>{
        'dischargeDisposition': <String, dynamic>{
          'coding': <dynamic>[
            <String, dynamic>{
              'system': CodeSystems.dischargeDisposition,
              'code': dischargeDisposition,
            },
          ],
        },
      },
  });

  factory Encounter.fromFhir(Map<String, dynamic> resource) {
    final subject = asString((resource['subject'] as Map?)?['reference']);
    final period =
        (resource['period'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final locations = asMapList(resource['location']);
    String? bedId;
    if (locations.isNotEmpty) {
      final reference = asString(
        (locations.first['location'] as Map?)?['reference'],
      );
      bedId = reference.startsWith('Location/') ? reference.substring(9) : null;
    }
    return Encounter(
      id: asString(resource['id']),
      patientId: subject.startsWith('Patient/')
          ? subject.substring(8)
          : subject,
      status: EncounterStatus.fromFhir(asStringOrNull(resource['status'])),
      encounterClass: EncounterClass.fromCode(
        asStringOrNull((resource['class'] as Map?)?['code']),
      ),
      admissionDate: asDateTime(period['start']),
      dischargeDate: asDateTimeOrNull(period['end']),
      bedId: bedId,
    );
  }
}

/// One ADT movement: an admission, a transfer or a discharge.
///
/// Movements are append-only. Replaying them reconstructs the whole patient
/// journey, which is exactly the audit trail a hospital has to keep - and a
/// good exercise for the students.
@immutable
class Movement {
  const Movement({
    required this.id,
    required this.encounterId,
    required this.patientId,
    required this.type,
    required this.occurredAt,
    required this.performedBy,
    this.fromWardId,
    this.fromBedId,
    this.toWardId,
    this.toBedId,
    this.note,
  });

  final String id;
  final String encounterId;
  final String patientId;
  final MovementType type;
  final DateTime occurredAt;
  final String performedBy;

  final String? fromWardId;
  final String? fromBedId;
  final String? toWardId;
  final String? toBedId;
  final String? note;

  factory Movement.fromJson(Map<String, dynamic> json) => Movement(
    id: asString(json['id']),
    encounterId: asString(json['encounter_id'] ?? json['encounterId']),
    patientId: asString(json['patient_id'] ?? json['patientId']),
    type: MovementType.fromName(asString(json['type'], fallback: 'admission')),
    occurredAt: asDateTime(json['occurred_at'] ?? json['occurredAt']),
    performedBy: asString(json['performed_by'] ?? json['performedBy']),
    fromWardId: asStringOrNull(json['from_ward_id'] ?? json['fromWardId']),
    fromBedId: asStringOrNull(json['from_bed_id'] ?? json['fromBedId']),
    toWardId: asStringOrNull(json['to_ward_id'] ?? json['toWardId']),
    toBedId: asStringOrNull(json['to_bed_id'] ?? json['toBedId']),
    note: asStringOrNull(json['note']),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'encounter_id': encounterId,
    'patient_id': patientId,
    'type': type.name,
    'occurred_at': occurredAt.toIso8601String(),
    'performed_by': performedBy,
    'from_ward_id': fromWardId,
    'from_bed_id': fromBedId,
    'to_ward_id': toWardId,
    'to_bed_id': toBedId,
    'note': note,
  };
}
