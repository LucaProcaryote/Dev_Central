import '../models/codes.dart';
import '../models/patient.dart';
import '../models/pharmacy.dart';
import '../models/prescription.dart';
import '../util/localized_text.dart';

/// A safety problem found before a drug is prescribed or handed over.
class SafetyAlert {
  const SafetyAlert({
    required this.severity,
    required this.title,
    required this.detail,
    this.blocker,
  });

  final SafetySeverity severity;
  final LocalizedText title;
  final LocalizedText detail;

  /// Set when the alert corresponds to a hard stop in the pharmacy workflow.
  final DispenseBlocker? blocker;

  bool get isBlocking => severity == SafetySeverity.blocking;
}

enum SafetySeverity {
  /// The action is refused outright.
  blocking,

  /// The action may proceed, but the user must acknowledge the alert first.
  warning,

  /// Worth saying; no acknowledgement required.
  advisory,
}

/// The clinical safety checks the prescribing and dispensing screens share.
///
/// Deliberately simple and readable: substring matching on the drug name and
/// on the allergy substance, in all three languages. A production system would
/// use a drug knowledge base with ingredient-level and cross-reactivity data,
/// which is exactly the discussion these functions are meant to start - the
/// limitation is the lesson, so it is documented rather than hidden.
class SafetyChecks {
  const SafetyChecks._();

  /// Allergy alerts raised by giving [medication] to [patient].
  static List<SafetyAlert> allergyAlerts({
    required Patient patient,
    required Medication medication,
  }) {
    final alerts = <SafetyAlert>[];
    final names = <String>[
      medication.name.en.toLowerCase(),
      medication.name.fr.toLowerCase(),
      medication.name.nl.toLowerCase(),
    ];

    for (final allergy in patient.allergies) {
      final substances = <String>[
        allergy.substance.en.toLowerCase(),
        allergy.substance.fr.toLowerCase(),
        allergy.substance.nl.toLowerCase(),
      ];

      final matches = names.any(
        (name) => substances.any(
          (substance) =>
              substance.length >= 4 &&
              (name.contains(substance) || substance.contains(name)),
        ),
      );

      // Beta-lactams cross-react: a penicillin allergy is a reason to think
      // twice about any of them, not only about penicillin itself.
      final crossReacts =
          _isBetaLactam(medication) &&
          substances.any((s) => s.contains('penicill'));

      if (!matches && !crossReacts) continue;

      alerts.add(
        SafetyAlert(
          severity: allergy.criticality == AllergyCriticality.high
              ? SafetySeverity.blocking
              : SafetySeverity.warning,
          title: LocalizedText(
            en: 'Allergy: ${allergy.substance.en}',
            fr: 'Allergie : ${allergy.substance.fr}',
            nl: 'Allergie: ${allergy.substance.nl}',
          ),
          detail: crossReacts && !matches
              ? LocalizedText(
                  en:
                      '${medication.name.en} is a beta-lactam and may '
                      'cross-react with the recorded penicillin allergy '
                      '(${allergy.reaction.en}).',
                  fr:
                      '${medication.name.fr} est un bêta-lactame et peut '
                      'présenter une réaction croisée avec l\'allergie '
                      'documentée à la pénicilline (${allergy.reaction.fr}).',
                  nl:
                      '${medication.name.nl} is een bèta-lactam en kan '
                      'kruisreageren met de geregistreerde penicilline-allergie '
                      '(${allergy.reaction.nl}).',
                )
              : LocalizedText(
                  en: 'Recorded reaction: ${allergy.reaction.en}.',
                  fr: 'Réaction documentée : ${allergy.reaction.fr}.',
                  nl: 'Geregistreerde reactie: ${allergy.reaction.nl}.',
                ),
          blocker: DispenseBlocker.allergyConflict,
        ),
      );
    }
    return alerts;
  }

  /// Whether the product belongs to the beta-lactam family, read off its ATC
  /// code: J01C is penicillins, J01D the other beta-lactams.
  static bool _isBetaLactam(Medication medication) =>
      medication.atcCode.startsWith('J01C') ||
      medication.atcCode.startsWith('J01D');

