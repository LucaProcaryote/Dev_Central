/// Builds HL7 v2 messages from the hospital's own domain model.
///
/// Two message types, chosen because they are the two the students already
/// produce without knowing it: an ADT movement is an `ADT^A0x`, and a device
/// reading is an `ORU^R01`. Everything the platform does in FHIR, it can now
/// also do in v2, which is the comparison the course is for.
///
/// The generated messages are deliberately minimal but well-formed: the
/// segments a receiving system actually reads, in the right order, with the
/// right delimiters and escaping. They are not conformance-complete, and a
/// real hospital would add a dozen Z-segments of its own - which is itself
/// worth a slide.
library;

import '../models/codes.dart';
import '../models/encounter.dart';
import '../models/observation.dart';
import '../models/patient.dart';
import 'hl7_message.dart';

/// Turns domain objects into HL7 v2 messages.
///
/// The sending and receiving identifiers go in MSH-3 to MSH-6 and are how a
/// receiving interface engine decides what to do with a message, so they are
/// configuration rather than constants.
class Hl7Builder {
  const Hl7Builder({
    this.sendingApplication = 'MINI-ADT',
    this.sendingFacility = 'MINI-HOSPITAL',
    this.receivingApplication = 'MINI-EAI',
    this.receivingFacility = 'MINI-HOSPITAL',
    this.processingId = 'T',
  });

  final String sendingApplication;
  final String sendingFacility;
  final String receivingApplication;
  final String receivingFacility;

  /// MSH-11. `T` for training, `P` for production. A receiving system is
  /// entitled to refuse a `P` message it was not expecting, and the fact that
  /// everything here is `T` is the honest answer.
  final String processingId;

  static const Hl7Encoding _encoding = Hl7Encoding.standard;

