import '../models/clinical_note.dart';
import '../models/codes.dart';
import '../models/encounter.dart';
import '../models/prescription.dart';
import 'seed_formulary.dart';

/// A patient's stay, described relative to "now" so the demo data never looks
/// stale: a hospital where every admission happened in 2023 is unconvincing.
class _Stay {
  const _Stay({
    required this.patientId,
    required this.wardId,
    required this.bedId,
    required this.encounterClass,
    required this.admittedHoursAgo,
    required this.reason,
    required this.admittingPractitioner,
    this.dischargedHoursAgo,
    this.dischargeDisposition,
  });

  final String patientId;
  final String wardId;
  final String bedId;
  final EncounterClass encounterClass;
  final int admittedHoursAgo;
  final String reason;
  final String admittingPractitioner;

  /// Null while the patient is still in the hospital.
  final int? dischargedHoursAgo;
  final String? dischargeDisposition;

  bool get isActive => dischargedHoursAgo == null;
}

const List<_Stay> _stays = <_Stay>[
  // ---- Currently in the hospital -------------------------------------------
  _Stay(
    patientId: 'pat-001',
    wardId: 'ward-card',
    bedId: 'bed-card-301a',
    encounterClass: EncounterClass.inpatient,
    admittedHoursAgo: 96,
    reason: 'Decompensated heart failure',
    admittingPractitioner: 'Dr. Anne Dubois',
  ),
  _Stay(
    patientId: 'pat-002',
    wardId: 'ward-int',
    bedId: 'bed-int-401a',
    encounterClass: EncounterClass.inpatient,
    admittedHoursAgo: 52,
    reason: 'Community-acquired pneumonia',
    admittingPractitioner: 'Dr. Jan Peeters',
  ),
  _Stay(
    patientId: 'pat-003',
    wardId: 'ward-surg',
    bedId: 'bed-surg-201a',
    encounterClass: EncounterClass.inpatient,
    admittedHoursAgo: 26,
    reason: 'Laparoscopic cholecystectomy',
    admittingPractitioner: 'Dr. Jan Peeters',
  ),
  _Stay(
    patientId: 'pat-005',
    wardId: 'ward-emer',
    bedId: 'bed-emer-1a',
    encounterClass: EncounterClass.emergency,
    admittedHoursAgo: 3,
    reason: 'Atypical chest pain',
    admittingPractitioner: 'Dr. Anne Dubois',
  ),
  _Stay(
    patientId: 'pat-006',
    wardId: 'ward-emer',
    bedId: 'bed-emer-2a',
    encounterClass: EncounterClass.emergency,
    admittedHoursAgo: 1,
    reason: 'Ankle trauma after a fall',
    admittingPractitioner: 'Dr. Jan Peeters',
  ),
  _Stay(
    patientId: 'pat-008',
    wardId: 'ward-icu',
    bedId: 'bed-icu-221a',
    encounterClass: EncounterClass.inpatient,
    admittedHoursAgo: 148,
    reason: 'Urosepsis with septic shock',
    admittingPractitioner: 'Dr. Jan Peeters',
  ),
  _Stay(
    patientId: 'pat-010',
    wardId: 'ward-ped',
    bedId: 'bed-ped-501a',
    encounterClass: EncounterClass.inpatient,
    admittedHoursAgo: 44,
    reason: 'Acute asthma exacerbation',
    admittingPractitioner: 'Dr. Anne Dubois',
  ),
  _Stay(
    patientId: 'pat-013',
    wardId: 'ward-geri',
    bedId: 'bed-geri-601a',
    encounterClass: EncounterClass.inpatient,
    admittedHoursAgo: 220,
    reason: 'Rehabilitation after hip fracture',
    admittingPractitioner: 'Dr. Anne Dubois',
  ),
  _Stay(
    patientId: 'pat-015',
    wardId: 'ward-card',
    bedId: 'bed-card-302a',
    encounterClass: EncounterClass.inpatient,
    admittedHoursAgo: 30,
    reason: 'Rapid atrial fibrillation',
    admittingPractitioner: 'Dr. Anne Dubois',
  ),
  _Stay(
    patientId: 'pat-016',
    wardId: 'ward-ped',
    bedId: 'bed-ped-502a',
    encounterClass: EncounterClass.inpatient,
    admittedHoursAgo: 13,
    reason: 'Abdominal pain, appendicitis to exclude',
    admittingPractitioner: 'Dr. Jan Peeters',
  ),
  _Stay(
    patientId: 'pat-018',
    wardId: 'ward-int',
    bedId: 'bed-int-402a',
    encounterClass: EncounterClass.inpatient,
    admittedHoursAgo: 74,
    reason: 'Decompensated type 2 diabetes',
    admittingPractitioner: 'Dr. Jan Peeters',
  ),
  _Stay(
    patientId: 'pat-020',
    wardId: 'ward-card',
    bedId: 'bed-card-303a',
    encounterClass: EncounterClass.inpatient,
    admittedHoursAgo: 120,
    reason: 'Post myocardial infarction monitoring',
    admittingPractitioner: 'Dr. Anne Dubois',
  ),

  // ---- Already discharged --------------------------------------------------
  _Stay(
    patientId: 'pat-004',
    wardId: 'ward-int',
    bedId: 'bed-int-403a',
    encounterClass: EncounterClass.inpatient,
    admittedHoursAgo: 240,
    dischargedHoursAgo: 120,
    reason: 'Pyelonephritis',
    admittingPractitioner: 'Dr. Jan Peeters',
    dischargeDisposition: 'home',
  ),
  _Stay(
    patientId: 'pat-009',
    wardId: 'ward-surg',
    bedId: 'bed-surg-202a',
    encounterClass: EncounterClass.inpatient,
    admittedHoursAgo: 384,
    dischargedHoursAgo: 288,
    reason: 'Inguinal hernia repair',
    admittingPractitioner: 'Dr. Jan Peeters',
    dischargeDisposition: 'home',
  ),
  _Stay(
    patientId: 'pat-011',
    wardId: 'ward-surg',
    bedId: 'bed-surg-203a',
    encounterClass: EncounterClass.dayCare,
    admittedHoursAgo: 488,
    dischargedHoursAgo: 480,
    reason: 'Diagnostic gastroscopy',
    admittingPractitioner: 'Dr. Anne Dubois',
    dischargeDisposition: 'home',
  ),
  _Stay(
    patientId: 'pat-014',
    wardId: 'ward-emer',
    bedId: 'bed-emer-3a',
    encounterClass: EncounterClass.emergency,
    admittedHoursAgo: 200,
    dischargedHoursAgo: 194,
    reason: 'Renal colic',
    admittingPractitioner: 'Dr. Jan Peeters',
    dischargeDisposition: 'home',
  ),
  _Stay(
    patientId: 'pat-019',
    wardId: 'ward-surg',
    bedId: 'bed-surg-204a',
    encounterClass: EncounterClass.dayCare,
    admittedHoursAgo: 728,
    dischargedHoursAgo: 722,
    reason: 'Wisdom tooth extraction under sedation',
    admittingPractitioner: 'Dr. Anne Dubois',
    dischargeDisposition: 'home',
  ),
];

