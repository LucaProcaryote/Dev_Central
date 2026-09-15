/// Translates HL7 v2 messages into FHIR R4 resources.
///
/// This is the single most common job an interface engine does in a European
/// hospital today: the estate speaks v2, the new systems want FHIR, and
/// something in the middle has to reconcile the two. Having it as an explicit
/// node on the canvas - rather than hidden in an adapter - is the point of
/// putting it here.
///
/// The translation is lossy in both directions and that is not a defect of
/// this code. `PID-5` has five components where FHIR `HumanName` has a list
/// and a use code; `PV1-2` has one letter where FHIR `Encounter.class` has a
/// coded system. Every mapping below makes a choice, and the choices are
/// commented where they are not obvious.
library;

import '../models/codes.dart';
import '../util/json.dart';
import 'hl7_message.dart';

/// Where the v2 trigger event is carried on a translated `Encounter`.
///
/// FHIR has no element for it, and dropping it would leave a receiving system
/// unable to tell an admission from a correction to one.
const String triggerEventExtensionUrl =
    'http://mini-hospital.example.org/fhir/StructureDefinition/'
    'hl7v2-trigger-event';

/// Which FHIR resource a translation should produce.
enum Hl7FhirTarget {
  /// Pick from the message type: ADT gives an Encounter, ORU an Observation.
  auto,
  patient,
  encounter,
  observation,

  /// Everything the message contains, as a `collection` Bundle. Useful for
  /// inspecting a translation; not something a FHIR server will store as is.
  bundle;

  static Hl7FhirTarget fromName(String value) => values.firstWhere(
    (t) => t.name == value,
    orElse: () => Hl7FhirTarget.auto,
  );
}

