import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_core/hospital_core.dart';

/// Records what the flow tried to do to the outside world.
class _RecordingContext {
  final List<Map<String, dynamic>> stored = <Map<String, dynamic>>[];
  final List<({String app, Map<String, dynamic> payload})> delivered =
      <({String app, Map<String, dynamic> payload})>[];
  final List<String> postedUrls = <String>[];

  FlowExecutionContext build({Patient? patient}) => FlowExecutionContext(
        lookupPatient: (_) async => patient,
        writeToFhirStore: (resource) async {
          stored.add(resource);
          return resource['id']?.toString() ?? 'generated';
        },
        deliverToApplication: (app, payload) async {
          delivered.add((app: app, payload: payload));
        },
        postToUrl: (url, _) async => postedUrls.add(url),
      );
}

IntegrationMessage _message(Map<String, dynamic> payload, {String type = 'Observation'}) =>
    IntegrationMessage(
      id: 'msg-1',
      messageType: type,
      sourceApp: 'DEV1',
      payload: payload,
      status: MessageStatus.received,
      receivedAt: DateTime.utc(2026, 9, 12, 10),
    );

Map<String, dynamic> _spo2(double value) => Observation(
      id: 'obs-test',
      patientId: 'pat-001',
      type: VitalSignType.oxygenSaturation,
      value: value,
      effectiveDateTime: DateTime.utc(2026, 9, 12, 10),
      deviceId: 'DEV3',
    ).toFhir();