/// Builds the encounters and the movement history that produced them.
///
/// Two of the stays include a transfer, so the ADT movement list is not just a
/// column of admissions: pat-008 came in through the emergency department
/// before reaching intensive care, and pat-020 stepped down from ICU to
/// cardiology.
({List<Encounter> encounters, List<Movement> movements}) buildSeedEncounters(
  DateTime now,
) {
  final encounters = <Encounter>[];
  final movements = <Movement>[];
  var visitCounter = 1;

  for (final stay in _stays) {
    final encounterId = 'enc-${stay.patientId.substring(4)}';
    final admittedAt = now.subtract(Duration(hours: stay.admittedHoursAgo));
    final dischargedAt = stay.dischargedHoursAgo == null
        ? null
        : now.subtract(Duration(hours: stay.dischargedHoursAgo!));

    encounters.add(Encounter(
      id: encounterId,
      patientId: stay.patientId,
      status: stay.isActive
          ? EncounterStatus.inProgress
          : EncounterStatus.finished,
      encounterClass: stay.encounterClass,
      admissionDate: admittedAt,
      wardId: stay.isActive ? stay.wardId : null,
      bedId: stay.isActive ? stay.bedId : null,
      dischargeDate: dischargedAt,
      admittingPractitioner: stay.admittingPractitioner,
      attendingPractitioner: stay.admittingPractitioner,
      reason: stay.reason,
      dischargeDisposition: stay.dischargeDisposition,
      visitNumber: 'V${now.year}-${visitCounter.toString().padLeft(4, '0')}',
    ));
    visitCounter++;

    // Two stays route through the emergency department first.
    final viaEmergency = stay.patientId == 'pat-008';
    final steppedDownFromIcu = stay.patientId == 'pat-020';

    if (viaEmergency) {
      movements.add(Movement(
        id: '$encounterId-mv-1',
        encounterId: encounterId,
        patientId: stay.patientId,
        type: MovementType.admission,
        occurredAt: admittedAt,
        performedBy: 'Fatima El Amrani',
        toWardId: 'ward-emer',
        toBedId: 'bed-emer-4a',
        note: 'Brought in by ambulance',
      ));
      movements.add(Movement(
        id: '$encounterId-mv-2',
        encounterId: encounterId,
        patientId: stay.patientId,
        type: MovementType.transfer,
        occurredAt: admittedAt.add(const Duration(hours: 4)),
        performedBy: 'Sofie De Clercq',
        fromWardId: 'ward-emer',
        fromBedId: 'bed-emer-4a',
        toWardId: stay.wardId,
        toBedId: stay.bedId,
        note: 'Haemodynamically unstable, escalated to intensive care',
      ));
    } else if (steppedDownFromIcu) {
      movements.add(Movement(
        id: '$encounterId-mv-1',
        encounterId: encounterId,
        patientId: stay.patientId,
        type: MovementType.admission,
        occurredAt: admittedAt,
        performedBy: 'Fatima El Amrani',
        toWardId: 'ward-icu',
        toBedId: 'bed-icu-222a',
      ));
      movements.add(Movement(
        id: '$encounterId-mv-2',
        encounterId: encounterId,
        patientId: stay.patientId,
        type: MovementType.transfer,
        occurredAt: admittedAt.add(const Duration(hours: 48)),
        performedBy: 'Marie Lambert',
        fromWardId: 'ward-icu',
        fromBedId: 'bed-icu-222a',
        toWardId: stay.wardId,
        toBedId: stay.bedId,
        note: 'Stable, stepped down to the cardiology ward',
      ));
    } else {
      movements.add(Movement(
        id: '$encounterId-mv-1',
        encounterId: encounterId,
        patientId: stay.patientId,
        type: MovementType.admission,
        occurredAt: admittedAt,
        performedBy: 'Fatima El Amrani',
        toWardId: stay.wardId,
        toBedId: stay.bedId,
      ));
    }

    if (dischargedAt != null) {
      movements.add(Movement(
        id: '$encounterId-mv-out',
        encounterId: encounterId,
        patientId: stay.patientId,
        type: MovementType.discharge,
        occurredAt: dischargedAt,
        performedBy: 'Fatima El Amrani',
        fromWardId: stay.wardId,
        fromBedId: stay.bedId,
        note: 'Discharged home',
      ));
    }
  }

  movements.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  return (encounters: encounters, movements: movements);
}

