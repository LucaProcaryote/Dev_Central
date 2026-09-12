import '../models/pharmacy.dart';
import '../util/localized_text.dart';
import 'seed_formulary.dart';

/// One automated dispensing cabinet per clinical ward.
const List<Cabinet> seedCabinets = <Cabinet>[
  Cabinet(
    id: 'cab-card',
    code: 'CAB-CARD-1',
    name: LocalizedText(
      en: 'Cardiology cabinet',
      fr: 'Armoire cardiologie',
      nl: 'Kast cardiologie',
    ),
    wardId: 'ward-card',
    isLocked: true,
  ),
  Cabinet(
    id: 'cab-int',
    code: 'CAB-INT-1',
    name: LocalizedText(
      en: 'Internal medicine cabinet',
      fr: 'Armoire médecine interne',
      nl: 'Kast interne geneeskunde',
    ),
    wardId: 'ward-int',
    isLocked: true,
  ),
  Cabinet(
    id: 'cab-icu',
    code: 'CAB-ICU-1',
    name: LocalizedText(
      en: 'Intensive care cabinet',
      fr: 'Armoire soins intensifs',
      nl: 'Kast intensieve zorgen',
    ),
    wardId: 'ward-icu',
    isLocked: true,
    temperatureCelsius: 4.2,
  ),
  Cabinet(
    id: 'cab-ped',
    code: 'CAB-PED-1',
    name: LocalizedText(
      en: 'Paediatrics cabinet',
      fr: 'Armoire pédiatrie',
      nl: 'Kast pediatrie',
    ),
    wardId: 'ward-ped',
    isLocked: true,
  ),
  Cabinet(
    id: 'cab-surg',
    code: 'CAB-SURG-1',
    name: LocalizedText(
      en: 'Surgery cabinet',
      fr: 'Armoire chirurgie',
      nl: 'Kast chirurgie',
    ),
    wardId: 'ward-surg',
    isLocked: true,
  ),
  Cabinet(
    id: 'cab-geri',
    code: 'CAB-GERI-1',
    name: LocalizedText(
      en: 'Geriatrics cabinet',
      fr: 'Armoire gériatrie',
      nl: 'Kast geriatrie',
    ),
    wardId: 'ward-geri',
    isLocked: true,
  ),
  Cabinet(
    id: 'cab-emer',
    code: 'CAB-EMER-1',
    name: LocalizedText(
      en: 'Emergency cabinet',
      fr: 'Armoire urgences',
      nl: 'Kast spoedgevallen',
    ),
    wardId: 'ward-emer',
    isLocked: false,
  ),
];

/// Fills every cabinet with the formulary.
///
/// Quantities are staged on purpose so the pharmacy screen has something to
/// say the moment it opens: a handful of slots sit at or below their par level,
/// one lot is already expired and two are close to it. Students should find
/// those without being told where they are.
List<StockItem> buildSeedStock(DateTime now) {
  final items = <StockItem>[];
  const rows = <String>['A', 'B', 'C', 'D'];
  var lotCounter = 0;

  for (final cabinet in seedCabinets) {
    var index = 0;
    for (final medication in seedFormulary) {
      // The emergency cabinet carries a narrower range.
      if (cabinet.id == 'cab-emer' && index >= 10) break;
      // Controlled substances only live where they are actually used.
      if (medication.isControlled &&
          !<String>['cab-icu', 'cab-surg', 'cab-emer'].contains(cabinet.id)) {
        index++;
        continue;
      }

      final row = rows[index % rows.length];
      final slotNumber = (index ~/ rows.length) + 1;
      lotCounter++;

      // A deterministic spread of stock levels, seeded off the slot position so
      // the same cabinet always looks the same between runs.
      final seed = (cabinet.code.hashCode ^ medication.code.hashCode).abs();
      final par = medication.isControlled ? 5 : 10 + (seed % 3) * 5;
      var quantity = par * 2 + (seed % 17);
      if (seed % 11 == 0) quantity = par;
      if (seed % 23 == 0) quantity = par ~/ 2;
      if (seed % 47 == 0) quantity = 0;

      var expiry = now.add(Duration(days: 90 + (seed % 600)));
      if (seed % 37 == 0) expiry = now.add(Duration(days: 8 + (seed % 20)));
      if (seed % 89 == 0) {
        expiry = now.subtract(Duration(days: 3 + (seed % 40)));
      }

      items.add(
        StockItem(
          id: '${cabinet.id}-${medication.code}',
          cabinetId: cabinet.id,
          slot: '$row-${slotNumber.toString().padLeft(2, '0')}',
          medication: medication,
          quantityOnHand: quantity,
          parLevel: par,
          expiryDate: expiry,
          lotNumber: 'LOT${(240000 + lotCounter * 13).toString()}',
        ),
      );
      index++;
    }
  }
  return items;
}
