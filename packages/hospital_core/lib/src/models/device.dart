import 'package:flutter/foundation.dart';

import '../util/json.dart';
import '../util/localized_text.dart';
import 'codes.dart';

/// What a connected device measures. One simulator can carry several.
enum DeviceKind {
  weightScale(
    LocalizedText(en: 'Weight scale', fr: 'Balance', nl: 'Weegschaal'),
    <VitalSignType>[VitalSignType.bodyWeight],
    '469',
  ),
  thermometer(
    LocalizedText(en: 'Thermometer', fr: 'Thermomètre', nl: 'Thermometer'),
    <VitalSignType>[VitalSignType.bodyTemperature],
    '448',
  ),
  cardiacMonitor(
    LocalizedText(en: 'Cardiac monitor', fr: 'Moniteur cardiaque', nl: 'Hartmonitor'),
    <VitalSignType>[VitalSignType.heartRate, VitalSignType.respiratoryRate],
    '347',
  ),
  pulseOximeter(
    LocalizedText(en: 'Pulse oximeter', fr: 'Oxymètre de pouls', nl: 'Pulsoximeter'),
    <VitalSignType>[VitalSignType.oxygenSaturation, VitalSignType.heartRate],
    '448',
  ),
  activityTracker(
    LocalizedText(en: 'Activity tracker', fr: "Traceur d'activité", nl: 'Activiteitentracker'),
    <VitalSignType>[VitalSignType.activitySteps, VitalSignType.heartRate],
    '625',
  ),
  bloodPressureMonitor(
    LocalizedText(en: 'Blood pressure monitor', fr: 'Tensiomètre', nl: 'Bloeddrukmeter'),
    <VitalSignType>[
      VitalSignType.systolicBloodPressure,
      VitalSignType.diastolicBloodPressure,
      VitalSignType.heartRate,
    ],
    '902',
  ),
  multiparameter(
    LocalizedText(
      en: 'Multiparameter monitor',
      fr: 'Moniteur multiparamétrique',
      nl: 'Multiparametermonitor',
    ),
    <VitalSignType>[
      VitalSignType.heartRate,
      VitalSignType.oxygenSaturation,
      VitalSignType.bodyTemperature,
      VitalSignType.respiratoryRate,
    ],
    '347',
  );

  const DeviceKind(this.display, this.measures, this.mdcCode);

  final LocalizedText display;

  /// The vital signs this device can emit.
  final List<VitalSignType> measures;

  /// ISO/IEEE 11073-10101 (MDC) device type code - what a real medical device
  /// gateway would report.
  final String mdcCode;

  static DeviceKind fromName(String value) => values.firstWhere(
        (k) => k.name == value,
        orElse: () => DeviceKind.multiparameter,
      );
}

/// Operational state of a device.
enum DeviceStatus {
  active(LocalizedText(en: 'Active', fr: 'Actif', nl: 'Actief')),
  standby(LocalizedText(en: 'Standby', fr: 'En veille', nl: 'Stand-by')),
  maintenance(LocalizedText(en: 'Maintenance', fr: 'Maintenance', nl: 'Onderhoud')),
  offline(LocalizedText(en: 'Offline', fr: 'Hors ligne', nl: 'Offline'));

  const DeviceStatus(this.display);
  final LocalizedText display;

  static DeviceStatus fromName(String value) => values.firstWhere(
        (s) => s.name == value,
        orElse: () => DeviceStatus.offline,
      );
}

/// A connected medical device (FHIR `Device`).
///
/// In the classroom each student runs one of these as a simulator, identified
/// by [code] (`DEV1`..`DEV10`).
@immutable
class MedicalDevice {
  const MedicalDevice({
    required this.id,
    required this.code,
    required this.kind,
    required this.manufacturer,
    required this.model,
    required this.serialNumber,
    required this.status,
    this.assignedPatientId,
    this.assignedBedId,
    this.wardId,
    this.lastSeenAt,
    this.batteryPercent,
    this.ownerStudent,
  });

  final String id;

  /// `DEV1`..`DEV10`, or `APPLE-WATCH-<n>` for HealthKit sources.
  final String code;
  final DeviceKind kind;
  final String manufacturer;
  final String model;
  final String serialNumber;
  final DeviceStatus status;

