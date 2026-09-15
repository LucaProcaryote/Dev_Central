import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_core/hospital_core.dart';

/// A patient whose data is deliberately awkward: a hyphenated given name, an
/// apostrophe, and a `^` inside the address line that would split a field in
/// two if it were not escaped.
final Patient patient = Patient(
  id: 'pat-002',
  mrn: 'MRN000002',
  nationalNumber: '55.03.14-021.53',
  familyName: "D'Hondt^Dupont",
  givenName: 'Marie-Claire',
  gender: AdministrativeGender.female,
  birthDate: DateTime(1955, 3, 14),
  address: const Address(
    line: 'Rue de la Loi 16',
    city: 'Bruxelles',
    postalCode: '1000',
  ),
  phone: '+32 2 555 12 34',
  preferredLanguage: 'fr',
);

final Encounter encounter = Encounter(
  id: 'enc-002',
  patientId: 'pat-002',
  status: EncounterStatus.inProgress,
  encounterClass: EncounterClass.inpatient,
  admissionDate: DateTime(2026, 9, 12, 8, 30),
  wardId: 'ward-internal',
  roomId: '204',
  bedId: '204-B',
  admittingPractitioner: 'Dr Janssens',
  attendingPractitioner: 'Dr Peeters',
  visitNumber: 'VN-000002',
);

final Movement admission = Movement(
  id: 'mov-0021',
  encounterId: 'enc-002',
  patientId: 'pat-002',
  type: MovementType.admission,
  occurredAt: DateTime(2026, 9, 12, 8, 30),
  performedBy: 'usr-003',
);

final Observation temperature = Observation(
  id: 'obs-7001',
  patientId: 'pat-002',
  type: VitalSignType.bodyTemperature,
  value: 38.4,
  effectiveDateTime: DateTime(2026, 9, 14, 6, 15),
  deviceId: 'DEV3',
  encounterId: 'enc-002',
);

final Observation heartRate = Observation(
  id: 'obs-7002',
  patientId: 'pat-002',
  type: VitalSignType.heartRate,
  value: 112,
  effectiveDateTime: DateTime(2026, 9, 14, 6, 15),
  deviceId: 'DEV3',
  encounterId: 'enc-002',
);

const Hl7Builder builder = Hl7Builder();

