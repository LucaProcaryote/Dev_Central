import 'package:flutter/foundation.dart';

import '../util/json.dart';
import '../util/localized_text.dart';
import 'codes.dart';

/// A nursing ward / unit (FHIR `Location`, physical type `wi`).
@immutable
class Ward {
  const Ward({
    required this.id,
    required this.code,
    required this.name,
    required this.floor,
    required this.specialty,
    this.phoneExtension,
  });

  final String id;

  /// Short code shown on bed boards, e.g. `CARD`, `PED`, `ICU`.
  final String code;
  final LocalizedText name;
  final int floor;
  final LocalizedText specialty;
  final String? phoneExtension;

  factory Ward.fromJson(Map<String, dynamic> json) => Ward(
        id: asString(json['id']),
        code: asString(json['code']),
        name: LocalizedText.fromJson(json['name']),
        floor: asInt(json['floor']),
        specialty: LocalizedText.fromJson(json['specialty']),
        phoneExtension:
            asStringOrNull(json['phone_extension'] ?? json['phoneExtension']),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'code': code,
        'name': name.toJson(),
        'floor': floor,
        'specialty': specialty.toJson(),
        'phone_extension': phoneExtension,
      };

  Map<String, dynamic> toFhir() => pruneNulls(<String, dynamic>{
        'resourceType': 'Location',
        'id': id,
        'identifier': <dynamic>[
          <String, dynamic>{
            'system': CodeSystems.localWard,
            'value': code,
          }
        ],
        'status': 'active',
        'name': name.en,
        'alias': <dynamic>[name.fr, name.nl],
        'mode': 'instance',
        'physicalType': <String, dynamic>{
          'coding': <dynamic>[
            <String, dynamic>{
              'system':
                  'http://terminology.hl7.org/CodeSystem/location-physical-type',
              'code': 'wi',
              'display': 'Wing',
            }
          ],
        },
      });
}

/// A room inside a ward.
@immutable
class Room {
  const Room({
    required this.id,
    required this.wardId,
    required this.number,
    required this.isIsolation,
  });

  final String id;
  final String wardId;
  final String number;

  /// Isolation rooms can only take one patient and are flagged in the UI.
  final bool isIsolation;

  factory Room.fromJson(Map<String, dynamic> json) => Room(
        id: asString(json['id']),
        wardId: asString(json['ward_id'] ?? json['wardId']),
        number: asString(json['number']),
        isIsolation: asBool(json['is_isolation'] ?? json['isIsolation']),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'ward_id': wardId,
        'number': number,
        'is_isolation': isIsolation,
      };
}

/// A physical bed - the unit of capacity the ADT application allocates.
@immutable
class Bed {
  const Bed({
    required this.id,
    required this.roomId,
    required this.wardId,
    required this.label,
    required this.status,
    this.currentEncounterId,
    this.currentPatientId,
  });

  final String id;
  final String roomId;
  final String wardId;

  /// Human label, e.g. `301-A`.
  final String label;
  final BedStatus status;

  /// Set while the bed is occupied; both are null otherwise.
  final String? currentEncounterId;
  final String? currentPatientId;

  bool get isAvailable => status == BedStatus.free;

  Bed copyWith({
    BedStatus? status,
    String? currentEncounterId,
    String? currentPatientId,
    bool clearOccupant = false,
  }) =>
      Bed(
        id: id,
        roomId: roomId,
        wardId: wardId,
        label: label,
        status: status ?? this.status,
        currentEncounterId:
            clearOccupant ? null : (currentEncounterId ?? this.currentEncounterId),
        currentPatientId:
            clearOccupant ? null : (currentPatientId ?? this.currentPatientId),
      );

  factory Bed.fromJson(Map<String, dynamic> json) => Bed(
        id: asString(json['id']),
        roomId: asString(json['room_id'] ?? json['roomId']),
        wardId: asString(json['ward_id'] ?? json['wardId']),
        label: asString(json['label']),
        status: BedStatus.fromName(asString(json['status'], fallback: 'free')),
        currentEncounterId: asStringOrNull(
          json['current_encounter_id'] ?? json['currentEncounterId'],
        ),
        currentPatientId: asStringOrNull(
          json['current_patient_id'] ?? json['currentPatientId'],
        ),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'room_id': roomId,
        'ward_id': wardId,
        'label': label,
        'status': status.name,
        'current_encounter_id': currentEncounterId,
        'current_patient_id': currentPatientId,
      };

  Map<String, dynamic> toFhir() => pruneNulls(<String, dynamic>{
        'resourceType': 'Location',
        'id': id,
        'status': status == BedStatus.blocked ? 'inactive' : 'active',
        'name': label,
        'mode': 'instance',
        'operationalStatus': <String, dynamic>{
          'system': 'http://terminology.hl7.org/CodeSystem/v2-0116',
          'code': switch (status) {
            BedStatus.free => 'U', // Unoccupied
            BedStatus.occupied => 'O', // Occupied
            BedStatus.cleaning => 'K', // Contaminated / housekeeping
            BedStatus.blocked => 'C', // Closed
          },
        },
        'physicalType': <String, dynamic>{
          'coding': <dynamic>[
            <String, dynamic>{
              'system':
                  'http://terminology.hl7.org/CodeSystem/location-physical-type',
              'code': 'bd',
              'display': 'Bed',
            }
          ],
        },
        'partOf': <String, dynamic>{'reference': 'Location/$roomId'},
      });
}

/// A bed together with the room and ward it belongs to - what the bed board
/// and the transfer picker actually need in one object.
@immutable
class BedPlacement {
  const BedPlacement({required this.bed, required this.room, required this.ward});

  final Bed bed;
  final Room room;
  final Ward ward;

  /// e.g. `Cardiology · 301 · 301-A`
  String describe(String languageCode) =>
      '${ward.name.forLanguage(languageCode)} · ${room.number} · ${bed.label}';
}
