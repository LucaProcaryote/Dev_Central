import 'package:flutter/foundation.dart';

import '../util/json.dart';
import '../util/localized_text.dart';
import 'prescription.dart';

/// A physical automated dispensing cabinet on a ward.
@immutable
class Cabinet {
  const Cabinet({
    required this.id,
    required this.code,
    required this.name,
    required this.wardId,
    required this.isLocked,
    this.temperatureCelsius,
  });

  final String id;

  /// e.g. `CAB-CARD-1`.
  final String code;
  final LocalizedText name;
  final String wardId;

  /// A locked cabinet refuses every drawer-open command until a user with the
  /// pharmacist or nurse role authenticates.
  final bool isLocked;

  /// Cabinets holding cold-chain products report their internal temperature.
  final double? temperatureCelsius;

  Cabinet copyWith({bool? isLocked, double? temperatureCelsius}) => Cabinet(
    id: id,
    code: code,
    name: name,
    wardId: wardId,
    isLocked: isLocked ?? this.isLocked,
    temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
  );

  factory Cabinet.fromJson(Map<String, dynamic> json) => Cabinet(
    id: asString(json['id']),
    code: asString(json['code']),
    name: LocalizedText.fromJson(json['name']),
    wardId: asString(json['ward_id'] ?? json['wardId']),
    isLocked: asBool(json['is_locked'] ?? json['isLocked'], fallback: true),
    temperatureCelsius: asDoubleOrNull(
      json['temperature_celsius'] ?? json['temperatureCelsius'],
    ),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'code': code,
    'name': name.toJson(),
    'ward_id': wardId,
    'is_locked': isLocked,
    'temperature_celsius': temperatureCelsius,
  };
}

/// One drawer/slot of a cabinet, holding a quantity of one medication.
@immutable
class StockItem {
  const StockItem({
    required this.id,
    required this.cabinetId,
    required this.slot,
    required this.medication,
    required this.quantityOnHand,
    required this.parLevel,
    required this.expiryDate,
    required this.lotNumber,
    this.isDrawerOpen = false,
  });

  final String id;
  final String cabinetId;

  /// Drawer label, e.g. `B-14`.
  final String slot;
  final Medication medication;
  final int quantityOnHand;

  /// Reorder threshold. Below this the cabinet raises a restock alert.
  final int parLevel;

  final DateTime expiryDate;
  final String lotNumber;

  /// Transient: true while the simulated drawer is physically open.
  final bool isDrawerOpen;

  bool get isLow => quantityOnHand <= parLevel;
  bool get isEmpty => quantityOnHand <= 0;
  bool get isExpired => expiryDate.isBefore(DateTime.now());

  /// Expiring within 30 days - the pharmacist wants these used first.
  bool get isNearExpiry =>
      !isExpired && expiryDate.difference(DateTime.now()).inDays <= 30;

  StockItem copyWith({int? quantityOnHand, bool? isDrawerOpen}) => StockItem(
    id: id,
    cabinetId: cabinetId,
    slot: slot,
    medication: medication,
    quantityOnHand: quantityOnHand ?? this.quantityOnHand,
    parLevel: parLevel,
    expiryDate: expiryDate,
    lotNumber: lotNumber,
    isDrawerOpen: isDrawerOpen ?? this.isDrawerOpen,
  );

  factory StockItem.fromJson(Map<String, dynamic> json) => StockItem(
    id: asString(json['id']),
    cabinetId: asString(json['cabinet_id'] ?? json['cabinetId']),
    slot: asString(json['slot']),
    medication: Medication.fromJson(
      (json['medication'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
    ),
    quantityOnHand: asInt(json['quantity_on_hand'] ?? json['quantityOnHand']),
    parLevel: asInt(json['par_level'] ?? json['parLevel']),
    expiryDate: asDateTime(json['expiry_date'] ?? json['expiryDate']),
    lotNumber: asString(json['lot_number'] ?? json['lotNumber']),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'cabinet_id': cabinetId,
    'slot': slot,
    'medication': medication.toJson(),
    'quantity_on_hand': quantityOnHand,
    'par_level': parLevel,
    'expiry_date': expiryDate.toIso8601String(),
    'lot_number': lotNumber,
  };
}

/// Why a dispense request cannot be honoured. Returned by the pharmacy service
/// so the interface can explain the refusal in the user's language.
enum DispenseBlocker {
  outOfStock,
  expiredLot,
  cabinetLocked,
  prescriptionNotActive,
  allergyConflict,
  controlledSubstanceNeedsWitness,
}