  /// Everything standing between a dispense request and the drawer opening.
  ///
  /// Returns an empty list when the dose may be handed over.
  static List<SafetyAlert> dispenseBlockers({
    required Patient patient,
    required Prescription prescription,
    required Cabinet cabinet,
    required StockItem? stock,
    required double quantity,
  }) {
    final alerts = <SafetyAlert>[];

    if (cabinet.isLocked) {
      alerts.add(
        const SafetyAlert(
          severity: SafetySeverity.blocking,
          title: LocalizedText(
            en: 'Cabinet locked',
            fr: 'Armoire verrouillée',
            nl: 'Kast vergrendeld',
          ),
          detail: LocalizedText(
            en: 'Unlock the cabinet before dispensing.',
            fr: 'Déverrouillez l\'armoire avant de délivrer.',
            nl: 'Ontgrendel de kast voordat u aflevert.',
          ),
          blocker: DispenseBlocker.cabinetLocked,
        ),
      );
    }

    if (prescription.status != PrescriptionStatus.active) {
      alerts.add(
        const SafetyAlert(
          severity: SafetySeverity.blocking,
          title: LocalizedText(
            en: 'Prescription not active',
            fr: 'Prescription non active',
            nl: 'Voorschrift niet actief',
          ),
          detail: LocalizedText(
            en: 'Only an active prescription can be dispensed against.',
            fr: 'Seule une prescription active peut donner lieu à une délivrance.',
            nl: 'Alleen tegen een actief voorschrift kan worden afgeleverd.',
          ),
          blocker: DispenseBlocker.prescriptionNotActive,
        ),
      );
    }

    if (stock == null || stock.quantityOnHand <= 0) {
      alerts.add(
        const SafetyAlert(
          severity: SafetySeverity.blocking,
          title: LocalizedText(
            en: 'Out of stock',
            fr: 'Rupture de stock',
            nl: 'Niet op voorraad',
          ),
          detail: LocalizedText(
            en: 'The slot is empty. Restock before dispensing.',
            fr: 'L\'emplacement est vide. Réapprovisionnez avant de délivrer.',
            nl: 'Het vak is leeg. Vul aan voordat u aflevert.',
          ),
          blocker: DispenseBlocker.outOfStock,
        ),
      );
    } else {
      if (stock.isExpired) {
        alerts.add(
          const SafetyAlert(
            severity: SafetySeverity.blocking,
            title: LocalizedText(
              en: 'Expired lot',
              fr: 'Lot périmé',
              nl: 'Vervallen lot',
            ),
            detail: LocalizedText(
              en: 'This lot is past its expiry date and must be withdrawn.',
              fr: 'Ce lot a dépassé sa date de péremption et doit être retiré.',
              nl: 'Dit lot is over de vervaldatum en moet worden teruggenomen.',
            ),
            blocker: DispenseBlocker.expiredLot,
          ),
        );
      } else if (stock.isNearExpiry) {
        alerts.add(
          const SafetyAlert(
            severity: SafetySeverity.advisory,
            title: LocalizedText(
              en: 'Expires soon',
              fr: 'Périme bientôt',
              nl: 'Vervalt binnenkort',
            ),
            detail: LocalizedText(
              en: 'Use this lot first.',
              fr: 'Utilisez ce lot en priorité.',
              nl: 'Gebruik dit lot als eerste.',
            ),
          ),
        );
      }

      if (quantity > stock.quantityOnHand) {
        alerts.add(
          SafetyAlert(
            severity: SafetySeverity.blocking,
            title: const LocalizedText(
              en: 'Not enough stock',
              fr: 'Stock insuffisant',
              nl: 'Onvoldoende voorraad',
            ),
            detail: LocalizedText(
              en: 'Only ${stock.quantityOnHand} left in slot ${stock.slot}.',
              fr:
                  'Il ne reste que ${stock.quantityOnHand} dans '
                  'l\'emplacement ${stock.slot}.',
              nl:
                  'Er zijn er nog maar ${stock.quantityOnHand} in vak '
                  '${stock.slot}.',
            ),
            blocker: DispenseBlocker.outOfStock,
          ),
        );
      }
    }

    alerts.addAll(
      allergyAlerts(patient: patient, medication: prescription.medication),
    );

    if (prescription.medication.isControlled) {
      alerts.add(
        const SafetyAlert(
          severity: SafetySeverity.warning,
          title: LocalizedText(
            en: 'Controlled substance',
            fr: 'Stupéfiant',
            nl: 'Verdovend middel',
          ),
          detail: LocalizedText(
            en: 'A witness must countersign this release.',
            fr: 'Un témoin doit contresigner cette délivrance.',
            nl: 'Een getuige moet deze aflevering medeondertekenen.',
          ),
          blocker: DispenseBlocker.controlledSubstanceNeedsWitness,
        ),
      );
    }

    return alerts;
  }

  /// Duplicate-therapy check: another active prescription for the same product.
  static List<SafetyAlert> duplicateTherapy({
    required Medication medication,
    required List<Prescription> activePrescriptions,
  }) {
    final duplicates = activePrescriptions
        .where((p) => p.medication.code == medication.code)
        .toList();
    if (duplicates.isEmpty) return const <SafetyAlert>[];
    return <SafetyAlert>[
      SafetyAlert(
        severity: SafetySeverity.warning,
        title: const LocalizedText(
          en: 'Duplicate therapy',
          fr: 'Doublon thérapeutique',
          nl: 'Dubbele therapie',
        ),
        detail: LocalizedText(
          en: '${medication.name.en} is already prescribed for this patient.',
          fr: '${medication.name.fr} est déjà prescrit pour ce patient.',
          nl: '${medication.name.nl} is al voorgeschreven voor deze patiënt.',
        ),
      ),
    ];
  }
}
