import 'package:device_simulator/src/services/signal_generator.dart';
import 'package:device_simulator/src/services/simulator_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_core/hospital_core.dart';

void main() {
  final now = DateTime.utc(2026, 9, 12, 10);

  group('signal generator', () {
    test('stays inside physiological limits however long it runs', () {
      for (final scenario in SimulationScenario.values) {
        final generator = SignalGenerator(scenario: scenario, seed: 42);
        for (var i = 0; i < 2000; i++) {
          for (final type in VitalSignType.values) {
            final value = generator.next(type, const Duration(seconds: 30));
            switch (type) {
              case VitalSignType.oxygenSaturation:
                expect(value, inInclusiveRange(60, 100));
              case VitalSignType.bodyTemperature:
                expect(value, inInclusiveRange(33, 42.5));
              case VitalSignType.heartRate:
                expect(value, inInclusiveRange(28, 220));
              case VitalSignType.respiratoryRate:
                expect(value, inInclusiveRange(4, 50));
              case VitalSignType.activitySteps:
                expect(value, inInclusiveRange(0, 40000));
              case VitalSignType.bodyWeight:
                expect(value, inInclusiveRange(2, 300));
              default:
                expect(value, inInclusiveRange(30, 260));
            }
          }
        }
      }
    });

    test('the trace is continuous, not a fresh random draw each time', () {
      final generator = SignalGenerator(
        scenario: SimulationScenario.stable,
        seed: 7,
      );
      var previous = generator.next(VitalSignType.heartRate, const Duration(seconds: 5));
      for (var i = 0; i < 200; i++) {
        final value =
            generator.next(VitalSignType.heartRate, const Duration(seconds: 5));
        // A stable patient's heart rate must not jump twenty beats between
        // consecutive five-second samples.
        expect((value - previous).abs(), lessThan(10));
        previous = value;
      }
    });

    test('deterioration moves every measurement the clinical way', () {
      final generator = SignalGenerator(
        scenario: SimulationScenario.deteriorating,
        seed: 3,
      );
      final startSpo2 = generator.current[VitalSignType.oxygenSaturation]!;
      final startHr = generator.current[VitalSignType.heartRate]!;

      // Twenty simulated minutes.
      for (var i = 0; i < 40; i++) {
        generator.next(VitalSignType.oxygenSaturation, const Duration(seconds: 30));
        generator.next(VitalSignType.heartRate, const Duration(seconds: 30));
      }

      // Saturation down, heart rate up - they must move together, in the
      // directions a deteriorating patient actually goes.
      expect(generator.current[VitalSignType.oxygenSaturation]!,
          lessThan(startSpo2 - 5));
      expect(generator.current[VitalSignType.heartRate]!,
          greaterThan(startHr + 10));
    });

    test('recovery moves them back', () {
      final generator = SignalGenerator(
        scenario: SimulationScenario.recovering,
        initial: <VitalSignType, double>{
          VitalSignType.oxygenSaturation: 88,
          VitalSignType.heartRate: 120,
        },
        seed: 11,
      );
      for (var i = 0; i < 40; i++) {
        generator.next(VitalSignType.oxygenSaturation, const Duration(seconds: 30));
        generator.next(VitalSignType.heartRate, const Duration(seconds: 30));
      }
      expect(generator.current[VitalSignType.oxygenSaturation]!, greaterThan(88));
      expect(generator.current[VitalSignType.heartRate]!, lessThan(120));
    });

    test('the artefact scenario is noisier than the stable one', () {
      double spread(SimulationScenario scenario) {
        final generator = SignalGenerator(scenario: scenario, seed: 5);
        var min = double.infinity;
        var max = double.negativeInfinity;
        for (var i = 0; i < 300; i++) {
          final value =
              generator.next(VitalSignType.heartRate, const Duration(seconds: 2));
          min = value < min ? value : min;
          max = value > max ? value : max;
        }
        return max - min;
      }

      expect(spread(SimulationScenario.artefact),
          greaterThan(spread(SimulationScenario.stable)));
    });

    test('a device only emits the measurements it can take', () {
      final generator = SignalGenerator(scenario: SimulationScenario.stable, seed: 1);
      const device = MedicalDevice(
        id: 'd',
        code: 'DEV3',
        kind: DeviceKind.pulseOximeter,
        manufacturer: 'x',
        model: 'y',
        serialNumber: 'z',
        status: DeviceStatus.active,
      );
      var counter = 0;
      final readings = generator.sample(
        device: device,
        patientId: 'pat-001',
        since: const Duration(seconds: 5),
        at: now,
        nextId: () => 'obs-${counter++}',
      );

      expect(
        readings.map((o) => o.type).toSet(),
        DeviceKind.pulseOximeter.measures.toSet(),
      );
      // Every reading is attributed to the device that produced it.
      expect(readings.every((o) => o.deviceId == 'DEV3'), isTrue);
      expect(readings.every((o) => o.patientId == 'pat-001'), isTrue);
    });
  });

  group('simulator controller', () {
    late MemoryHospitalRepository repository;
    late SimulatorController controller;

    setUp(() async {
      repository = MemoryHospitalRepository(seed: HospitalSeed.build(now: now));
      await repository.initialize();
      controller = SimulatorController(
        repository: repository,
        // No engine: the simulator must still work on its own.
        publisher: null,
        deviceCode: 'DEV3',
      );
      await controller.load();
    });

    tearDown(() => controller.dispose());

    test('loads its device and the patient it is attached to', () {
      expect(controller.device, isNotNull);
      expect(controller.device!.code, 'DEV3');
      // DEV3 is the pulse oximeter on Marie-Claire Dupont in the seed data.
      expect(controller.patient?.id, 'pat-002');
    });

    test('a manual reading is stored and attributed to the device', () async {
      final before = await repository.listObservations(
        patientId: 'pat-002',
        type: VitalSignType.oxygenSaturation,
      );

      final entry =
          await controller.sendManual(VitalSignType.oxygenSaturation, 86);

      expect(entry, isNotNull);
      expect(entry!.observation.value, 86);
      expect(entry.observation.deviceId, 'DEV3');
      // No engine configured, so it cannot have been delivered - and the
      // controller must say so rather than pretend.
      expect(entry.delivered, isFalse);
      expect(controller.failedCount, 1);

      final after = await repository.listObservations(
        patientId: 'pat-002',
        type: VitalSignType.oxygenSaturation,
      );
      expect(after.length, before.length + 1);
      // It is stored locally regardless, so the simulator is useful alone.
      expect(after.first.value, 86);
      expect(after.first.isAbnormal, isTrue);
    });

    test('reassigning the patient follows them to their bed', () async {
      final target = (await repository.findPatient('pat-001'))!;
      await controller.assignPatient(target);

      expect(controller.patient?.id, 'pat-001');
      final encounter = await repository.activeEncounterFor('pat-001');
      expect(controller.device!.assignedPatientId, 'pat-001');
      expect(controller.device!.assignedBedId, encounter!.bedId);
      expect(controller.device!.wardId, encounter.wardId);
    });

    test('unassigning clears the device', () async {
      await controller.assignPatient(null);
      expect(controller.patient, isNull);
      expect(controller.device!.assignedPatientId, isNull);
    });

    test('an Apple Watch export lands as ordinary observations', () async {
      final count = await controller.ingest(
        <({VitalSignType type, double value, DateTime at})>[
          (type: VitalSignType.heartRate, value: 68, at: now),
          (
            type: VitalSignType.activitySteps,
            value: 4210,
            at: now.subtract(const Duration(hours: 1)),
          ),
        ],
      );

      expect(count, 2);
      final stored = await repository.listObservations(patientId: 'pat-002');
      final watch = stored.where((o) => o.deviceId == 'APPLE-WATCH');
      expect(watch, hasLength(2));
      // Indistinguishable downstream from a simulated reading, which is the
      // whole point: a consumer wearable is just another device on the feed.
      expect(watch.first.toFhir()['resourceType'], 'Observation');
    });

    test('the outbox is capped so a long run does not grow without bound',
        () async {
      for (var i = 0; i < 260; i++) {
        await controller.sendManual(VitalSignType.heartRate, 70 + (i % 20));
      }
      expect(controller.outbox.length, lessThanOrEqualTo(200));
      // Newest first.
      expect(
        controller.outbox.first.observation.effectiveDateTime
            .isAfter(controller.outbox.last.observation.effectiveDateTime),
        isTrue,
      );
    });

    test('changing the interval takes effect without restarting', () {
      controller.setInterval(const Duration(seconds: 20));
      expect(controller.interval, const Duration(seconds: 20));
      expect(controller.isRunning, isFalse);
    });
  });
}