void main() {
  group('ER7 encoding', () {
    test('MSH keeps HL7 numbering even though field 1 is the separator', () {
      final message = Hl7Message.parse(
        r'MSH|^~\&|MINI-ADT|MINI-HOSPITAL|MINI-EAI|MINI-HOSPITAL|'
        '20260912083000||ADT^A01^ADT_A01|MOV0021|T|2.5',
      );
      final msh = message.segment('MSH')!;

      expect(msh.field(1), '|');
      expect(msh.field(2), r'^~\&');
      expect(msh.field(3), 'MINI-ADT');
      expect(msh.field(9), 'ADT^A01^ADT_A01');
      expect(msh.field(10), 'MOV0021');
      expect(msh.field(12), '2.5');
    });

    test('messageType keeps the code and trigger, drops the structure', () {
      final message = builder.adt(
        patient: patient,
        encounter: encounter,
        movement: admission,
      );
      expect(message.segment('MSH')!.field(9), 'ADT^A01^ADT_A01');
      expect(message.messageType, 'ADT^A01');
    });

    test('a delimiter inside a value is escaped, not written raw', () {
      final message = builder.adt(
        patient: patient,
        encounter: encounter,
        movement: admission,
      );
      final line = message.toEr7().split('\r').firstWhere(
        (l) => l.startsWith('PID'),
      );

      // The patient's family name contains a component separator. Written
      // raw it would turn one name into three components; escaped, PID-5
      // still has exactly two - family and given.
      expect(line, contains(r"D'Hondt\S\Dupont"));
      expect(line.split('|')[5].split('^'), hasLength(2));
    });

    test('an escaped value round-trips back to the original text', () {
      final message = builder.adt(
        patient: patient,
        encounter: encounter,
        movement: admission,
      );
      final reparsed = Hl7Message.parse(message.toEr7());

      expect(
        reparsed.segment('PID')!.component(5, 1),
        "D'Hondt^Dupont",
      );
      expect(reparsed.segment('PID')!.component(5, 2), 'Marie-Claire');
    });

    test('parse then serialise leaves the message byte-identical', () {
      final original = builder
          .oru(
            patient: patient,
            observations: <Observation>[temperature, heartRate],
            encounter: encounter,
          )
          .toEr7();

      expect(Hl7Message.parse(original).toEr7(), original);
    });

    test('non-standard delimiters are read out of the header, not assumed', () {
      // Same message, written with the delimiters a sending system is
      // entitled to choose. A parser that hard-codes "|" sees one field.
      final message = Hl7Message.parse(
        'MSH!@~\\&!SEND!FAC!RECV!FAC!20260912083000!!ADT@A01!42!T!2.5',
      );
      expect(message.encoding.field, '!');
      expect(message.encoding.component, '@');
      expect(message.messageType, 'ADT^A01');
      expect(message.segment('MSH')!.field(3), 'SEND');
    });

    test('\\n and \\r\\n are accepted as segment separators', () {
      final crlf = Hl7Message.parse(
        'MSH|^~\\&|A|B|C|D|20260101000000||ADT^A01|1|T|2.5\r\n'
        'EVN|A01|20260101000000\n'
        'PID|1||MRN1||NAME',
      );
      expect(crlf.segments.map((s) => s.name), <String>['MSH', 'EVN', 'PID']);
    });
  });

  group('ADT^A0x from a movement', () {
    test('the trigger event is the one the ADT application already used', () {
      for (final type in <MovementType>[
        MovementType.admission,
        MovementType.transfer,
        MovementType.discharge,
      ]) {
        final message = builder.adt(
          patient: patient,
          encounter: encounter,
          movement: Movement(
            id: 'mov-x',
            encounterId: 'enc-002',
            patientId: 'pat-002',
            type: type,
            occurredAt: DateTime(2026, 9, 12),
            performedBy: 'usr-003',
          ),
        );
        expect(message.messageType, 'ADT^${type.hl7EventCode}');
        expect(message.segment('EVN')!.field(1), type.hl7EventCode);
      }
    });

    test('PID and PV1 carry the fields a receiving system reads', () {
      final message = builder.adt(
        patient: patient,
        encounter: encounter,
        movement: admission,
        wardName: 'Internal medicine',
        bedName: '204-B',
      );
      final pid = message.segment('PID')!;
      final pv1 = message.segment('PV1')!;

      expect(pid.component(3, 1), 'MRN000002');
      expect(pid.field(7), '19550314');
      expect(pid.field(8), 'F');
      expect(pid.component(11, 3), 'Bruxelles');

      expect(pv1.field(2), 'I');
      expect(pv1.component(3, 1), 'Internal medicine');
      expect(pv1.component(3, 3), '204-B');
      expect(pv1.field(19), 'VN-000002');
      expect(pv1.field(44), '20260912083000');
    });

    test('the national number rides along as a second PID-3 repetition', () {
      final message = builder.adt(
        patient: patient,
        encounter: encounter,
        movement: admission,
      );
      final repetitions = message.segment('PID')!.field(3).split('~');

      expect(repetitions, hasLength(2));
      expect(repetitions[0], contains('MRN000002'));
      expect(repetitions[1], contains('55.03.14-021.53'));
      expect(repetitions[1], endsWith('NN'));
    });

    test('a discharge carries PV1-45, an admission does not', () {
      final discharged = Encounter(
        id: 'enc-002',
        patientId: 'pat-002',
        status: EncounterStatus.finished,
        encounterClass: EncounterClass.inpatient,
        admissionDate: DateTime(2026, 9, 12, 8, 30),
        dischargeDate: DateTime(2026, 9, 14, 11, 0),
        visitNumber: 'VN-000002',
      );

      expect(
        builder
            .adt(
              patient: patient,
              encounter: encounter,
              movement: admission,
            )
            .segment('PV1')!
            .field(45),
        isEmpty,
      );
      expect(
        builder
            .adt(
              patient: patient,
              encounter: discharged,
              movement: Movement(
                id: 'mov-0022',
                encounterId: 'enc-002',
                patientId: 'pat-002',
                type: MovementType.discharge,
                occurredAt: DateTime(2026, 9, 14, 11, 0),
                performedBy: 'usr-003',
              ),
            )
            .segment('PV1')!
            .field(45),
        '20260914110000',
      );
    });
  });

  group('ORU^R01 from device readings', () {
    test('one OBX per observation, numbered from 1', () {
      final message = builder.oru(
        patient: patient,
        observations: <Observation>[temperature, heartRate],
        encounter: encounter,
      );
      final obx = message.allSegments('OBX');

      expect(message.messageType, 'ORU^R01');
      expect(obx, hasLength(2));
      expect(obx[0].field(1), '1');
      expect(obx[1].field(1), '2');
    });

    test('OBX-5 is the bare number and OBX-6 the unit', () {
      final obx = builder
          .oru(patient: patient, observations: <Observation>[temperature])
          .allSegments('OBX')
          .first;

      // A receiving system parses OBX-5 as a number. "38.4 °C" would give it
      // nothing, which is why the display format is not reused here.
      expect(obx.field(5), '38.4');
      expect(double.tryParse(obx.field(5)), 38.4);
      expect(obx.field(6), 'Cel');
    });

    test('the abnormal flag matches what the record already computes', () {
      final hot = builder
          .oru(patient: patient, observations: <Observation>[temperature])
          .allSegments('OBX')
          .first;
      expect(hot.field(8), 'H');
      expect(hot.field(8), temperature.interpretationCode);

      final normal = builder
          .oru(
            patient: patient,
            observations: <Observation>[
              Observation(
                id: 'obs-7003',
                patientId: 'pat-002',
                type: VitalSignType.bodyTemperature,
                value: 36.8,
                effectiveDateTime: DateTime(2026, 9, 14, 6, 15),
              ),
            ],
          )
          .allSegments('OBX')
          .first;
      expect(normal.field(8), 'N');
    });

    test('the device that produced the reading is named in OBX-18', () {
      final obx = builder
          .oru(patient: patient, observations: <Observation>[temperature])
          .allSegments('OBX')
          .first;
      expect(obx.field(18), 'DEV3');
    });
  });

  group('JSON view for the canvas', () {
    test('a field with components is addressable as PID.5.1', () {
      final json = builder
          .adt(patient: patient, encounter: encounter, movement: admission)
          .toJson();

      expect(readPath(json, 'PID.5.1'), "D'Hondt^Dupont");
      expect(readPath(json, 'PID.5.2'), 'Marie-Claire');
      expect(readPath(json, 'PID.8'), 'F');
      expect(readPath(json, 'message_type'), 'ADT^A01');
    });

    test('OBX is always a list, even when the message carries only one', () {
      final one = builder
          .oru(patient: patient, observations: <Observation>[temperature])
          .toJson();
      final two = builder
          .oru(
            patient: patient,
            observations: <Observation>[temperature, heartRate],
          )
          .toJson();

      // A flow written against one reading must not break when a second
      // arrives, so the shape is decided by the segment name rather than by
      // how many happened to turn up.
      expect(one['OBX'], isA<List<dynamic>>());
      expect(two['OBX'], isA<List<dynamic>>());
      expect(readPath(one, 'OBX.0.5'), '38.4');
      expect(readPath(two, 'OBX.1.5'), '112');
    });

    test('the original text travels with the parsed segments', () {
      final message = builder.adt(
        patient: patient,
        encounter: encounter,
        movement: admission,
      );
      expect(message.toJson()['hl7'], message.toEr7());
    });
  });

  group('HL7 v2 to FHIR', () {
    Hl7Message adtMessage() => builder.adt(
      patient: patient,
      encounter: encounter,
      movement: admission,
      wardName: 'Internal medicine',
      bedName: '204-B',
    );

    test('PID becomes a Patient, escaping undone', () {
      final resource = hl7ToFhir(adtMessage(), target: Hl7FhirTarget.patient);

      expect(resource['resourceType'], 'Patient');
      expect(readPath(resource, 'name.0.family'), "D'Hondt^Dupont");
      expect(readPath(resource, 'name.0.given.0'), 'Marie-Claire');
      expect(resource['gender'], 'female');
      expect(resource['birthDate'], '1955-03-14');
      expect(readPath(resource, 'address.0.city'), 'Bruxelles');
    });

    test('both PID-3 identifiers survive with their type codes', () {
      final resource = hl7ToFhir(adtMessage(), target: Hl7FhirTarget.patient);
      final identifiers = resource['identifier'] as List<dynamic>;

      expect(identifiers, hasLength(2));
      expect(readPath(identifiers[0], 'value'), 'MRN000002');
      expect(readPath(identifiers[0], 'type.coding.0.code'), 'MR');
      expect(readPath(identifiers[1], 'type.coding.0.code'), 'NN');
    });

    test('PV1 becomes an Encounter and auto is the default for ADT', () {
      final resource = hl7ToFhir(adtMessage());

      expect(resource['resourceType'], 'Encounter');
      expect(resource['status'], 'in-progress');
      expect(readPath(resource, 'class.code'), 'IMP');
      expect(readPath(resource, 'period.start'), '2026-09-12T08:30:00');
      expect(
        readPath(resource, 'location.0.location.display'),
        'Internal medicine / 204 / 204-B',
      );
    });

    test('the v2 trigger event survives as an extension', () {
      final resource = hl7ToFhir(adtMessage());

      // FHIR has nowhere to put A01, and dropping it would leave the receiver
      // unable to tell an admission from a correction.
      expect(readPath(resource, 'extension.0.url'), triggerEventExtensionUrl);
      expect(readPath(resource, 'extension.0.valueCode'), 'A01');
    });

    test('an A03 finishes the encounter even with no discharge date', () {
      final message = Hl7Message.parse(
        'MSH|^~\\&|A|B|C|D|20260914110000||ADT^A03|1|T|2.5\r'
        'EVN|A03|20260914110000\r'
        'PID|1||MRN000002||DUPONT^Marie-Claire||19550314|F\r'
        'PV1|1|I|Internal medicine',
      );
      expect(hl7ToFhir(message)['status'], 'finished');
    });

    test('OBX becomes an Observation with LOINC, UCUM and the device', () {
      final message = builder.oru(
        patient: patient,
        observations: <Observation>[temperature],
        encounter: encounter,
      );
      final resource = hl7ToFhir(message);

      expect(resource['resourceType'], 'Observation');
      expect(readPath(resource, 'code.coding.0.code'), '8310-5');
      expect(readPath(resource, 'code.coding.0.system'), CodeSystems.loinc);
      expect(readPath(resource, 'valueQuantity.value'), 38.4);
      expect(readPath(resource, 'valueQuantity.code'), 'Cel');
      expect(readPath(resource, 'interpretation.0.coding.0.code'), 'H');
      expect(readPath(resource, 'device.identifier.value'), 'DEV3');
      expect(readPath(resource, 'subject.identifier.value'), 'MRN000002');
    });

    test('a local code is passed through without a system rather than '
        'being labelled LOINC', () {
      final message = Hl7Message.parse(
        'MSH|^~\\&|A|B|C|D|20260914061500||ORU^R01|1|T|2.5\r'
        'PID|1||MRN000002||DUPONT^Marie-Claire||19550314|F\r'
        'OBR|1||o1|74728-7^Vital signs^LN\r'
        'OBX|1|NM|LOCAL-TEMP^Temp^L||38.4|Cel|||||F|||20260914061500',
      );
      final resource = hl7ToFhir(message);

      expect(readPath(resource, 'code.coding.0.code'), 'LOCAL-TEMP');
      expect(readPath(resource, 'code.coding.0.system'), isNull);
    });

    test('the bundle target collects everything the message holds', () {
      final message = builder.oru(
        patient: patient,
        observations: <Observation>[temperature, heartRate],
        encounter: encounter,
      );
      final bundle = hl7ToFhir(message, target: Hl7FhirTarget.bundle);
      final types = (bundle['entry'] as List<dynamic>)
          .map((e) => readPath(e, 'resource.resourceType'))
          .toList();

      expect(bundle['resourceType'], 'Bundle');
      expect(types, <String>[
        'Patient',
        'Encounter',
        'Observation',
        'Observation',
      ]);
    });

    test('a message with several results says so instead of silently '
        'translating the first', () {
      final message = Hl7Message.parse(
        'MSH|^~\\&|A|B|C|D|20260914061500||ORU^R01|1|T|2.5\r'
        'PID|1||MRN000002||DUPONT^Marie-Claire||19550314|F',
      );

      expect(
        () => hl7ToFhir(message),
        throwsA(isA<Hl7TranslationException>()),
      );
    });

    test('a missing PID is reported, not papered over', () {
      final message = Hl7Message.parse(
        'MSH|^~\\&|A|B|C|D|20260101000000||ADT^A01|1|T|2.5\r'
        'EVN|A01|20260101000000',
      );

      expect(
        () => hl7ToFhir(message, target: Hl7FhirTarget.patient),
        throwsA(isA<Hl7TranslationException>()),
      );
    });
  });

  group('HL7 nodes on the canvas', () {
    FlowNode node(
      String id,
      FlowNodeType type, {
      Map<String, dynamic> config = const <String, dynamic>{},
    }) => FlowNode(id: id, type: type, label: '', x: 0, y: 0, config: config);

    IntegrationFlow flowOf(
      List<FlowNode> nodes,
      List<FlowConnection> connections,
    ) => IntegrationFlow(
      id: 'flow-hl7',
      name: const LocalizedText(en: 'HL7', fr: 'HL7', nl: 'HL7'),
      description: const LocalizedText(en: '', fr: '', nl: ''),
      isEnabled: true,
      nodes: nodes,
      connections: connections,
      updatedAt: DateTime(2026, 9, 14),
    );

    IntegrationMessage messageWith(Map<String, dynamic> payload) =>
        IntegrationMessage(
          id: 'msg-1',
          messageType: 'ADT^A01',
          sourceApp: 'ADT',
          payload: payload,
          status: MessageStatus.received,
          receivedAt: DateTime(2026, 9, 14),
        );

    test('source, translator and FHIR store run end to end', () async {
      final stored = <Map<String, dynamic>>[];
      final engine = FlowEngine(
        FlowExecutionContext(
          lookupPatient: (_) async => null,
          writeToFhirStore: (resource) async {
            stored.add(resource);
            return '${resource['resourceType']}/1';
          },
          deliverToApplication: (_, __) async {},
          postToUrl: (_, __) async {},
        ),
      );

      final flow = flowOf(
        <FlowNode>[
          node('a', FlowNodeType.hl7Source),
          node('b', FlowNodeType.hl7ToFhir),
          node('c', FlowNodeType.fhirStore),
        ],
        const <FlowConnection>[
          FlowConnection(id: '1', fromNodeId: 'a', toNodeId: 'b'),
          FlowConnection(id: '2', fromNodeId: 'b', toNodeId: 'c'),
        ],
      );

      final result = await engine.run(
        flow,
        messageWith(<String, dynamic>{
          'hl7': builder
              .adt(
                patient: patient,
                encounter: encounter,
                movement: admission,
              )
              .toEr7(),
        }),
      );

      expect(result.status, MessageStatus.delivered);
      expect(stored, hasLength(1));
      expect(stored.single['resourceType'], 'Encounter');
      expect(result.trace.first.detail, contains('Parsed ADT^A01'));
      expect(result.trace[1].detail, contains('to Encounter'));
    });

    test('a payload that is not HL7 fails at the source with a reason',
        () async {
      final engine = FlowEngine(FlowExecutionContext.dryRun());
      final flow = flowOf(
        <FlowNode>[
          node('a', FlowNodeType.hl7Source),
          node('b', FlowNodeType.logDestination),
        ],
        const <FlowConnection>[
          FlowConnection(id: '1', fromNodeId: 'a', toNodeId: 'b'),
        ],
      );

      final result = await engine.run(
        flow,
        messageWith(<String, dynamic>{'hl7': 'this is not a message'}),
      );

      expect(result.status, MessageStatus.failed);
      expect(result.error, contains('MSH'));
    });

    test('a filter can route on a parsed v2 field', () async {
      final engine = FlowEngine(FlowExecutionContext.dryRun());
      final flow = flowOf(
        <FlowNode>[
          node('a', FlowNodeType.hl7Source),
          node(
            'b',
            FlowNodeType.filter,
            config: const <String, dynamic>{
              'path': 'PV1.2',
              'operator': 'equals',
              'value': 'I',
            },
          ),
          node('c', FlowNodeType.logDestination),
        ],
        const <FlowConnection>[
          FlowConnection(id: '1', fromNodeId: 'a', toNodeId: 'b'),
          FlowConnection(id: '2', fromNodeId: 'b', toNodeId: 'c'),
        ],
      );

      final inpatient = await engine.run(
        flow,
        messageWith(<String, dynamic>{
          'hl7': builder
              .adt(
                patient: patient,
                encounter: encounter,
                movement: admission,
              )
              .toEr7(),
        }),
      );
      expect(inpatient.status, MessageStatus.delivered);

      final outpatient = await engine.run(
        flow,
        messageWith(<String, dynamic>{
          'hl7': builder
              .adt(
                patient: patient,
                encounter: Encounter(
                  id: 'enc-003',
                  patientId: 'pat-002',
                  status: EncounterStatus.inProgress,
                  encounterClass: EncounterClass.outpatient,
                  admissionDate: DateTime(2026, 9, 12, 8, 30),
                ),
                movement: admission,
              )
              .toEr7(),
        }),
      );
      expect(outpatient.status, MessageStatus.filtered);
    });

    test('the destination hands the application the v2 text unchanged',
        () async {
      final delivered = <String, Map<String, dynamic>>{};
      final engine = FlowEngine(
        FlowExecutionContext(
          lookupPatient: (_) async => null,
          writeToFhirStore: (_) async => 'x',
          deliverToApplication: (app, payload) async =>
              delivered[app] = payload,
          postToUrl: (_, __) async {},
        ),
      );
      final original = builder
          .adt(patient: patient, encounter: encounter, movement: admission)
          .toEr7();

      final flow = flowOf(
        <FlowNode>[
          node('a', FlowNodeType.hl7Source),
          node(
            'b',
            FlowNodeType.hl7Destination,
            config: const <String, dynamic>{'app': 'EHR'},
          ),
        ],
        const <FlowConnection>[
          FlowConnection(id: '1', fromNodeId: 'a', toNodeId: 'b'),
        ],
      );

      final result = await engine.run(
        flow,
        messageWith(<String, dynamic>{'hl7': original}),
      );

      expect(result.status, MessageStatus.delivered);
      expect(delivered['EHR']!['hl7'], original);
    });

    test('the seeded HL7 flow carries a real admission all the way to FHIR',
        () async {
      // The other seeded-flow test only checks the graph is well formed. This
      // one runs a message through it, because a flow the students open on
      // day one had better work.
      final stored = <Map<String, dynamic>>[];
      final delivered = <String, Map<String, dynamic>>{};
      final engine = FlowEngine(
        FlowExecutionContext(
          lookupPatient: (_) async => null,
          writeToFhirStore: (resource) async {
            stored.add(resource);
            return 'Encounter/1';
          },
          deliverToApplication: (app, payload) async =>
              delivered[app] = payload,
          postToUrl: (_, __) async {},
        ),
      );

      final flow = HospitalSeed.build(now: DateTime.utc(2026, 9, 14)).flows
          .firstWhere((f) => f.id == 'flow-hl7-adt');

      final result = await engine.run(
        flow,
        messageWith(<String, dynamic>{
          'hl7': builder
              .adt(
                patient: patient,
                encounter: encounter,
                movement: admission,
                wardName: 'Internal medicine',
              )
              .toEr7(),
        }),
      );

      expect(result.status, MessageStatus.delivered);
      expect(stored.single['resourceType'], 'Encounter');
      expect(
        readPath(stored.single, 'subject.identifier.value'),
        'MRN000002',
      );
      expect(delivered.keys, <String>['EHR']);
    });

    test('every node type is still executable', () async {
      // The engine switches exhaustively on FlowNodeType, so a new node
      // cannot be added to the model without being handled here. This test
      // makes the same promise about the palette the students see.
      final engine = FlowEngine(FlowExecutionContext.dryRun());
      for (final type in FlowNodeType.values) {
        final flow = flowOf(<FlowNode>[node('only', type)], const []);
        final result = await engine.run(
          flow,
          messageWith(<String, dynamic>{'hl7': ''}),
          entryNodeId: 'only',
        );
        expect(
          result.trace,
          hasLength(1),
          reason: '${type.name} produced no trace step',
        );
      }
    });
  });

  group('what the applications put on the wire', () {
    test('an ADT movement carries both the JSON event and the v2 message', () {
      final message = builder.adt(
        patient: patient,
        encounter: encounter,
        movement: admission,
      );

      // The publisher builds exactly this and files it under "hl7" beside the
      // JSON, so a flow can be written against either representation of the
      // same admission.
      final parsed = Hl7Message.parse(message.toEr7());
      expect(parsed.messageType, 'ADT^A01');
      expect(parsed.sendingApplication, 'MINI-ADT');
    });

    test('a device reading says it came from the device feed, not the ADT', () {
      // MSH-3 is what a receiving system routes on. A monitor claiming to be
      // the admissions system is how a message ends up in the wrong queue.
      const deviceBuilder = Hl7Builder(sendingApplication: 'MINI-DEV');
      final message = deviceBuilder.oru(
        patient: patient,
        observations: <Observation>[temperature],
      );

      expect(message.sendingApplication, 'MINI-DEV');
      expect(message.messageType, 'ORU^R01');
    });
  });
}