/// A prescription line, expressed against the formulary.
class _Rx {
  const _Rx(
    this.patientId,
    this.medicationCode,
    this.dose,
    this.unit,
    this.perDay,
    this.route, {
    this.prn = false,
    this.indication,
    this.status = PrescriptionStatus.active,
    this.startedHoursAgo = 24,
  });

  final String patientId;
  final String medicationCode;
  final double dose;
  final String unit;
  final int perDay;
  final MedicationRoute route;
  final bool prn;
  final String? indication;
  final PrescriptionStatus status;
  final int startedHoursAgo;
}

const List<_Rx> _prescriptions = <_Rx>[
  // pat-001 - heart failure
  _Rx('pat-001', 'MED-0107', 40, 'mg', 2, MedicationRoute.oral,
      indication: 'Fluid overload', startedHoursAgo: 94),
  _Rx('pat-001', 'MED-0106', 5, 'mg', 1, MedicationRoute.oral,
      indication: 'Heart failure', startedHoursAgo: 94),
  _Rx('pat-001', 'MED-0108', 5, 'mg', 1, MedicationRoute.oral, startedHoursAgo: 94),
  _Rx('pat-001', 'MED-0101', 1, 'tablet', 3, MedicationRoute.oral,
      prn: true, indication: 'Pain'),

  // pat-002 - pneumonia. Note: penicillin-free is not required here, but the
  // students will find that pat-001 is the one who must not get MED-0104.
  _Rx('pat-002', 'MED-0116', 2, 'g', 1, MedicationRoute.intravenous,
      indication: 'Pneumonia', startedHoursAgo: 50),
  _Rx('pat-002', 'MED-0101', 1, 'tablet', 4, MedicationRoute.oral, prn: true),
  _Rx('pat-002', 'MED-0105', 4000, 'IU', 1, MedicationRoute.subcutaneous,
      indication: 'Thrombosis prophylaxis', startedHoursAgo: 50),

  // pat-003 - post-operative
  _Rx('pat-003', 'MED-0114', 5, 'mg', 4, MedicationRoute.intravenous,
      prn: true, indication: 'Post-operative pain', startedHoursAgo: 24),
  _Rx('pat-003', 'MED-0101', 1, 'g', 4, MedicationRoute.oral, startedHoursAgo: 24),
  _Rx('pat-003', 'MED-0105', 4000, 'IU', 1, MedicationRoute.subcutaneous,
      startedHoursAgo: 24),

  // pat-008 - ICU, sepsis
  _Rx('pat-008', 'MED-0116', 2, 'g', 2, MedicationRoute.intravenous,
      indication: 'Urosepsis', startedHoursAgo: 146),
  _Rx('pat-008', 'MED-0117', 500, 'mL', 4, MedicationRoute.intravenous,
      startedHoursAgo: 146),
  _Rx('pat-008', 'MED-0115', 5, 'mg', 1, MedicationRoute.intravenous,
      prn: true, indication: 'Sedation', startedHoursAgo: 146),

  // pat-010 - paediatric asthma
  _Rx('pat-010', 'MED-0112', 2, 'dose', 4, MedicationRoute.inhalation,
      indication: 'Asthma', startedHoursAgo: 42),

  // pat-013 - geriatrics
  _Rx('pat-013', 'MED-0101', 1, 'g', 3, MedicationRoute.oral, startedHoursAgo: 218),
  _Rx('pat-013', 'MED-0120', 75, 'µg', 1, MedicationRoute.oral, startedHoursAgo: 218),
  _Rx('pat-013', 'MED-0113', 20, 'mg', 1, MedicationRoute.oral, startedHoursAgo: 218),

  // pat-015 - atrial fibrillation
  _Rx('pat-015', 'MED-0106', 5, 'mg', 2, MedicationRoute.oral,
      indication: 'Rate control', startedHoursAgo: 28),
  _Rx('pat-015', 'MED-0119', 80, 'mg', 1, MedicationRoute.oral, startedHoursAgo: 28),

  // pat-016 - paediatric observation
  _Rx('pat-016', 'MED-0101', 500, 'mg', 3, MedicationRoute.oral,
      prn: true, indication: 'Abdominal pain', startedHoursAgo: 12),

  // pat-018 - diabetes
  _Rx('pat-018', 'MED-0111', 8, 'IU', 3, MedicationRoute.subcutaneous,
      indication: 'Type 2 diabetes', startedHoursAgo: 72),
  _Rx('pat-018', 'MED-0110', 850, 'mg', 2, MedicationRoute.oral, startedHoursAgo: 72),
  _Rx('pat-018', 'MED-0109', 40, 'mg', 1, MedicationRoute.oral, startedHoursAgo: 72),

  // pat-020 - post infarction
  _Rx('pat-020', 'MED-0119', 80, 'mg', 1, MedicationRoute.oral, startedHoursAgo: 118),
  _Rx('pat-020', 'MED-0109', 40, 'mg', 1, MedicationRoute.oral, startedHoursAgo: 118),
  _Rx('pat-020', 'MED-0106', 5, 'mg', 1, MedicationRoute.oral, startedHoursAgo: 118),
  _Rx('pat-020', 'MED-0118', 5, 'mg', 1, MedicationRoute.oral,
      status: PrescriptionStatus.onHold, startedHoursAgo: 118),

  // Historic lines on discharged patients, so the record is not empty.
  _Rx('pat-004', 'MED-0103', 500, 'mg', 3, MedicationRoute.oral,
      status: PrescriptionStatus.completed, startedHoursAgo: 238),
  _Rx('pat-009', 'MED-0101', 1, 'g', 3, MedicationRoute.oral,
      status: PrescriptionStatus.completed, startedHoursAgo: 382),
];

