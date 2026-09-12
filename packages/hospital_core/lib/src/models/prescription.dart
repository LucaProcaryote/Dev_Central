import 'package:flutter/foundation.dart';

import '../util/json.dart';
import '../util/localized_text.dart';
import 'codes.dart';

/// A medicinal product as it appears in the hospital formulary.
@immutable
class Medication {
  const Medication({
    required this.code,
    required this.name,
    required this.form,
    required this.strength,
    required this.atcCode,
    this.isControlled = false,
  });

  /// Internal formulary code (CNK-like), e.g. `MED-0142`.
  final String code;
  final LocalizedText name;

  /// Galenic form: tablet, solution for injection, ...
  final LocalizedText form;

  /// e.g. `500 mg`, `1 g/10 mL`.
  final String strength;

  /// WHO Anatomical Therapeutic Chemical code.
  final String atcCode;

  /// Controlled substances need a witnessed, logged release from the cabinet.
  final bool isControlled;

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
        code: asString(json['code']),
        name: LocalizedText.fromJson(json['name']),
        form: LocalizedText.fromJson(json['form']),
        strength: asString(json['strength']),
        atcCode: asString(json['atc_code'] ?? json['atcCode']),
        isControlled: asBool(json['is_controlled'] ?? json['isControlled']),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'code': code,
        'name': name.toJson(),
        'form': form.toJson(),
        'strength': strength,
        'atc_code': atcCode,
        'is_controlled': isControlled,
      };

  Map<String, dynamic> toFhirCodeableConcept() => <String, dynamic>{
        'coding': <dynamic>[
          <String, dynamic>{
            'system': CodeSystems.atc,
            'code': atcCode,
            'display': name.en,
          }
        ],
        'text': '${name.en} $strength',
      };
}

/// A prescription (FHIR `MedicationRequest`).
@immutable
class Prescription {
  const Prescription({
    required this.id,
    required this.patientId,
    required this.medication,
    required this.doseQuantity,
    required this.doseUnit,
    required this.frequencyPerDay,
    required this.route,
    required this.startDate,
    required this.prescriber,
    required this.status,
    this.encounterId,
    this.endDate,
    this.instructions,
    this.isPrn = false,
    this.indication,
  });

  final String id;
  final String patientId;
  final Medication medication;

  /// Amount per administration, e.g. `1` (tablet) or `500` (mg).
  final double doseQuantity;
  final String doseUnit;

  /// How many times a day, e.g. `3` for TID.
  final int frequencyPerDay;

  final MedicationRoute route;
  final DateTime startDate;
  final String prescriber;
  final PrescriptionStatus status;

  final String? encounterId;
  final DateTime? endDate;
  final String? instructions;

  /// "As needed" (pro re nata) - given on demand rather than on schedule.
  final bool isPrn;

  final String? indication;

  bool get isActive => status == PrescriptionStatus.active;

  /// Total number of administrations still expected today.
  int get dailyAdministrations => isPrn ? 0 : frequencyPerDay;

  /// Human-readable dosage line, e.g. `1 tablet, 3x/day, oral`.
  String dosageText(String languageCode) {
    final dose = doseQuantity == doseQuantity.roundToDouble()
        ? doseQuantity.toStringAsFixed(0)
        : doseQuantity.toString();
    final frequency = isPrn
        ? switch (languageCode) {
            'fr' => 'si besoin',
            'nl' => 'zo nodig',
            _ => 'as needed',
          }
        : switch (languageCode) {
            'fr' => '${frequencyPerDay}x/jour',
            'nl' => '${frequencyPerDay}x/dag',
            _ => '${frequencyPerDay}x/day',
          };
    return '$dose $doseUnit, $frequency, ${route.display.forLanguage(languageCode).toLowerCase()}';
  }