/// Raised when a message cannot be translated, with a reason worth reading.
class Hl7TranslationException implements Exception {
  const Hl7TranslationException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Converts [message] into a FHIR resource.
///
/// Throws [Hl7TranslationException] when the message lacks what the chosen
/// target needs - an ORU has no Encounter to build, and saying so is more use
/// than returning an empty resource that fails validation three nodes later.
Map<String, dynamic> hl7ToFhir(
  Hl7Message message, {
  Hl7FhirTarget target = Hl7FhirTarget.auto,
}) {
  final type = message.messageType;
  final resolved = target == Hl7FhirTarget.auto
      ? (type.startsWith('ORU')
            ? Hl7FhirTarget.observation
            : Hl7FhirTarget.encounter)
      : target;

  return switch (resolved) {
    Hl7FhirTarget.patient => hl7Patient(message),
    Hl7FhirTarget.encounter => hl7Encounter(message),
    Hl7FhirTarget.observation => _firstObservation(message),
    Hl7FhirTarget.bundle => hl7Bundle(message),
    Hl7FhirTarget.auto => throw StateError('unreachable'),
  };
}

Map<String, dynamic> _firstObservation(Hl7Message message) {
  final observations = hl7Observations(message);
  if (observations.isEmpty) {
    throw const Hl7TranslationException(
      'The message carries no OBX segment, so there is no Observation to '
      'build. Use the Bundle target for a message with several results.',
    );
  }
  return observations.first;
}

/// FHIR `Patient` from the PID segment.
Map<String, dynamic> hl7Patient(Hl7Message message) {
  final pid = message.segment('PID');
  if (pid == null) {
    throw const Hl7TranslationException(
      'The message has no PID segment, so there is no patient to identify.',
    );
  }
  final encoding = message.encoding;

  // PID-3 repeats: one entry per identifier the sending system knows. The
  // component layout is value ^^^ assigning authority ^ identifier type.
  final identifiers = <Map<String, dynamic>>[];
  for (final repetition in pid.field(3).split(encoding.repetition)) {
    if (repetition.isEmpty) continue;
    final parts = repetition.split(encoding.component);
    final value = encoding.decode(parts.isNotEmpty ? parts[0] : '');
    if (value.isEmpty) continue;
    final authority = parts.length > 3 ? encoding.decode(parts[3]) : '';
    final typeCode = parts.length > 4 ? encoding.decode(parts[4]) : 'MR';
    identifiers.add(
      pruneNulls(<String, dynamic>{
        'system': authority.isEmpty
            ? null
            : 'urn:oid:mini-hospital:${authority.toLowerCase()}',
        'value': value,
        'type': <String, dynamic>{
          'coding': <dynamic>[
            <String, dynamic>{
              'system': CodeSystems.identifierType,
              'code': typeCode,
            },
          ],
        },
      }),
    );
  }

  final family = pid.component(5, 1, encoding: encoding);
  final given = pid.component(5, 2, encoding: encoding);

  return pruneNulls(<String, dynamic>{
    'resourceType': 'Patient',
    if (identifiers.isNotEmpty) 'identifier': identifiers,
    'name': <dynamic>[
      pruneNulls(<String, dynamic>{
        'use': 'official',
        'family': family.isEmpty ? null : family,
        if (given.isNotEmpty) 'given': <String>[given],
      }),
    ],
    'gender': _fhirGender(pid.field(8)),
    'birthDate': _fhirDate(pid.field(7)),
    if (pid.field(11).isNotEmpty)
      'address': <dynamic>[
        pruneNulls(<String, dynamic>{
          'line': <String>[pid.component(11, 1, encoding: encoding)],
          'city': _orNull(pid.component(11, 3, encoding: encoding)),
          'postalCode': _orNull(pid.component(11, 5, encoding: encoding)),
          'country': _orNull(pid.component(11, 6, encoding: encoding)),
        }),
      ],
    if (pid.field(13).isNotEmpty)
      'telecom': <dynamic>[
        <String, dynamic>{
          'system': 'phone',
          'value': encoding.decode(pid.field(13)),
        },
      ],
    if (pid.field(15).isNotEmpty)
      'communication': <dynamic>[
        <String, dynamic>{
          'language': <String, dynamic>{
            'coding': <dynamic>[
              <String, dynamic>{
                'system': 'urn:ietf:bcp:47',
                'code': encoding.decode(pid.field(15)),
              },
            ],
          },
          'preferred': true,
        },
      ],
  });
}

/// FHIR `Encounter` from PV1, with the ADT trigger event carried through.
///
/// The trigger event matters downstream: an `A03` is a discharge whatever the
/// rest of the message says, and losing it would leave the receiving system
/// guessing from the presence of a discharge date.
Map<String, dynamic> hl7Encounter(Hl7Message message) {
  final pv1 = message.segment('PV1');
  if (pv1 == null) {
    throw const Hl7TranslationException(
      'The message has no PV1 segment, so there is no visit to describe.',
    );
  }
  final encoding = message.encoding;
  final event = message.segment('EVN')?.field(1) ?? '';
  final mrn = message.segment('PID')?.component(3, 1, encoding: encoding);

  final ward = pv1.component(3, 1, encoding: encoding);
  final room = pv1.component(3, 2, encoding: encoding);
  final bed = pv1.component(3, 3, encoding: encoding);

  final admitted = _fhirDateTime(pv1.field(44));
  final discharged = _fhirDateTime(pv1.field(45));

  return pruneNulls(<String, dynamic>{
    'resourceType': 'Encounter',
    if (pv1.field(19).isNotEmpty)
      'identifier': <dynamic>[
        <String, dynamic>{'value': encoding.decode(pv1.field(19))},
      ],
    // An A03 closes the visit even if PV1-45 was left empty, which sending
    // systems do more often than they should.
    'status': event == 'A03' || discharged != null
        ? 'finished'
        : (event == 'A05' ? 'planned' : 'in-progress'),
    'class': <String, dynamic>{
      'system': CodeSystems.encounterClass,
      'code': _fhirEncounterClass(pv1.field(2)),
    },
    if (mrn != null && mrn.isNotEmpty)
      'subject': <String, dynamic>{
        'identifier': <String, dynamic>{'value': mrn},
        'display': _patientDisplay(message),
      },
    if (admitted != null)
      'period': pruneNulls(<String, dynamic>{
        'start': admitted,
        'end': discharged,
      }),
    if (ward.isNotEmpty || bed.isNotEmpty)
      'location': <dynamic>[
        <String, dynamic>{
          'location': <String, dynamic>{
            'display': <String>[
              ward,
              room,
              bed,
            ].where((p) => p.isNotEmpty).join(' / '),
          },
        },
      ],
    if (event.isNotEmpty)
      // No FHIR element holds the v2 trigger event, so it travels as an
      // extension rather than being dropped. A receiving system that does not
      // know the extension ignores it, which is the behaviour FHIR intends.
      'extension': <dynamic>[
        <String, dynamic>{
          'url': triggerEventExtensionUrl,
          'valueCode': event,
        },
      ],
  });
}

/// One FHIR `Observation` per OBX segment.
List<Map<String, dynamic>> hl7Observations(Hl7Message message) {
  final encoding = message.encoding;
  final mrn = message.segment('PID')?.component(3, 1, encoding: encoding);
  final display = _patientDisplay(message);

  return <Map<String, dynamic>>[
    for (final obx in message.allSegments('OBX'))
      pruneNulls(<String, dynamic>{
        'resourceType': 'Observation',
        'status': _fhirObservationStatus(obx.field(11)),
        'category': <dynamic>[
          <String, dynamic>{
            'coding': <dynamic>[
              <String, dynamic>{
                'system': CodeSystems.observationCategory,
                'code': 'vital-signs',
              },
            ],
          },
        ],
        'code': <String, dynamic>{
          'coding': <dynamic>[
            pruneNulls(<String, dynamic>{
              // OBX-3.3 names the coding system. `LN` is LOINC; anything else
              // is a local code and is passed through unresolved rather than
              // guessed at.
              'system': obx.component(3, 3, encoding: encoding) == 'LN'
                  ? CodeSystems.loinc
                  : null,
              'code': _orNull(obx.component(3, 1, encoding: encoding)),
              'display': _orNull(obx.component(3, 2, encoding: encoding)),
            }),
          ],
        },
        if (mrn != null && mrn.isNotEmpty)
          'subject': <String, dynamic>{
            'identifier': <String, dynamic>{'value': mrn},
            'display': display,
          },
        'effectiveDateTime': _fhirDateTime(obx.field(14)),
        'valueQuantity': pruneNulls(<String, dynamic>{
          'value': double.tryParse(obx.field(5)),
          'unit': _orNull(encoding.decode(obx.field(6))),
          'system': CodeSystems.ucum,
          'code': _orNull(encoding.decode(obx.field(6))),
        }),
        if (obx.field(8).isNotEmpty && obx.field(8) != 'N')
          'interpretation': <dynamic>[
            <String, dynamic>{
              'coding': <dynamic>[
                <String, dynamic>{
                  'system':
                      'http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation',
                  'code': obx.field(8),
                },
              ],
            },
          ],
        if (obx.field(7).isNotEmpty)
          'referenceRange': <dynamic>[
            <String, dynamic>{'text': obx.field(7)},
          ],
        if (obx.field(18).isNotEmpty)
          'device': <String, dynamic>{
            'identifier': <String, dynamic>{
              'value': encoding.decode(obx.field(18)),
            },
          },
      }),
  ];
}

/// Everything in the message, as a `collection` Bundle.
Map<String, dynamic> hl7Bundle(Hl7Message message) {
  final entries = <Map<String, dynamic>>[];

  void add(Map<String, dynamic> Function() build) {
    try {
      entries.add(<String, dynamic>{'resource': build()});
    } on Hl7TranslationException {
      // A message without a PV1 is not an error when we are collecting
      // whatever is there; it just has no Encounter.
    }
  }

  add(() => hl7Patient(message));
  add(() => hl7Encounter(message));
  for (final observation in hl7Observations(message)) {
    entries.add(<String, dynamic>{'resource': observation});
  }

  return <String, dynamic>{
    'resourceType': 'Bundle',
    'type': 'collection',
    'entry': entries,
  };
}

String? _patientDisplay(Hl7Message message) {
  final pid = message.segment('PID');
  if (pid == null) return null;
  final family = pid.component(5, 1, encoding: message.encoding);
  final given = pid.component(5, 2, encoding: message.encoding);
  final joined = <String>[
    given,
    family,
  ].where((p) => p.isNotEmpty).join(' ').trim();
  return joined.isEmpty ? null : joined;
}

String? _orNull(String value) => value.isEmpty ? null : value;

String _fhirGender(String code) => switch (code.toUpperCase()) {
  'M' => 'male',
  'F' => 'female',
  'O' || 'A' => 'other',
  _ => 'unknown',
};

String _fhirEncounterClass(String code) => switch (code.toUpperCase()) {
  'I' => 'IMP',
  'E' => 'EMER',
  'O' => 'AMB',
  'P' => 'PRENC', // pre-admit
  'R' => 'AMB', // recurring patient
  _ => 'IMP',
};

String _fhirObservationStatus(String code) => switch (code.toUpperCase()) {
  'P' => 'preliminary',
  'C' => 'amended',
  'X' => 'cancelled',
  'I' => 'registered',
  _ => 'final',
};

/// `yyyyMMdd` to `yyyy-MM-dd`, or null when the field is absent or malformed.
String? _fhirDate(String value) {
  if (value.length < 8) return null;
  final year = value.substring(0, 4);
  final month = value.substring(4, 6);
  final day = value.substring(6, 8);
  if (int.tryParse('$year$month$day') == null) return null;
  return '$year-$month-$day';
}

/// `yyyyMMddHHmmss` to an ISO instant, tolerating the shorter forms v2 allows.
String? _fhirDateTime(String value) {
  final date = _fhirDate(value);
  if (date == null) return null;
  if (value.length < 12) return date;
  final hour = value.substring(8, 10);
  final minute = value.substring(10, 12);
  final second = value.length >= 14 ? value.substring(12, 14) : '00';
  return '${date}T$hour:$minute:$second';
}