  /// `yyyyMMddHHmmss`, the only timestamp format v2 uses.
  static String timestamp(DateTime value) {
    final local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}${two(local.month)}${two(local.day)}'
        '${two(local.hour)}${two(local.minute)}${two(local.second)}';
  }

  /// `yyyyMMdd`, for dates of birth.
  static String date(DateTime value) {
    final local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}${two(local.month)}${two(local.day)}';
  }

  /// PID-8. v2 predates the FHIR value set and has its own one-letter codes.
  static String sexCode(AdministrativeGender gender) => switch (gender) {
    AdministrativeGender.male => 'M',
    AdministrativeGender.female => 'F',
    AdministrativeGender.other => 'O',
    AdministrativeGender.unknown => 'U',
  };

  Hl7Segment _msh({
    required String messageType,
    required String controlId,
    required DateTime now,
  }) => Hl7Segment('MSH', <String>[
    _encoding.encodingCharacters,
    _encoding.encode(sendingApplication),
    _encoding.encode(sendingFacility),
    _encoding.encode(receivingApplication),
    _encoding.encode(receivingFacility),
    timestamp(now),
    '', // MSH-8 security, never used
    messageType,
    controlId,
    processingId,
    '2.5', // MSH-12: the version everyone in Belgium is actually running
  ]);

  /// PID, the patient identification segment.
  ///
  /// PID-5 is the component that catches everyone out: family name, given
  /// name, middle, suffix, prefix - five components where FHIR has a list of
  /// strings and a use code.
  Hl7Segment _pid(Patient patient) => Hl7Segment('PID', <String>[
    '1', // PID-1 set id
    '', // PID-2 external id, deprecated
    // PID-3 is the identifier list: value ^^^ assigning authority ^ type.
    '${_encoding.encode(patient.mrn)}^^^$sendingFacility^MR'
        '${patient.nationalNumber != null ? '~${_encoding.encode(patient.nationalNumber!)}^^^BELGIUM^NN' : ''}',
    '',
    '${_encoding.encode(patient.familyName)}^${_encoding.encode(patient.givenName)}',
    '', // PID-6 mother's maiden name
    date(patient.birthDate),
    sexCode(patient.gender),
    '', // PID-9 alias
    '', // PID-10 race
    '${_encoding.encode(patient.address.line)}^^'
        '${_encoding.encode(patient.address.city)}^^'
        '${_encoding.encode(patient.address.postalCode)}^'
        '${_encoding.encode(patient.address.country)}',
    '', // PID-12 county
    _encoding.encode(patient.phone ?? ''),
    '', // PID-14 business phone
    _encoding.encode(patient.preferredLanguage),
  ]);

  /// PV1, the visit segment: where the patient is and under whose care.
  Hl7Segment _pv1(Encounter encounter, {String? wardName, String? bedName}) {
    // PV1-3 is the assigned patient location: point of care ^ room ^ bed ^
    // facility. Sending ids rather than names would be defensible; sending
    // names is what the ward clerk reading the downstream system expects.
    final location = <String>[
      _encoding.encode(wardName ?? encounter.wardId ?? ''),
      _encoding.encode(encounter.roomId ?? ''),
      _encoding.encode(bedName ?? encounter.bedId ?? ''),
      _encoding.encode(sendingFacility),
    ].join('^');

    return Hl7Segment('PV1', <String>[
      '1',
      _patientClass(encounter.encounterClass),
      location,
      '', // PV1-4 admission type
      '', // PV1-5 pre-admit number
      '', // PV1-6 prior location
      _encoding.encode(encounter.attendingPractitioner ?? ''),
      '', // PV1-8 referring doctor
      '', // PV1-9 consulting doctor
      '', // PV1-10 hospital service
      '', // PV1-11 temporary location
      '', // PV1-12 pre-admit test indicator
      '', // PV1-13 re-admission indicator
      '', // PV1-14 admit source
      '', // PV1-15 ambulatory status
      '', // PV1-16 VIP indicator
      _encoding.encode(encounter.admittingPractitioner ?? ''),
      '', // PV1-18 patient type
      _encoding.encode(encounter.visitNumber ?? encounter.id),
      for (var i = 20; i < 36; i++) '',
      // PV1-36 discharge disposition, PV1-44 admit date, PV1-45 discharge date
      _encoding.encode(encounter.dischargeDisposition ?? ''),
      for (var i = 37; i < 44; i++) '',
      timestamp(encounter.admissionDate),
      if (encounter.dischargeDate != null) timestamp(encounter.dischargeDate!),
    ]);
  }

  static String _patientClass(EncounterClass value) => switch (value) {
    EncounterClass.inpatient => 'I',
    EncounterClass.outpatient => 'O',
    EncounterClass.emergency => 'E',
    EncounterClass.dayCare => 'O',
    EncounterClass.homeCare => 'O',
  };

  /// An `ADT^A01`, `A02` or `A03` for a patient movement.
  ///
  /// The trigger event comes from [MovementType.hl7EventCode], which the ADT
  /// application already used to label its JSON events - so the same movement
  /// now produces the same event code in both representations.
  Hl7Message adt({
    required Patient patient,
    required Encounter encounter,
    required Movement movement,
    String? wardName,
    String? bedName,
    String? controlId,
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    final event = movement.type.hl7EventCode;
    return Hl7Message(<Hl7Segment>[
      _msh(
        messageType: 'ADT^$event^ADT_A01',
        controlId: controlId ?? _controlId(movement.id),
        now: at,
      ),
      // EVN carries the event itself: what happened and when, as distinct
      // from when the message was built. A message replayed an hour later
      // still describes the same admission.
      Hl7Segment('EVN', <String>[
        event,
        timestamp(at),
        '', // EVN-3 planned event date
        '', // EVN-4 event reason code
        _encoding.encode(movement.performedBy),
        timestamp(movement.occurredAt),
      ]),
      _pid(patient),
      _pv1(encounter, wardName: wardName, bedName: bedName),
    ]);
  }

  /// An `ORU^R01` carrying one or more observations for a patient.
  ///
  /// This is the message a bedside monitor sends. One OBR groups the readings
  /// that were taken together; each OBX is a single measured value, with its
  /// LOINC code, its UCUM unit, its reference range and an interpretation
  /// flag - all information the platform already holds on [VitalSignType].
  Hl7Message oru({
    required Patient patient,
    required List<Observation> observations,
    Encounter? encounter,
    String? wardName,
    String? bedName,
    String? controlId,
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    final first = observations.isEmpty ? null : observations.first;
    final segments = <Hl7Segment>[
      _msh(
        messageType: 'ORU^R01^ORU_R01',
        controlId: controlId ?? _controlId(first?.id ?? 'oru'),
        now: at,
      ),
      _pid(patient),
      if (encounter != null)
        _pv1(encounter, wardName: wardName, bedName: bedName),
      Hl7Segment('OBR', <String>[
        '1',
        '', // OBR-2 placer order number: there is no order, these are vitals
        _encoding.encode(first?.id ?? ''),
        // OBR-4 universal service identifier. 74728-7 is the LOINC panel for
        // vital signs, which is what a monitor sends rather than an order.
        '74728-7^Vital signs^LN',
        '', // OBR-5 priority
        '', // OBR-6 requested date
        if (first != null) timestamp(first.effectiveDateTime) else '',
      ]),
    ];

    for (var i = 0; i < observations.length; i++) {
      segments.add(_obx(observations[i], setId: i + 1));
    }
    return Hl7Message(segments);
  }

  Hl7Segment _obx(Observation observation, {required int setId}) {
    final type = observation.type;
    return Hl7Segment('OBX', <String>[
      '$setId',
      'NM', // OBX-2 value type: numeric
      '${type.loincCode}^${_encoding.encode(type.display.en)}^LN',
      '', // OBX-4 sub-id, used when the same code repeats in one message
      // OBX-5 is the value alone. [VitalSignType.format] appends the unit for
      // display, which would be wrong here: the unit belongs in OBX-6, and a
      // receiving system parsing "37.2 °C" as a number gets nothing.
      observation.value.toStringAsFixed(type.decimals),
      _encoding.encode(type.ucum),
      // OBX-7 reference range, written the way a lab report prints it.
      '${_trim(type.normalLow)}-${_trim(type.normalHigh)}',
      // OBX-8 abnormal flags: the same H/L/N the EHR already computes.
      observation.interpretationCode,
      '', // OBX-9 probability
      '', // OBX-10 nature of abnormal test
      _obxStatus(observation.status),
      '', // OBX-12 effective date of reference range
      '', // OBX-13 user defined access checks
      timestamp(observation.effectiveDateTime),
      '', // OBX-15 producer id
      _encoding.encode(observation.performer ?? ''), // OBX-16
      '', // OBX-17 observation method
      // OBX-18, the equipment instance identifier: which device produced the
      // reading. This is the field that makes a connected device traceable,
      // and the reason a hospital can recall one monitor's readings.
      _encoding.encode(observation.deviceId ?? ''),
    ]);
  }

  /// OBX-11 observation result status. v2 uses single letters where FHIR
  /// spells the word out.
  static String _obxStatus(ObservationStatus status) => switch (status) {
    ObservationStatus.registered => 'I', // specimen in lab, no result yet
    ObservationStatus.preliminary => 'P',
    ObservationStatus.finalised => 'F',
    ObservationStatus.amended => 'C', // corrected
    ObservationStatus.cancelled => 'X',
  };

  static String _trim(double value) {
    final asInt = value.truncate();
    return value == asInt ? '$asInt' : '$value';
  }

  /// MSH-10 has to be unique per sending application. Deriving it from the
  /// record's own id keeps a rebuilt message identical, which is what makes
  /// the golden tests in `hl7_test.dart` possible.
  static String _controlId(String seed) =>
      seed.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
}
