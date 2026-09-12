import '../util/localized_text.dart';

/// Terminology system URIs used across the mini-hospital.
class CodeSystems {
  const CodeSystems._();

  static const String loinc = 'http://loinc.org';
  static const String snomed = 'http://snomed.info/sct';
  static const String atc = 'http://www.whocc.no/atc';
  static const String ucum = 'http://unitsofmeasure.org';
  static const String observationCategory =
      'http://terminology.hl7.org/CodeSystem/observation-category';
  static const String encounterClass =
      'http://terminology.hl7.org/CodeSystem/v3-ActCode';
  static const String identifierType =
      'http://terminology.hl7.org/CodeSystem/v2-0203';
  static const String dischargeDisposition =
      'http://terminology.hl7.org/CodeSystem/discharge-disposition';

  /// Local code systems, namespaced under the teaching hospital.
  static const String localBase =
      'http://mini-hospital.example.org/fhir/CodeSystem';
  static const String localWard = '$localBase/ward';
  static const String localNoteType = '$localBase/note-type';
  static const String localDevice = '$localBase/device-type';
}

/// The vital signs and body measurements the connected devices produce.
///
/// Each entry carries its LOINC code and UCUM unit, so an [Observation] can be
/// rendered as a spec-valid FHIR resource without a lookup table elsewhere.
enum VitalSignType {
  bodyWeight(
    loincCode: '29463-7',
    unit: 'kg',
    ucum: 'kg',
    display: LocalizedText(
      en: 'Body weight',
      fr: 'Poids corporel',
      nl: 'Lichaamsgewicht',
    ),
    normalLow: 2,
    normalHigh: 250,
    decimals: 1,
  ),
  bodyTemperature(
    loincCode: '8310-5',
    unit: '°C',
    ucum: 'Cel',
    display: LocalizedText(
      en: 'Body temperature',
      fr: 'Température corporelle',
      nl: 'Lichaamstemperatuur',
    ),
    normalLow: 36.1,
    normalHigh: 37.8,
    decimals: 1,
  ),
  heartRate(
    loincCode: '8867-4',
    unit: 'bpm',
    ucum: '/min',
    display: LocalizedText(
      en: 'Heart rate',
      fr: 'Fréquence cardiaque',
      nl: 'Hartfrequentie',
    ),
    normalLow: 60,
    normalHigh: 100,
    decimals: 0,
  ),
  oxygenSaturation(
    loincCode: '2708-6',
    unit: '%',
    ucum: '%',
    display: LocalizedText(
      en: 'Oxygen saturation (SpO2)',
      fr: 'Saturation en oxygène (SpO2)',
      nl: 'Zuurstofsaturatie (SpO2)',
    ),
    normalLow: 94,
    normalHigh: 100,
    decimals: 0,
  ),
  activitySteps(
    loincCode: '41950-7',
    unit: 'steps',
    ucum: '{steps}',
    display: LocalizedText(
      en: 'Activity (steps per 24h)',
      fr: 'Activité (pas par 24 h)',
      nl: 'Activiteit (stappen per 24 u)',
    ),
    normalLow: 1000,
    normalHigh: 20000,
    decimals: 0,
  ),
  respiratoryRate(
    loincCode: '9279-1',
    unit: '/min',
    ucum: '/min',
    display: LocalizedText(
      en: 'Respiratory rate',
      fr: 'Fréquence respiratoire',
      nl: 'Ademhalingsfrequentie',
    ),
    normalLow: 12,
    normalHigh: 20,
    decimals: 0,
  ),
  systolicBloodPressure(
    loincCode: '8480-6',
    unit: 'mmHg',
    ucum: 'mm[Hg]',
    display: LocalizedText(
      en: 'Systolic blood pressure',
      fr: 'Pression artérielle systolique',
      nl: 'Systolische bloeddruk',
    ),
    normalLow: 90,
    normalHigh: 140,
    decimals: 0,
  ),
  diastolicBloodPressure(
    loincCode: '8462-4',
    unit: 'mmHg',
    ucum: 'mm[Hg]',
    display: LocalizedText(
      en: 'Diastolic blood pressure',
      fr: 'Pression artérielle diastolique',
      nl: 'Diastolische bloeddruk',
    ),
    normalLow: 60,
    normalHigh: 90,
    decimals: 0,
  );

  const VitalSignType({
    required this.loincCode,
    required this.unit,
    required this.ucum,
    required this.display,
    required this.normalLow,
    required this.normalHigh,
    required this.decimals,
  });