  Prescription copyWith({
    PrescriptionStatus? status,
    DateTime? endDate,
    String? instructions,
  }) =>
      Prescription(
        id: id,
        patientId: patientId,
        medication: medication,
        doseQuantity: doseQuantity,
        doseUnit: doseUnit,
        frequencyPerDay: frequencyPerDay,
        route: route,
        startDate: startDate,
        prescriber: prescriber,
        status: status ?? this.status,
        encounterId: encounterId,
        endDate: endDate ?? this.endDate,
        instructions: instructions ?? this.instructions,
        isPrn: isPrn,
        indication: indication,
      );

  factory Prescription.fromJson(Map<String, dynamic> json) => Prescription(
        id: asString(json['id']),
        patientId: asString(json['patient_id'] ?? json['patientId']),
        medication: Medication.fromJson(
          (json['medication'] as Map?)?.cast<String, dynamic>() ??
              const <String, dynamic>{},
        ),
        doseQuantity: asDouble(json['dose_quantity'] ?? json['doseQuantity']),
        doseUnit: asString(json['dose_unit'] ?? json['doseUnit']),
        frequencyPerDay:
            asInt(json['frequency_per_day'] ?? json['frequencyPerDay'], fallback: 1),
        route: MedicationRoute.fromName(asString(json['route'], fallback: 'oral')),
        startDate: asDateTime(json['start_date'] ?? json['startDate']),
        prescriber: asString(json['prescriber']),
        status: PrescriptionStatus.fromFhir(asString(json['status'])),
        encounterId: asStringOrNull(json['encounter_id'] ?? json['encounterId']),
        endDate: asDateTimeOrNull(json['end_date'] ?? json['endDate']),
        instructions: asStringOrNull(json['instructions']),
        isPrn: asBool(json['is_prn'] ?? json['isPrn']),
        indication: asStringOrNull(json['indication']),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'patient_id': patientId,
        'medication': medication.toJson(),
        'dose_quantity': doseQuantity,
        'dose_unit': doseUnit,
        'frequency_per_day': frequencyPerDay,
        'route': route.name,
        'start_date': startDate.toIso8601String(),
        'prescriber': prescriber,
        'status': status.fhirCode,
        'encounter_id': encounterId,
        'end_date': endDate?.toIso8601String(),
        'instructions': instructions,
        'is_prn': isPrn,
        'indication': indication,
      };

  Map<String, dynamic> toFhir() => pruneNulls(<String, dynamic>{
        'resourceType': 'MedicationRequest',
        'id': id,
        'status': status.fhirCode,
        'intent': 'order',
        'medicationCodeableConcept': medication.toFhirCodeableConcept(),
        'subject': <String, dynamic>{'reference': 'Patient/$patientId'},
        if (encounterId != null)
          'encounter': <String, dynamic>{'reference': 'Encounter/$encounterId'},
        'authoredOn': toFhirDateTime(startDate),
        'requester': <String, dynamic>{'display': prescriber},
        if (indication != null)
          'reasonCode': <dynamic>[
            <String, dynamic>{'text': indication}
          ],
        'dosageInstruction': <dynamic>[
          pruneNulls(<String, dynamic>{
            'text': dosageText('en'),
            'asNeededBoolean': isPrn,
            if (instructions != null) 'patientInstruction': instructions,
            'timing': <String, dynamic>{
              'repeat': <String, dynamic>{
                'frequency': frequencyPerDay,
                'period': 1,
                'periodUnit': 'd',
                if (endDate != null)
                  'boundsPeriod': <String, dynamic>{
                    'start': toFhirDateTime(startDate),
                    'end': toFhirDateTime(endDate!),
                  },
              },
            },
            'route': <String, dynamic>{
              'coding': <dynamic>[
                <String, dynamic>{
                  'system': CodeSystems.snomed,
                  'code': route.snomedCode,
                  'display': route.display.en,
                }
              ],
            },
            'doseAndRate': <dynamic>[
              <String, dynamic>{
                'doseQuantity': <String, dynamic>{
                  'value': doseQuantity,
                  'unit': doseUnit,
                  'system': CodeSystems.ucum,
                  'code': doseUnit,
                },
              }
            ],
          })
        ],
      });
}