  final String? assignedPatientId;
  final String? assignedBedId;
  final String? wardId;
  final DateTime? lastSeenAt;
  final int? batteryPercent;

  /// Name of the student operating this simulator, shown on the fleet board.
  final String? ownerStudent;

  bool get isConnected => status == DeviceStatus.active;

  /// A device is stale if it has not reported in the last two minutes.
  bool get isStale {
    if (lastSeenAt == null) return true;
    return DateTime.now().difference(lastSeenAt!) > const Duration(minutes: 2);
  }

  MedicalDevice copyWith({
    DeviceStatus? status,
    String? assignedPatientId,
    String? assignedBedId,
    String? wardId,
    DateTime? lastSeenAt,
    int? batteryPercent,
    bool clearAssignment = false,
  }) =>
      MedicalDevice(
        id: id,
        code: code,
        kind: kind,
        manufacturer: manufacturer,
        model: model,
        serialNumber: serialNumber,
        status: status ?? this.status,
        assignedPatientId:
            clearAssignment ? null : (assignedPatientId ?? this.assignedPatientId),
        assignedBedId:
            clearAssignment ? null : (assignedBedId ?? this.assignedBedId),
        wardId: wardId ?? this.wardId,
        lastSeenAt: lastSeenAt ?? this.lastSeenAt,
        batteryPercent: batteryPercent ?? this.batteryPercent,
        ownerStudent: ownerStudent,
      );

  factory MedicalDevice.fromJson(Map<String, dynamic> json) => MedicalDevice(
        id: asString(json['id']),
        code: asString(json['code']),
        kind: DeviceKind.fromName(asString(json['kind'])),
        manufacturer: asString(json['manufacturer']),
        model: asString(json['model']),
        serialNumber: asString(json['serial_number'] ?? json['serialNumber']),
        status: DeviceStatus.fromName(asString(json['status'], fallback: 'offline')),
        assignedPatientId: asStringOrNull(
          json['assigned_patient_id'] ?? json['assignedPatientId'],
        ),
        assignedBedId:
            asStringOrNull(json['assigned_bed_id'] ?? json['assignedBedId']),
        wardId: asStringOrNull(json['ward_id'] ?? json['wardId']),
        lastSeenAt: asDateTimeOrNull(json['last_seen_at'] ?? json['lastSeenAt']),
        batteryPercent:
            asIntOrNull(json['battery_percent'] ?? json['batteryPercent']),
        ownerStudent:
            asStringOrNull(json['owner_student'] ?? json['ownerStudent']),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'code': code,
        'kind': kind.name,
        'manufacturer': manufacturer,
        'model': model,
        'serial_number': serialNumber,
        'status': status.name,
        'assigned_patient_id': assignedPatientId,
        'assigned_bed_id': assignedBedId,
        'ward_id': wardId,
        'last_seen_at': lastSeenAt?.toIso8601String(),
        'battery_percent': batteryPercent,
        'owner_student': ownerStudent,
      };

  Map<String, dynamic> toFhir() => pruneNulls(<String, dynamic>{
        'resourceType': 'Device',
        'id': id,
        'identifier': <dynamic>[
          <String, dynamic>{
            'system': CodeSystems.localDevice,
            'value': code,
          }
        ],
        'status': status == DeviceStatus.offline ? 'inactive' : 'active',
        'manufacturer': manufacturer,
        'serialNumber': serialNumber,
        'deviceName': <dynamic>[
          <String, dynamic>{'name': model, 'type': 'model-name'}
        ],
        'type': <String, dynamic>{
          'coding': <dynamic>[
            <String, dynamic>{
              'system': 'urn:iso:std:iso:11073:10101',
              'code': kind.mdcCode,
              'display': kind.display.en,
            }
          ],
          'text': kind.display.en,
        },
        if (assignedPatientId != null)
          'patient': <String, dynamic>{'reference': 'Patient/$assignedPatientId'},
        if (assignedBedId != null)
          'location': <String, dynamic>{'reference': 'Location/$assignedBedId'},
      });
}