  /// LOINC code, the identifier a real hospital system would exchange.
  final String loincCode;

  /// Unit as shown to a human.
  final String unit;

  /// Unit as UCUM, which is what FHIR `Quantity.code` requires.
  final String ucum;

  final LocalizedText display;

  /// Lower bound of the physiologically normal range, used to flag values.
  final double normalLow;

  /// Upper bound of the physiologically normal range.
  final double normalHigh;

  /// How many decimals to show; a heart rate of `72.0` reads wrong.
  final int decimals;

  static VitalSignType? fromLoinc(String code) {
    for (final type in values) {
      if (type.loincCode == code) return type;
    }
    return null;
  }

  static VitalSignType fromName(String name, {VitalSignType? fallback}) {
    for (final type in values) {
      if (type.name == name) return type;
    }
    return fallback ?? VitalSignType.heartRate;
  }

  /// True when [value] falls outside the normal range and should be flagged.
  bool isAbnormal(double value) => value < normalLow || value > normalHigh;

  String format(double value) => '${value.toStringAsFixed(decimals)} $unit';
}

/// FHIR `Observation.status`.
enum ObservationStatus {
  registered,
  preliminary,
  finalised,
  amended,
  cancelled;

  /// FHIR uses the American spelling `final`, which is a Dart keyword, so the
  /// enum constant is [finalised] and the wire value is mapped here.
  String get fhirCode => this == ObservationStatus.finalised ? 'final' : name;

  static ObservationStatus fromFhir(String? code) => switch (code) {
    'registered' => ObservationStatus.registered,
    'preliminary' => ObservationStatus.preliminary,
    'final' => ObservationStatus.finalised,
    'amended' => ObservationStatus.amended,
    'cancelled' || 'entered-in-error' => ObservationStatus.cancelled,
    _ => ObservationStatus.finalised,
  };
}

/// Administrative gender, as FHIR defines it.
enum AdministrativeGender {
  male(LocalizedText(en: 'Male', fr: 'Masculin', nl: 'Man')),
  female(LocalizedText(en: 'Female', fr: 'Féminin', nl: 'Vrouw')),
  other(LocalizedText(en: 'Other', fr: 'Autre', nl: 'Anders')),
  unknown(LocalizedText(en: 'Unknown', fr: 'Inconnu', nl: 'Onbekend'));

  const AdministrativeGender(this.display);
  final LocalizedText display;

  static AdministrativeGender fromFhir(String? code) => switch (code) {
    'male' => AdministrativeGender.male,
    'female' => AdministrativeGender.female,
    'other' => AdministrativeGender.other,
    _ => AdministrativeGender.unknown,
  };
}

/// FHIR `Encounter.class` restricted to what this teaching hospital models.
enum EncounterClass {
  inpatient(
    'IMP',
    LocalizedText(en: 'Inpatient', fr: 'Hospitalisation', nl: 'Opname'),
  ),
  outpatient(
    'AMB',
    LocalizedText(en: 'Outpatient', fr: 'Ambulatoire', nl: 'Ambulant'),
  ),
  emergency(
    'EMER',
    LocalizedText(en: 'Emergency', fr: 'Urgences', nl: 'Spoed'),
  ),
  dayCare(
    'SS',
    LocalizedText(en: 'Day care', fr: 'Hôpital de jour', nl: 'Dagziekenhuis'),
  ),
  homeCare(
    'HH',
    LocalizedText(en: 'Home care', fr: 'Soins à domicile', nl: 'Thuiszorg'),
  );

  const EncounterClass(this.code, this.display);
  final String code;
  final LocalizedText display;

  static EncounterClass fromCode(String? code) => switch (code) {
    'IMP' => EncounterClass.inpatient,
    'AMB' => EncounterClass.outpatient,
    'EMER' => EncounterClass.emergency,
    'SS' => EncounterClass.dayCare,
    'HH' => EncounterClass.homeCare,
    _ => EncounterClass.inpatient,
  };
}

/// FHIR `Encounter.status`, narrowed to the ADT lifecycle we simulate.
enum EncounterStatus {
  planned(LocalizedText(en: 'Planned', fr: 'Planifié', nl: 'Gepland')),
  inProgress(LocalizedText(en: 'In progress', fr: 'En cours', nl: 'Lopend')),
  onLeave(LocalizedText(en: 'On leave', fr: 'En permission', nl: 'Met verlof')),
  finished(LocalizedText(en: 'Discharged', fr: 'Sorti', nl: 'Ontslagen')),
  cancelled(LocalizedText(en: 'Cancelled', fr: 'Annulé', nl: 'Geannuleerd'));