/// A dispensing event from the pharmacy cabinet (FHIR `MedicationDispense`).
@immutable
class Dispense {
  const Dispense({
    required this.id,
    required this.prescriptionId,
    required this.patientId,
    required this.quantity,
    required this.status,
    required this.requestedAt,
    this.dispensedAt,
    this.dispensedBy,
    this.cabinetId,
    this.slot,
    this.refusalReason,
    this.lotNumber,
  });

  final String id;
  final String prescriptionId;
  final String patientId;
  final double quantity;
  final DispenseStatus status;
  final DateTime requestedAt;
  final DateTime? dispensedAt;
  final String? dispensedBy;
  final String? cabinetId;

  /// Physical drawer/slot the cabinet opened, e.g. `B-14`.
  final String? slot;

  final String? refusalReason;
  final String? lotNumber;

  Dispense copyWith({
    DispenseStatus? status,
    DateTime? dispensedAt,
    String? dispensedBy,
    String? refusalReason,
    String? lotNumber,
  }) =>
      Dispense(
        id: id,
        prescriptionId: prescriptionId,
        patientId: patientId,
        quantity: quantity,
        status: status ?? this.status,
        requestedAt: requestedAt,
        dispensedAt: dispensedAt ?? this.dispensedAt,
        dispensedBy: dispensedBy ?? this.dispensedBy,
        cabinetId: cabinetId,
        slot: slot,
        refusalReason: refusalReason ?? this.refusalReason,
        lotNumber: lotNumber ?? this.lotNumber,
      );

  factory Dispense.fromJson(Map<String, dynamic> json) => Dispense(
        id: asString(json['id']),
        prescriptionId:
            asString(json['prescription_id'] ?? json['prescriptionId']),
        patientId: asString(json['patient_id'] ?? json['patientId']),
        quantity: asDouble(json['quantity']),
        status: DispenseStatus.fromName(
          asString(json['status'], fallback: 'requested'),
        ),
        requestedAt: asDateTime(json['requested_at'] ?? json['requestedAt']),
        dispensedAt: asDateTimeOrNull(json['dispensed_at'] ?? json['dispensedAt']),
        dispensedBy: asStringOrNull(json['dispensed_by'] ?? json['dispensedBy']),
        cabinetId: asStringOrNull(json['cabinet_id'] ?? json['cabinetId']),
        slot: asStringOrNull(json['slot']),
        refusalReason:
            asStringOrNull(json['refusal_reason'] ?? json['refusalReason']),
        lotNumber: asStringOrNull(json['lot_number'] ?? json['lotNumber']),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'prescription_id': prescriptionId,
        'patient_id': patientId,
        'quantity': quantity,
        'status': status.name,
        'requested_at': requestedAt.toIso8601String(),
        'dispensed_at': dispensedAt?.toIso8601String(),
        'dispensed_by': dispensedBy,
        'cabinet_id': cabinetId,
        'slot': slot,
        'refusal_reason': refusalReason,
        'lot_number': lotNumber,
      };

  Map<String, dynamic> toFhir() => pruneNulls(<String, dynamic>{
        'resourceType': 'MedicationDispense',
        'id': id,
        'status': status.fhirCode,
        'subject': <String, dynamic>{'reference': 'Patient/$patientId'},
        'authorizingPrescription': <dynamic>[
          <String, dynamic>{'reference': 'MedicationRequest/$prescriptionId'}
        ],
        'quantity': <String, dynamic>{'value': quantity},
        if (dispensedAt != null) 'whenHandedOver': toFhirDateTime(dispensedAt!),
        if (dispensedBy != null)
          'performer': <dynamic>[
            <String, dynamic>{
              'actor': <String, dynamic>{'display': dispensedBy},
            }
          ],
      });
}
