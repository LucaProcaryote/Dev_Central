import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_core/hospital_core.dart';

final Patient patient = Patient(
  id: 'pat-002',
  mrn: 'MRN000002',
  familyName: 'Dupont',
  givenName: 'Marie-Claire',
  gender: AdministrativeGender.female,
  birthDate: DateTime(1955, 3, 14),
  address: const Address(
    line: 'Rue de la Loi 16',
    city: 'Bruxelles',
    postalCode: '1000',
  ),
);

final DeviceReading heartRate = DeviceReading(
  deviceId: 'DEV3',
  patientId: 'pat-002',
  metric: 'heartRate',
  value: 112,
  unit: '/min',
  at: DateTime.utc(2026, 9, 15, 6, 15),
  location: const DeviceLocation(wardId: 'ward-icu', bedId: 'bed-221a'),
  sequence: 41,
);

void main() {
  group('the topic tree', () {
    test('a reading is addressed by ward, bed, device and measurement', () {
      expect(
        heartRate.topic,
        'hospital/ward/ward-icu/bed/bed-221a/device/DEV3/heartRate',
      );
    });

    test('a device with no bed is addressed explicitly, not with a gap', () {
      // An empty segment is legal MQTT and reads as a mistake. "unassigned"
      // says the absence was known.
      expect(
        MqttTopics.reading(deviceId: 'apple-watch', metric: 'activitySteps'),
        'hospital/ward/unassigned/bed/unassigned/device/apple-watch/activitySteps',
      );
    });

    test('liveness is kept out of the location tree', () {
      // Where a monitor stands has nothing to do with whether it is talking,
      // and a status topic under the bed would move when the bed did.
      expect(MqttTopics.status('DEV3'), 'hospital/device/DEV3/status');
    });

    test('a separator inside an identifier cannot add a topic level', () {
      // Nothing in the seed data contains one, but a topic built from a ward
      // *name* one day would, and the extra level would silently stop every
      // subscriber from matching.
      final topic = MqttTopics.reading(
        deviceId: 'DEV/9',
        metric: 'heartRate',
        location: const DeviceLocation(wardId: 'a+b', bedId: 'c#d'),
      );
      expect(topic.split('/'), hasLength(8));
      expect(topic, contains('ward/a-b'));
      expect(topic, contains('device/DEV-9'));
    });

    test('a topic round-trips back to its parts', () {
      final parsed = MqttTopics.parseReading(heartRate.topic)!;
      expect(parsed.deviceId, 'DEV3');
      expect(parsed.metric, 'heartRate');
      expect(parsed.location.wardId, 'ward-icu');
      expect(parsed.location.bedId, 'bed-221a');
    });

    test('unassigned reads back as no ward rather than as a ward called '
        'unassigned', () {
      final parsed = MqttTopics.parseReading(
        MqttTopics.reading(deviceId: 'apple-watch', metric: 'heartRate'),
      )!;
      expect(parsed.location.wardId, isNull);
      expect(parsed.location.bedId, isNull);
    });

    test('a status topic is not mistaken for a reading', () {
      expect(MqttTopics.parseReading(MqttTopics.status('DEV3')), isNull);
      expect(MqttTopics.parseStatus(heartRate.topic), isNull);
      expect(MqttTopics.parseStatus(MqttTopics.status('DEV3')), 'DEV3');
    });
  });

  group('wildcard matching', () {
    test('# takes the rest of the tree', () {
      expect(MqttTopics.matches('hospital/ward/#', heartRate.topic), isTrue);
      expect(
        MqttTopics.matches(
          MqttTopics.wardReadings('ward-icu'),
          heartRate.topic,
        ),
        isTrue,
      );
      expect(
        MqttTopics.matches(
          MqttTopics.wardReadings('ward-surgery'),
          heartRate.topic,
        ),
        isFalse,
      );
    });

    test('+ takes exactly one level, which is the whole difference', () {
      expect(
        MqttTopics.matches(
          MqttTopics.metricEverywhere('heartRate'),
          heartRate.topic,
        ),
        isTrue,
      );
      // One level short: a plus does not span the tree the way a hash does.
      expect(
        MqttTopics.matches('hospital/ward/+/heartRate', heartRate.topic),
        isFalse,
      );
    });

    test('an exact filter matches only its own topic', () {
      expect(MqttTopics.matches(heartRate.topic, heartRate.topic), isTrue);
      expect(
        MqttTopics.matches('hospital/ward/ward-icu', heartRate.topic),
        isFalse,
      );
    });
  });

  group('what a device puts on the wire', () {
    test('a compact payload, not a FHIR resource', () {
      final json = heartRate.toJson();

      // A monitor sending this every few seconds over a link it does not own
      // sends the measurement, not a clinical document. Building the resource
      // is the receiving system's job, which is why there is a node for it.
      expect(json.keys, containsAll(<String>['device', 'metric', 'value']));
      expect(json.containsKey('resourceType'), isFalse);
      expect(json['unit'], '/min');
      expect(json['seq'], 41);
    });

    test('a payload round-trips, with the topic filling in the location', () {
      // The location is in the address, so a device need not repeat it in
      // every message - and a receiver that read only the payload would lose
      // it entirely.
      final stripped = Map<String, dynamic>.from(heartRate.toJson())
        ..remove('ward')
        ..remove('bed');
      final parsed = DeviceReading.fromJson(
        stripped,
        topic: MqttTopics.parseReading(heartRate.topic),
      );

      expect(parsed.location.wardId, 'ward-icu');
      expect(parsed.location.bedId, 'bed-221a');
      expect(parsed.value, 112);
      expect(parsed.at, heartRate.at);
    });

    test('a reading becomes an Observation with its LOINC code resolved', () {
      final observation = heartRate.toObservation(id: 'obs-1');

      expect(observation.type, VitalSignType.heartRate);
      expect(observation.type.loincCode, '8867-4');
      expect(observation.deviceId, 'DEV3');
      expect(observation.isAbnormal, isTrue);
    });
  });

  group('the feed', () {
    late FakeMqttTransport broker;
    late DeviceFeed feed;

    setUp(() {
      broker = FakeMqttTransport();
      feed = DeviceFeed(broker);
    });

    tearDown(() async {
      await feed.close();
      await broker.close();
    });

    test('a reading published reaches a subscriber on a wildcard', () async {
      await feed.connectAsObserver();
      final received = feed.events.firstWhere((e) => e is ReadingEvent);

      broker.publish(heartRate.topic, heartRate.encode());

      final event = await received as ReadingEvent;
      expect(event.reading.deviceId, 'DEV3');
      expect(event.reading.value, 112);
    });

    test('a reading is published at most once and not retained', () async {
      await broker.connect();
      feed.publishReading(heartRate);

      // A vital sign is a moment, not a state. Retaining it would hand the
      // next subscriber an hour-old heart rate as though it were current.
      expect(broker.published, hasLength(1));
      final replayed = <MqttEnvelope>[];
      broker.messages.listen(replayed.add);
      broker.subscribe(MqttTopics.allReadings);
      await Future<void>.delayed(Duration.zero);
      expect(replayed, isEmpty);
    });

    test(
      'presence is retained, so a screen opened later still learns it',
      () async {
        await broker.connect();
        feed.announce(
          'DEV3',
          DevicePresence.online,
          now: DateTime.utc(2026, 9, 15),
        );

        // Subscribing after the fact: a real broker replays what it kept.
        final late = DeviceFeed(broker);
        final seen = late.events.firstWhere((e) => e is PresenceEvent);
        await late.connectAsObserver();

        final event = await seen as PresenceEvent;
        expect(event.status.presence, DevicePresence.online);
        expect(event.retained, isTrue, reason: 'a replay is not news');
        await late.close();
      },
    );

    test(
      'a device that stops answering is announced by the broker itself',
      () async {
        final observer = DeviceFeed(broker);
        await observer.connectAsObserver();
        final offline = observer.events.firstWhere(
          (e) =>
              e is PresenceEvent && e.status.presence == DevicePresence.offline,
        );

        await feed.connectAsDevice('DEV3', now: DateTime.utc(2026, 9, 15, 6));
        expect(observer.isOnline('DEV3'), isFalse, reason: 'not yet delivered');
        await Future<void>.delayed(Duration.zero);
        expect(observer.isOnline('DEV3'), isTrue);

        // Nothing polls and nothing notices: the broker publishes the will.
        broker.fail();

        final event = await offline as PresenceEvent;
        expect(event.status.deviceId, 'DEV3');
        expect(observer.isOnline('DEV3'), isFalse);
        await observer.close();
      },
    );

    test('a device nobody has heard from is not online', () async {
      await feed.connectAsObserver();
      expect(feed.isOnline('DEV9'), isFalse);
    });

    test('a malformed payload is reported rather than dropped', () async {
      await feed.connectAsObserver();
      final received = feed.events.firstWhere((e) => e is MalformedEvent);

      broker.publish(heartRate.topic, 'not json at all');

      final event = await received as MalformedEvent;
      expect(event.topic, heartRate.topic);
      expect(event.payload, 'not json at all');
    });

    test(
      'a topic from outside the hospital tree is reported, not parsed',
      () async {
        await feed.connectAsObserver(readings: '#');
        final received = feed.events.firstWhere((e) => e is MalformedEvent);

        broker.inject('somebody/else/topic', '{"value":1}');

        final event = await received as MalformedEvent;
        expect(event.reason, contains('tree'));
      },
    );
  });

  group('the decoder node', () {
    FlowNode node(
      String id,
      FlowNodeType type, {
      Map<String, dynamic> config = const <String, dynamic>{},
    }) => FlowNode(id: id, type: type, label: '', x: 0, y: 0, config: config);

    IntegrationFlow flowOf(
      List<FlowNode> nodes,
      List<FlowConnection> connections,
    ) => IntegrationFlow(
      id: 'flow-mqtt-test',
      name: const LocalizedText(en: 'MQTT', fr: 'MQTT', nl: 'MQTT'),
      description: const LocalizedText(en: '', fr: '', nl: ''),
      isEnabled: true,
      nodes: nodes,
      connections: connections,
      updatedAt: DateTime(2026, 9, 15),
    );

    IntegrationMessage messageOf(Map<String, dynamic> payload) =>
        IntegrationMessage(
          id: 'msg-1',
          messageType: 'reading',
          sourceApp: 'DEV3',
          payload: payload,
          status: MessageStatus.received,
          receivedAt: DateTime(2026, 9, 15),
        );

    FlowEngine engineWith({
      List<Map<String, dynamic>>? stored,
      Patient? known,
    }) => FlowEngine(
      FlowExecutionContext(
        lookupPatient: (_) async => known,
        writeToFhirStore: (resource) async {
          stored?.add(resource);
          return '${resource['resourceType']}/1';
        },
        deliverToApplication: (_, __) async {},
        postToUrl: (_, __) async {},
      ),
    );

    test('a device payload becomes a FHIR Observation', () async {
      final stored = <Map<String, dynamic>>[];
      final result = await engineWith(stored: stored).run(
        flowOf(
          <FlowNode>[
            node('a', FlowNodeType.mqttSource),
            node(
              'b',
              FlowNodeType.deviceDecoder,
              config: const <String, dynamic>{'format': 'fhir'},
            ),
            node('c', FlowNodeType.fhirStore),
          ],
          const <FlowConnection>[
            FlowConnection(id: '1', fromNodeId: 'a', toNodeId: 'b'),
            FlowConnection(id: '2', fromNodeId: 'b', toNodeId: 'c'),
          ],
        ),
        messageOf(heartRate.toJson()),
      );

      expect(result.status, MessageStatus.delivered);
      expect(stored.single['resourceType'], 'Observation');
      expect(readPath(stored.single, 'valueQuantity.value'), 112);
    });

    test('the same reading twice produces one resource id, not two', () async {
      // At-least-once delivery makes a redelivery a certainty rather than a
      // corner case, so the id is derived from the reading instead of
      // generated.
      final stored = <Map<String, dynamic>>[];
      final flow = flowOf(
        <FlowNode>[
          node('a', FlowNodeType.mqttSource),
          node('b', FlowNodeType.deviceDecoder),
          node('c', FlowNodeType.fhirStore),
        ],
        const <FlowConnection>[
          FlowConnection(id: '1', fromNodeId: 'a', toNodeId: 'b'),
          FlowConnection(id: '2', fromNodeId: 'b', toNodeId: 'c'),
        ],
      );
      final engine = engineWith(stored: stored);

      await engine.run(flow, messageOf(heartRate.toJson()));
      await engine.run(flow, messageOf(heartRate.toJson()));

      expect(stored, hasLength(2));
      expect(stored[0]['id'], stored[1]['id']);
    });

    test(
      'the v2 format needs a patient, and says so when there is none',
      () async {
        final result = await engineWith().run(
          flowOf(
            <FlowNode>[
              node('a', FlowNodeType.mqttSource),
              node(
                'b',
                FlowNodeType.deviceDecoder,
                config: const <String, dynamic>{'format': 'hl7v2'},
              ),
              node('c', FlowNodeType.logDestination),
            ],
            const <FlowConnection>[
              FlowConnection(id: '1', fromNodeId: 'a', toNodeId: 'b'),
              FlowConnection(id: '2', fromNodeId: 'b', toNodeId: 'c'),
            ],
          ),
          messageOf(heartRate.toJson()),
        );

        expect(result.status, MessageStatus.failed);
        expect(result.error, contains('pat-002'));
      },
    );

    test('something that is not a reading fails with a reason', () async {
      final result = await engineWith().run(
        flowOf(
          <FlowNode>[
            node('a', FlowNodeType.mqttSource),
            node('b', FlowNodeType.deviceDecoder),
            node('c', FlowNodeType.logDestination),
          ],
          const <FlowConnection>[
            FlowConnection(id: '1', fromNodeId: 'a', toNodeId: 'b'),
            FlowConnection(id: '2', fromNodeId: 'b', toNodeId: 'c'),
          ],
        ),
        messageOf(<String, dynamic>{'resourceType': 'Patient'}),
      );

      expect(result.status, MessageStatus.failed);
      expect(result.error, contains('metric'));
    });

    test(
      'the seeded flow carries one reading through all three formats',
      () async {
        // MQTT payload, then ORU^R01, then FHIR. This is the chain a hospital
        // actually runs, and the flow the students open on day one.
        final stored = <Map<String, dynamic>>[];
        final flow = HospitalSeed.build(
          now: DateTime.utc(2026, 9, 15),
        ).flows.firstWhere((f) => f.id == 'flow-mqtt-vitals');

        final result = await engineWith(
          stored: stored,
          known: patient,
        ).run(flow, messageOf(heartRate.toJson()));

        expect(result.status, MessageStatus.delivered);
        expect(result.trace[1].detail, contains('ORU^R01'));
        expect(stored.single['resourceType'], 'Observation');
        expect(readPath(stored.single, 'code.coding.0.code'), '8867-4');
        expect(
          readPath(stored.single, 'subject.identifier.value'),
          'MRN000002',
        );
        expect(readPath(stored.single, 'device.identifier.value'), 'DEV3');
      },
    );
  });
}