  const EncounterStatus(this.display);
  final LocalizedText display;

  /// FHIR spells these in kebab-case.
  String get fhirCode => switch (this) {
    EncounterStatus.inProgress => 'in-progress',
    EncounterStatus.onLeave => 'onleave',
    _ => name,
  };

  static EncounterStatus fromFhir(String? code) => switch (code) {
    'planned' => EncounterStatus.planned,
    'in-progress' || 'arrived' || 'triaged' => EncounterStatus.inProgress,
    'onleave' => EncounterStatus.onLeave,
    'finished' => EncounterStatus.finished,
    'cancelled' || 'entered-in-error' => EncounterStatus.cancelled,
    _ => EncounterStatus.planned,
  };

  bool get isActive =>
      this == EncounterStatus.inProgress || this == EncounterStatus.onLeave;
}

/// The three ADT movements the students must implement and observe.
enum MovementType {
  admission(
    'A01',
    LocalizedText(en: 'Admission', fr: 'Admission', nl: 'Opname'),
  ),
  transfer(
    'A02',
    LocalizedText(en: 'Transfer', fr: 'Transfert', nl: 'Overplaatsing'),
  ),
  discharge('A03', LocalizedText(en: 'Discharge', fr: 'Sortie', nl: 'Ontslag')),
  cancelAdmission(
    'A11',
    LocalizedText(
      en: 'Cancel admission',
      fr: "Annulation d'admission",
      nl: 'Annulering opname',
    ),
  ),
  preAdmission(
    'A05',
    LocalizedText(en: 'Pre-admission', fr: 'Pré-admission', nl: 'Pre-opname'),
  );

  const MovementType(this.hl7EventCode, this.display);

  /// The HL7 v2 ADT trigger event this movement corresponds to. Students see
  /// the same codes in the EAI message log, which is the point.
  final String hl7EventCode;
  final LocalizedText display;

  static MovementType fromName(String value) => values.firstWhere(
    (m) => m.name == value,
    orElse: () => MovementType.admission,
  );
}

/// Status of a physical bed in a ward.
enum BedStatus {
  free(LocalizedText(en: 'Free', fr: 'Libre', nl: 'Vrij')),
  occupied(LocalizedText(en: 'Occupied', fr: 'Occupé', nl: 'Bezet')),
  cleaning(LocalizedText(en: 'Cleaning', fr: 'Nettoyage', nl: 'Schoonmaak')),
  blocked(LocalizedText(en: 'Blocked', fr: 'Bloqué', nl: 'Geblokkeerd'));

  const BedStatus(this.display);
  final LocalizedText display;

  static BedStatus fromName(String value) =>
      values.firstWhere((s) => s.name == value, orElse: () => BedStatus.free);
}

/// FHIR `MedicationRequest.status`.
enum PrescriptionStatus {
  draft(LocalizedText(en: 'Draft', fr: 'Brouillon', nl: 'Concept')),
  active(LocalizedText(en: 'Active', fr: 'Active', nl: 'Actief')),
  onHold(LocalizedText(en: 'On hold', fr: 'Suspendue', nl: 'Onderbroken')),
  completed(LocalizedText(en: 'Completed', fr: 'Terminée', nl: 'Voltooid')),
  cancelled(LocalizedText(en: 'Cancelled', fr: 'Annulée', nl: 'Geannuleerd'));

  const PrescriptionStatus(this.display);
  final LocalizedText display;

  String get fhirCode => this == PrescriptionStatus.onHold ? 'on-hold' : name;

  static PrescriptionStatus fromFhir(String? code) => switch (code) {
    'draft' => PrescriptionStatus.draft,
    'active' => PrescriptionStatus.active,
    'on-hold' => PrescriptionStatus.onHold,
    'completed' => PrescriptionStatus.completed,
    'cancelled' || 'stopped' => PrescriptionStatus.cancelled,
    _ => PrescriptionStatus.draft,
  };
}