void main() {
  final seed = HospitalSeed.build(now: DateTime.utc(2026, 9, 12, 10));

  group('json path', () {
    const document = <String, dynamic>{
      'resourceType': 'Observation',
      'subject': <String, dynamic>{'reference': 'Patient/pat-001'},
      'code': <String, dynamic>{
        'coding': <dynamic>[
          <String, dynamic>{'code': '2708-6'}
        ],
      },
      'valueQuantity': <String, dynamic>{'value': 91.0},
    };

    test('reads nested objects and array indices', () {
      expect(readPath(document, 'resourceType'), 'Observation');
      expect(readPath(document, 'subject.reference'), 'Patient/pat-001');
      expect(readPath(document, 'code.coding.0.code'), '2708-6');
      expect(readPath(document, 'valueQuantity.value'), 91.0);
    });

    test('returns null for a path that is not there', () {
      expect(readPath(document, 'nope'), isNull);
      expect(readPath(document, 'subject.missing.deeper'), isNull);
      expect(readPath(document, 'code.coding.9.code'), isNull);
      expect(readPath(document, 'resourceType.nested'), isNull);
    });

    test('writing creates intermediate maps without mutating the input', () {
      final result = writePath(document, 'alert.severity', 'high');
      expect(readPath(result, 'alert.severity'), 'high');
      // The original must be untouched, or one branch of a flow would corrupt
      // the payload another branch is still holding.
      expect(readPath(document, 'alert.severity'), isNull);
      expect(readPath(result, 'subject.reference'), 'Patient/pat-001');
    });

    test('writing deep-copies nested structures', () {
      final result = writePath(document, 'subject.display', 'Émile');
      expect(readPath(result, 'subject.display'), 'Émile');
      expect((document['subject'] as Map).containsKey('display'), isFalse);
    });

    test('collectLeafPaths enumerates the fields a mapper can pick', () {
      final paths = collectLeafPaths(document);
      expect(paths, contains('subject.reference'));
      expect(paths, contains('code.coding.0.code'));
      expect(paths, contains('valueQuantity.value'));
    });
  });

  group('field transforms', () {
    test('each transform does what its name says', () {
      expect(FieldTransform.uppercase.apply('abc', null), 'ABC');
      expect(FieldTransform.lowercase.apply('ABC', null), 'abc');
      expect(FieldTransform.trim.apply('  x  ', null), 'x');
      expect(FieldTransform.dateOnly.apply('2026-09-12T10:30:00Z', null),
          '2026-09-12');
      expect(FieldTransform.toNumber.apply('42.5', null), 42.5);
      expect(FieldTransform.constant.apply('ignored', 'fixed'), 'fixed');
      expect(FieldTransform.prefix.apply('001', 'MRN'), 'MRN001');
      expect(FieldTransform.suffix.apply('12', ' kg'), '12 kg');
      expect(FieldTransform.stripPrefix.apply('Patient/pat-001', 'Patient/'),
          'pat-001');
      expect(FieldTransform.defaultIfEmpty.apply('', 'unknown'), 'unknown');
      expect(FieldTransform.defaultIfEmpty.apply('given', 'unknown'), 'given');
    });

    test('transforms tolerate null input rather than throwing', () {
      for (final transform in FieldTransform.values) {
        expect(() => transform.apply(null, 'arg'), returnsNormally,
            reason: '${transform.name} threw on null');
      }
    });

    test('filter operators compare as expected', () {
      expect(FilterOperator.equals.evaluate('a', 'a'), isTrue);
      expect(FilterOperator.notEquals.evaluate('a', 'b'), isTrue);
      expect(FilterOperator.contains.evaluate('abcdef', 'cde'), isTrue);
      expect(FilterOperator.startsWith.evaluate('Patient/1', 'Patient/'), isTrue);
      expect(FilterOperator.exists.evaluate('x', ''), isTrue);
      expect(FilterOperator.exists.evaluate(null, ''), isFalse);
      expect(FilterOperator.notExists.evaluate(null, ''), isTrue);
      expect(FilterOperator.greaterThan.evaluate(95, '92'), isTrue);
      expect(FilterOperator.lessThan.evaluate(88, '92'), isTrue);
      // A non-numeric value must not silently compare as zero.
      expect(FilterOperator.lessThan.evaluate('abc', '92'), isFalse);
    });
  });

  group('flow engine', () {
    test('the SpO2 alert flow drops a normal reading', () async {
      final flow = seed.flows.firstWhere((f) => f.id == 'flow-spo2-alert');
      final recorder = _RecordingContext();
      final engine = FlowEngine(recorder.build());

      final result = await engine.run(flow, _message(_spo2(97)));

      expect(result.status, MessageStatus.filtered);
      expect(recorder.delivered, isEmpty);
      // The trace must still explain why it stopped.
      expect(result.trace.any((s) => s.status == MessageStatus.filtered), isTrue);
      final dropped =
          result.trace.firstWhere((s) => s.status == MessageStatus.filtered);
      expect(dropped.detail, contains('92'));
    });

    test('the SpO2 alert flow raises an alert for a low reading', () async {
      final flow = seed.flows.firstWhere((f) => f.id == 'flow-spo2-alert');
      final recorder = _RecordingContext();
      final engine = FlowEngine(recorder.build());

      final result = await engine.run(flow, _message(_spo2(88)));

      expect(result.status, MessageStatus.delivered);
      // The mapper should have reshaped the FHIR resource into a flat alert.
      final logStep = result.trace.last;
      expect(logStep.nodeType, FlowNodeType.logDestination);

      final mapped = result.trace
          .firstWhere((s) => s.nodeType == FlowNodeType.mapper)
          .payloadAfter!;
      expect(mapped['severity'], 'high');
      expect(mapped['patient'], 'pat-001');
      expect(mapped['spo2'], 88.0);
      expect(mapped['device'], 'DEV3');
      // The mapper does not keep unmapped fields unless told to.
      expect(mapped.containsKey('resourceType'), isFalse);
    });

    test('the vitals flow validates, enriches and stores', () async {
      final flow = seed.flows.firstWhere((f) => f.id == 'flow-vitals');
      final recorder = _RecordingContext();
      final patient = seed.patients.firstWhere((p) => p.id == 'pat-001');
      final engine = FlowEngine(recorder.build(patient: patient));

      final result = await engine.run(flow, _message(_spo2(95)));

      expect(result.status, MessageStatus.delivered);
      expect(recorder.stored, hasLength(1));
      expect(recorder.delivered.map((d) => d.app), contains('EHR'));

      final enriched = result.trace
          .firstWhere((s) => s.nodeType == FlowNodeType.enricher)
          .payloadAfter!;
      expect(readPath(enriched, 'patient.mrn'), patient.mrn);
      expect(readPath(enriched, 'patient.family_name'), patient.familyName);
      // Enrichment must add, never replace.
      expect(readPath(enriched, 'resourceType'), 'Observation');
    });

    test('the validator rejects a resource missing a required element', () async {
      final flow = seed.flows.firstWhere((f) => f.id == 'flow-vitals');
      final recorder = _RecordingContext();
      final engine = FlowEngine(recorder.build());

      final broken = Map<String, dynamic>.from(_spo2(95))..remove('subject');
      final result = await engine.run(flow, _message(broken));

      expect(result.status, MessageStatus.failed);
      expect(result.error, contains('subject'));
      expect(recorder.stored, isEmpty,
          reason: 'nothing may reach the FHIR store after a validation failure');
    });

    test('the validator rejects a payload that is not FHIR at all', () async {
      final flow = seed.flows.firstWhere((f) => f.id == 'flow-vitals');
      final recorder = _RecordingContext();
      final engine = FlowEngine(recorder.build());

      final result = await engine.run(
        flow,
        _message(<String, dynamic>{'temperature': 37.2}),
      );

      expect(result.status, MessageStatus.failed);
      expect(result.error, contains('resourceType'));
    });

    test('the router sends each movement type down its own branch', () async {
      final flow = seed.flows.firstWhere((f) => f.id == 'flow-adt');

      for (final entry in <String, String>{
        'admission': 'EHR',
        'transfer': 'EHR',
        'discharge': 'PHARM',
      }.entries) {
        final recorder = _RecordingContext();
        final engine = FlowEngine(recorder.build());
        final result = await engine.run(
          flow,
          _message(
            <String, dynamic>{'type': entry.key, 'patient_id': 'pat-001'},
            type: 'ADT',
          ),
        );
        expect(result.status, MessageStatus.delivered);
        expect(recorder.delivered, hasLength(1));
        expect(recorder.delivered.single.app, entry.value);
      }
    });

    test('a disabled flow processes nothing', () async {
      final flow = seed.flows.first.copyWith(isEnabled: false);
      final recorder = _RecordingContext();
      final engine = FlowEngine(recorder.build());

      final result = await engine.run(flow, _message(_spo2(88)));

      expect(result.status, MessageStatus.filtered);
      expect(result.error, contains('disabled'));
      expect(result.trace, isEmpty);
    });

    test('a cycle on the canvas stops instead of hanging', () async {
      final flow = IntegrationFlow(
        id: 'flow-loop',
        name: const LocalizedText.same('Loop'),
        description: const LocalizedText.same('Deliberately circular'),
        isEnabled: true,
        updatedAt: DateTime.utc(2026, 9, 12),
        nodes: const <FlowNode>[
          FlowNode(id: 'a', type: FlowNodeType.httpSource, label: 'In', x: 0, y: 0),
          FlowNode(id: 'b', type: FlowNodeType.mapper, label: 'B', x: 1, y: 0),
          FlowNode(id: 'c', type: FlowNodeType.mapper, label: 'C', x: 2, y: 0),
        ],
        connections: const <FlowConnection>[
          FlowConnection(id: '1', fromNodeId: 'a', toNodeId: 'b'),
          FlowConnection(id: '2', fromNodeId: 'b', toNodeId: 'c'),
          FlowConnection(id: '3', fromNodeId: 'c', toNodeId: 'b'),
        ],
      );
      final engine = FlowEngine(FlowExecutionContext.dryRun());

      final result = await engine
          .run(flow, _message(<String, dynamic>{'x': 1}))
          .timeout(const Duration(seconds: 5));

      expect(result.status, MessageStatus.failed);
      expect(result.error, contains('loop'));
    });

    test('a flow with no source cannot be entered', () async {
      final flow = IntegrationFlow(
        id: 'flow-nosource',
        name: const LocalizedText.same('No source'),
        description: const LocalizedText.same(''),
        isEnabled: true,
        updatedAt: DateTime.utc(2026, 9, 12),
        nodes: const <FlowNode>[
          FlowNode(id: 'x', type: FlowNodeType.logDestination, label: 'Log', x: 0, y: 0),
        ],
        connections: const <FlowConnection>[],
      );
      final engine = FlowEngine(FlowExecutionContext.dryRun());

      final result = await engine.run(flow, _message(<String, dynamic>{}));
      expect(result.status, MessageStatus.failed);
      expect(result.error, contains('source'));
    });
  });

  group('flow validation', () {
    test('the seeded flows are all structurally valid', () {
      for (final flow in seed.flows) {
        expect(flow.validate(), isEmpty,
            reason: '${flow.id}: ${flow.validate().map((i) => i.message.en)}');
      }
    });

    test('an empty flow reports that it is empty', () {
      final flow = IntegrationFlow(
        id: 'f',
        name: const LocalizedText.same('Empty'),
        description: const LocalizedText.same(''),
        isEnabled: true,
        updatedAt: DateTime.utc(2026, 9, 12),
        nodes: const <FlowNode>[],
        connections: const <FlowConnection>[],
      );
      final issues = flow.validate();
      expect(issues, hasLength(1));
      expect(issues.single.message.fr, contains('vide'));
      expect(issues.single.message.nl, contains('leeg'));
    });

    test('a dangling block is reported against that block', () {
      final flow = IntegrationFlow(
        id: 'f',
        name: const LocalizedText.same('Dangling'),
        description: const LocalizedText.same(''),
        isEnabled: true,
        updatedAt: DateTime.utc(2026, 9, 12),
        nodes: const <FlowNode>[
          FlowNode(id: 'a', type: FlowNodeType.httpSource, label: 'In', x: 0, y: 0),
          FlowNode(id: 'b', type: FlowNodeType.logDestination, label: 'Log', x: 1, y: 0),
        ],
        connections: const <FlowConnection>[],
      );
      final issues = flow.validate();
      expect(issues.map((i) => i.nodeId), containsAll(<String>['a', 'b']));
    });
  });
}