List<Prescription> buildSeedPrescriptions(
  DateTime now,
  Map<String, String> encounterIdByPatient,
) {
  final prescriptions = <Prescription>[];
  var counter = 1;
  for (final rx in _prescriptions) {
    final medication = formularyByCode(rx.medicationCode);
    if (medication == null) continue;
    prescriptions.add(Prescription(
      id: 'rx-${counter.toString().padLeft(4, '0')}',
      patientId: rx.patientId,
      encounterId: encounterIdByPatient[rx.patientId],
      medication: medication,
      doseQuantity: rx.dose,
      doseUnit: rx.unit,
      frequencyPerDay: rx.perDay,
      route: rx.route,
      startDate: now.subtract(Duration(hours: rx.startedHoursAgo)),
      prescriber: rx.patientId.hashCode.isEven
          ? 'Dr. Anne Dubois'
          : 'Dr. Jan Peeters',
      status: rx.status,
      isPrn: rx.prn,
      indication: rx.indication,
    ));
    counter++;
  }
  return prescriptions;
}

/// Clinical notes. Written in the language the ward actually works in, which
/// is why the set is a mix of French, Dutch and English - and why the note
/// viewer labels each one with its language rather than pretending they are
/// interchangeable.
List<ClinicalNote> buildSeedNotes(
  DateTime now,
  Map<String, String> encounterIdByPatient,
) {
  ClinicalNote note({
    required String id,
    required String patientId,
    required NoteType type,
    required String title,
    required String body,
    required String authorName,
    required String authorRole,
    required int hoursAgo,
    required String language,
    bool signed = true,
  }) =>
      ClinicalNote(
        id: id,
        patientId: patientId,
        encounterId: encounterIdByPatient[patientId],
        type: type,
        title: title,
        body: body,
        authorName: authorName,
        authorRole: authorRole,
        createdAt: now.subtract(Duration(hours: hoursAgo)),
        isSigned: signed,
        language: language,
      );

  return <ClinicalNote>[
    note(
      id: 'note-0001',
      patientId: 'pat-001',
      type: NoteType.admission,
      title: "Note d'admission - décompensation cardiaque",
      body: 'Patient de 77 ans, connu pour une insuffisance cardiaque à fraction '
          "d'éjection réduite, admis pour dyspnée croissante depuis cinq jours et "
          'prise de poids de 4 kg.\n\n'
          'Examen : orthopnée, râles crépitants aux deux bases, œdèmes des membres '
          "inférieurs prenant le godet jusqu'aux genoux. TA 148/92, FC 96/min, "
          "SpO2 91 % à l'air ambiant.\n\n"
          'Plan : furosémide IV, restriction hydrique à 1,5 L/24 h, pesée '
          'quotidienne, poursuite du bisoprolol et du périndopril.\n\n'
          'ATTENTION : allergie documentée à la pénicilline (urticaire).',
      authorName: 'Dr. Anne Dubois',
      authorRole: 'Physician',
      hoursAgo: 95,
      language: 'fr',
    ),
    note(
      id: 'note-0002',
      patientId: 'pat-001',
      type: NoteType.nursing,
      title: 'Suivi infirmier - pesée du matin',
      body: 'Poids ce matin 82,4 kg, soit -1,6 kg par rapport à hier. Diurèse des '
          '24 h : 2 350 mL. Le patient se dit moins essoufflé, a pu marcher '
          "jusqu'à la salle de bain sans aide. Œdèmes en régression. "
          'SpO2 95 % à l\'air ambiant.',
      authorName: 'Marie Lambert',
      authorRole: 'Nurse',
      hoursAgo: 6,
      language: 'fr',
    ),
    note(
      id: 'note-0003',
      patientId: 'pat-002',
      type: NoteType.admission,
      title: 'Opnamenotitie - pneumonie',
      body: 'Vrouw van 70 jaar, sinds vier dagen koorts tot 39,2 °C, productieve '
          'hoest met purulent sputum en pijn rechts thoracaal bij inademing.\n\n'
          'Onderzoek: verminderd ademgeruis rechts basaal, crepitaties. '
          'Ademhalingsfrequentie 24/min, SpO2 93% bij kamerlucht. CRP 187 mg/L, '
          'leukocyten 15.400/µL. Thoraxfoto: infiltraat rechter onderkwab.\n\n'
          'Beleid: ceftriaxone 2 g IV eenmaal daags, zuurstof op geleide van '
          'saturatie, tromboseprofylaxe.\n\n'
          'LET OP: allergie voor jodiumhoudend contrastmiddel (anafylaxie) - geen '
          'CT met contrast zonder overleg.',
      authorName: 'Dr. Jan Peeters',
      authorRole: 'Physician',
      hoursAgo: 51,
      language: 'nl',
    ),
    note(
      id: 'note-0004',
      patientId: 'pat-003',
      type: NoteType.progress,
      title: 'Post-operative day 1',
      body: 'Laparoscopic cholecystectomy performed yesterday without '
          'complications. Four ports, gallbladder removed intact, no drain left '
          'in place.\n\n'
          'Today: afebrile, abdomen soft, port sites clean and dry. Bowel sounds '
          'present, first flatus passed overnight. Pain controlled on paracetamol '
          'with morphine used twice during the night.\n\n'
          'Plan: start light diet, mobilise, aim for discharge tomorrow if the '
          'patient tolerates food.',
      authorName: 'Dr. Jan Peeters',
      authorRole: 'Physician',
      hoursAgo: 4,
      language: 'en',
    ),
    note(
      id: 'note-0005',
      patientId: 'pat-008',
      type: NoteType.progress,
      title: 'Intensieve zorgen - dag 6',
      body: 'Urosepsis met septische shock bij opname. Noradrenaline sinds '
          'gisterochtend afgebouwd en nu gestopt. Hemodynamisch stabiel zonder '
          'vasopressoren.\n\n'
          'Nierfunctie herstelt: creatinine van 3,1 naar 1,7 mg/dL. Diurese '
          'spontaan 1.900 mL/24 u. Bloedkweken: E. coli, gevoelig voor '
          'ceftriaxone.\n\n'
          'Beleid: antibiotica voortzetten tot dag 10, morgen mogelijk '
          'overplaatsing naar interne geneeskunde.\n\n'
          'LET OP: allergie voor acetylsalicylzuur (bronchospasme).',
      authorName: 'Dr. Jan Peeters',
      authorRole: 'Physician',
      hoursAgo: 8,
      language: 'nl',
    ),
    note(
      id: 'note-0006',
      patientId: 'pat-010',
      type: NoteType.nursing,
      title: 'Verpleegkundige observatie - nachtdienst',
      body: 'Noah heeft rustig geslapen, geen nachtelijke hoestbuien. '
          'Piekstroom bij het ontwaken 78% van de voorspelde waarde, tegenover '
          '61% bij opname. Salbutamol viermaal gegeven volgens schema, geen '
          'extra doses nodig geweest.\n\n'
          'Moeder blijft vannacht bij het kind. Uitleg gegeven over het correcte '
          'gebruik van de voorzetkamer.',
      authorName: 'Sofie De Clercq',
      authorRole: 'Nurse',
      hoursAgo: 9,
      language: 'nl',
    ),
    note(
      id: 'note-0007',
      patientId: 'pat-013',
      type: NoteType.progress,
      title: 'Revalidation - bilan hebdomadaire',
      body: 'Patiente de 89 ans en revalidation après fracture du col du fémur '
          'opérée il y a neuf jours.\n\n'
          'Progrès : transfert lit-fauteuil possible avec une aide, marche de '
          '15 mètres avec cadre de marche contre 5 mètres la semaine dernière. '
          "Douleur cotée 3/10 au repos, 5/10 à l'effort.\n\n"
          "Points d'attention : appétit diminué, perte de 1,2 kg cette semaine. "
          'Avis diététique demandé. Risque de chute élevé, maintien des barrières.\n\n'
          'ATTENTION : allergie aux sulfamides (syndrome de Stevens-Johnson).',
      authorName: 'Dr. Anne Dubois',
      authorRole: 'Physician',
      hoursAgo: 20,
      language: 'fr',
    ),
    note(
      id: 'note-0008',
      patientId: 'pat-018',
      type: NoteType.progress,
      title: 'Équilibration du diabète - jour 3',
      body: 'Glycémies des dernières 24 h : 212, 178, 156, 143 mg/dL. Nette '
          "amélioration depuis l'introduction de l'insuline asparte avant les "
          'repas.\n\n'
          "HbA1c à l'admission : 10,4 %. Le patient reconnaît avoir interrompu la "
          'metformine depuis plusieurs mois.\n\n'
          "Plan : éducation thérapeutique avec l'infirmière de diabétologie, "
          "reprise de la metformine, poursuite de l'insuline avec adaptation "
          "selon les glycémies. Fond d'œil et bilan podologique à programmer.",
      authorName: 'Dr. Jan Peeters',
      authorRole: 'Physician',
      hoursAgo: 11,
      language: 'fr',
    ),
    note(
      id: 'note-0009',
      patientId: 'pat-005',
      type: NoteType.observation,
      title: 'Emergency triage note',
      body: 'Thirty-five year old woman presenting with central chest tightness '
          'that started two hours ago at rest, lasting about twenty minutes, now '
          'resolved. No radiation, no dyspnoea, no sweating.\n\n'
          'ECG: sinus rhythm, no ST changes. First troponin negative. '
          'Vital signs stable.\n\n'
          'Plan: repeat troponin at three hours, cardiology review if positive. '
          'Low HEART score so far.\n\n'
          'NOTE: high-risk peanut allergy (angioedema) - check every product '
          'given.',
      authorName: 'Dr. Anne Dubois',
      authorRole: 'Physician',
      hoursAgo: 2,
      language: 'en',
      signed: false,
    ),
    note(
      id: 'note-0010',
      patientId: 'pat-020',
      type: NoteType.progress,
      title: 'Suivi post-infarctus - jour 5',
      body: 'Patient de 75 ans, infarctus inférieur traité par angioplastie '
          "primaire avec pose d'un stent actif sur la coronaire droite.\n\n"
          'Évolution favorable : pas de récidive douloureuse, pas de trouble du '
          "rythme au monitoring. Fraction d'éjection à 48 % à l'échographie de "
          'contrôle.\n\n'
          "L'amlodipine est suspendue en raison d'une tendance hypotensive "
          '(TA 102/58 ce matin). Réévaluation dans 48 h.\n\n'
          'Plan : réadaptation cardiaque à organiser, sortie envisagée dans '
          'deux jours.',
      authorName: 'Dr. Anne Dubois',
      authorRole: 'Physician',
      hoursAgo: 7,
      language: 'fr',
    ),
    note(
      id: 'note-0011',
      patientId: 'pat-004',
      type: NoteType.discharge,
      title: 'Ontslagbrief - pyelonefritis',
      body: 'Patiënte werd opgenomen met rechtszijdige flankpijn, koorts en '
          'dysurie. Diagnose: acute pyelonefritis rechts.\n\n'
          'Behandeling: amoxicilline oraal gedurende zeven dagen na initiële '
          'intraveneuze therapie. Klinisch en biochemisch volledig hersteld bij '
          'ontslag: afebriel sinds 48 uur, CRP gedaald van 210 naar 22 mg/L.\n\n'
          'Advies: kuur afmaken, ruim drinken, controle bij de huisarts over een '
          'week. Bij hernieuwde koorts of pijn onmiddellijk contact opnemen.',
      authorName: 'Dr. Jan Peeters',
      authorRole: 'Physician',
      hoursAgo: 120,
      language: 'nl',
    ),
    note(
      id: 'note-0012',
      patientId: 'pat-016',
      type: NoteType.observation,
      title: 'Observation - douleur abdominale',
      body: 'Garçon de 15 ans, douleur abdominale péri-ombilicale depuis hier '
          'soir, migrant vers la fosse iliaque droite ce matin. Une vomissement, '
          'pas de diarrhée.\n\n'
          'Examen : défense en fosse iliaque droite, signe de McBurney positif. '
          'Température 37,9 °C. Leucocytes 13.200/µL, CRP 42 mg/L.\n\n'
          'Échographie abdominale demandée. À jeun strict. Réévaluation '
          'chirurgicale dans quatre heures.',
      authorName: 'Dr. Jan Peeters',
      authorRole: 'Physician',
      hoursAgo: 10,
      language: 'fr',
      signed: false,
    ),
  ];
}