/// Route of administration (SNOMED CT).
enum MedicationRoute {
  oral('26643006', LocalizedText(en: 'Oral', fr: 'Orale', nl: 'Oraal')),
  intravenous(
    '47625008',
    LocalizedText(en: 'Intravenous', fr: 'Intraveineuse', nl: 'Intraveneus'),
  ),
  subcutaneous(
    '34206005',
    LocalizedText(en: 'Subcutaneous', fr: 'Sous-cutanée', nl: 'Subcutaan'),
  ),
  intramuscular(
    '78421000',
    LocalizedText(
      en: 'Intramuscular',
      fr: 'Intramusculaire',
      nl: 'Intramusculair',
    ),
  ),
  topical('6064005', LocalizedText(en: 'Topical', fr: 'Topique', nl: 'Lokaal')),
  inhalation(
    '447694001',
    LocalizedText(en: 'Inhalation', fr: 'Inhalation', nl: 'Inhalatie'),
  ),
  rectal('12130007', LocalizedText(en: 'Rectal', fr: 'Rectale', nl: 'Rectaal'));

  const MedicationRoute(this.snomedCode, this.display);
  final String snomedCode;
  final LocalizedText display;

  static MedicationRoute fromName(String value) => values.firstWhere(
    (r) => r.name == value,
    orElse: () => MedicationRoute.oral,
  );
}

/// Status of a dispensing event in the pharmacy cabinet.
enum DispenseStatus {
  requested(LocalizedText(en: 'Requested', fr: 'Demandée', nl: 'Aangevraagd')),
  preparation(
    LocalizedText(
      en: 'In preparation',
      fr: 'En préparation',
      nl: 'In bereiding',
    ),
  ),
  dispensed(LocalizedText(en: 'Dispensed', fr: 'Délivrée', nl: 'Afgeleverd')),
  refused(LocalizedText(en: 'Refused', fr: 'Refusée', nl: 'Geweigerd')),
  returned(LocalizedText(en: 'Returned', fr: 'Retournée', nl: 'Geretourneerd'));

  const DispenseStatus(this.display);
  final LocalizedText display;

  String get fhirCode => switch (this) {
    DispenseStatus.requested => 'preparation',
    DispenseStatus.preparation => 'in-progress',
    DispenseStatus.dispensed => 'completed',
    DispenseStatus.refused => 'cancelled',
    DispenseStatus.returned => 'stopped',
  };

  static DispenseStatus fromName(String value) => values.firstWhere(
    (s) => s.name == value,
    orElse: () => DispenseStatus.requested,
  );
}

/// Kind of clinical note. Drives the icon and the default template.
enum NoteType {
  admission(
    LocalizedText(
      en: 'Admission note',
      fr: "Note d'admission",
      nl: 'Opnamenotitie',
    ),
  ),
  progress(
    LocalizedText(
      en: 'Progress note',
      fr: 'Note de suivi',
      nl: 'Voortgangsnotitie',
    ),
  ),
  nursing(
    LocalizedText(
      en: 'Nursing note',
      fr: 'Note infirmière',
      nl: 'Verpleegkundige notitie',
    ),
  ),
  consultation(
    LocalizedText(en: 'Consultation', fr: 'Consultation', nl: 'Consult'),
  ),
  observation(
    LocalizedText(en: 'Observation', fr: 'Observation', nl: 'Observatie'),
  ),
  discharge(
    LocalizedText(
      en: 'Discharge summary',
      fr: 'Rapport de sortie',
      nl: 'Ontslagbrief',
    ),
  );

  const NoteType(this.display);
  final LocalizedText display;

  static NoteType fromName(String value) => values.firstWhere(
    (t) => t.name == value,
    orElse: () => NoteType.progress,
  );
}

/// How severe an allergy reaction is expected to be (FHIR `criticality`).
enum AllergyCriticality {
  low(LocalizedText(en: 'Low risk', fr: 'Risque faible', nl: 'Laag risico')),
  high(LocalizedText(en: 'High risk', fr: 'Risque élevé', nl: 'Hoog risico')),
  unableToAssess(
    LocalizedText(
      en: 'Unable to assess',
      fr: 'Non évaluable',
      nl: 'Niet te beoordelen',
    ),
  );

  const AllergyCriticality(this.display);
  final LocalizedText display;

  String get fhirCode =>
      this == AllergyCriticality.unableToAssess ? 'unable-to-assess' : name;

  static AllergyCriticality fromFhir(String? code) => switch (code) {
    'low' => AllergyCriticality.low,
    'high' => AllergyCriticality.high,
    _ => AllergyCriticality.unableToAssess,
  };
}
