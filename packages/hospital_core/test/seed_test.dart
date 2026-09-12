import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_core/hospital_core.dart';

void main() {
  // Pin "now" so the generated history is identical on every run.
  final now = DateTime.utc(2026, 9, 12, 10);
  final seed = HospitalSeed.build(now: now);

  group('seed integrity', () {
    test('identifiers are unique within every collection', () {
      void expectUnique<T>(String label, List<T> items, String Function(T) idOf) {
        final ids = items.map(idOf).toList();
        expect(ids.toSet().length, ids.length, reason: 'duplicate id in $label');
      }

      expectUnique('patients', seed.patients, (p) => p.id);
      expectUnique('wards', seed.wards, (w) => w.id);
      expectUnique('rooms', seed.rooms, (r) => r.id);
      expectUnique('beds', seed.beds, (b) => b.id);
      expectUnique('encounters', seed.encounters, (e) => e.id);
      expectUnique('movements', seed.movements, (m) => m.id);
      expectUnique('observations', seed.observations, (o) => o.id);
      expectUnique('prescriptions', seed.prescriptions, (p) => p.id);
      expectUnique('dispenses', seed.dispenses, (d) => d.id);
      expectUnique('notes', seed.notes, (n) => n.id);
      expectUnique('stock', seed.stock, (s) => s.id);
      expectUnique('devices', seed.devices, (d) => d.id);
      expectUnique('flows', seed.flows, (f) => f.id);
    });

    test('every reference points at something that exists', () {
      final patientIds = seed.patients.map((p) => p.id).toSet();
      final bedIds = seed.beds.map((b) => b.id).toSet();
      final wardIds = seed.wards.map((w) => w.id).toSet();
      final roomIds = seed.rooms.map((r) => r.id).toSet();
      final encounterIds = seed.encounters.map((e) => e.id).toSet();
      final prescriptionIds = seed.prescriptions.map((p) => p.id).toSet();
      final cabinetIds = seed.cabinets.map((c) => c.id).toSet();

      for (final room in seed.rooms) {
        expect(wardIds, contains(room.wardId));
      }
      for (final bed in seed.beds) {
        expect(roomIds, contains(bed.roomId));
        expect(wardIds, contains(bed.wardId));
      }
      for (final encounter in seed.encounters) {
        expect(patientIds, contains(encounter.patientId));
        if (encounter.bedId != null) expect(bedIds, contains(encounter.bedId));
        if (encounter.wardId != null) expect(wardIds, contains(encounter.wardId));
      }
      for (final movement in seed.movements) {
        expect(encounterIds, contains(movement.encounterId));
        expect(patientIds, contains(movement.patientId));
      }
      for (final observation in seed.observations) {
        expect(patientIds, contains(observation.patientId));
      }
      for (final prescription in seed.prescriptions) {
        expect(patientIds, contains(prescription.patientId));
      }
      for (final dispense in seed.dispenses) {
        expect(prescriptionIds, contains(dispense.prescriptionId));
        expect(patientIds, contains(dispense.patientId));
        if (dispense.cabinetId != null) {
          expect(cabinetIds, contains(dispense.cabinetId));
        }
      }
      for (final note in seed.notes) {
        expect(patientIds, contains(note.patientId));
      }
      for (final item in seed.stock) {
        expect(cabinetIds, contains(item.cabinetId));
      }
      for (final allergy in seed.patients.expand((p) => p.allergies)) {
        expect(patientIds, contains(allergy.patientId));
      }
    });

    test('bed occupancy agrees with the active encounters', () {
      final occupiedBedIds = seed.beds
          .where((b) => b.status == BedStatus.occupied)
          .map((b) => b.id)
          .toSet();
      final activeBedIds = seed.encounters
          .where((e) => e.status.isActive && e.bedId != null)
          .map((e) => e.bedId!)
          .toSet();

      expect(occupiedBedIds, equals(activeBedIds));

      // And every occupied bed names the patient who is in it.
      for (final bed in seed.beds.where((b) => b.status == BedStatus.occupied)) {
        expect(bed.currentPatientId, isNotNull);
        expect(bed.currentEncounterId, isNotNull);
      }
      // A free bed must not claim an occupant.
      for (final bed in seed.beds.where((b) => b.status != BedStatus.occupied)) {
        expect(bed.currentPatientId, isNull);
      }
    });

    test('no two active encounters share a bed', () {
      final used = <String>{};
      for (final encounter in seed.encounters) {
        if (!encounter.status.isActive || encounter.bedId == null) continue;
        expect(used.add(encounter.bedId!), isTrue,
            reason: 'bed ${encounter.bedId} double-booked');
      }
    });

    test('a patient has at most one active encounter', () {
      final active = <String>{};
      for (final encounter in seed.encounters) {
        if (!encounter.status.isActive) continue;
        expect(active.add(encounter.patientId), isTrue,
            reason: '${encounter.patientId} admitted twice at once');
      }
    });

    test('national register numbers carry a valid check digit', () {
      // Belgian NISS: the last two digits are 97 minus the first nine modulo
      // 97, with a leading 2 prepended for births from 2000 onwards.
      for (final patient in seed.patients) {
        final raw = patient.nationalNumber!.replaceAll(RegExp(r'[.\-]'), '');
        expect(raw.length, 11, reason: '${patient.id}: ${patient.nationalNumber}');
        final body = raw.substring(0, 9);
        final check = int.parse(raw.substring(9));
        final born2000OrLater = patient.birthDate.year >= 2000;
        final base = int.parse(born2000OrLater ? '2$body' : body);
        expect(97 - (base % 97), check,
            reason: '${patient.id} has an invalid NISS check digit');
      }
    });

    test('generated vitals stay physiologically plausible', () {
      for (final observation in seed.observations) {
        final value = observation.value;
        switch (observation.type) {
          case VitalSignType.oxygenSaturation:
            expect(value, inInclusiveRange(70, 100));
          case VitalSignType.bodyTemperature:
            expect(value, inInclusiveRange(34, 42));
          case VitalSignType.heartRate:
            expect(value, inInclusiveRange(35, 200));
          case VitalSignType.bodyWeight:
            expect(value, inInclusiveRange(2, 250));
          case VitalSignType.respiratoryRate:
            expect(value, inInclusiveRange(6, 45));
          case VitalSignType.activitySteps:
            expect(value, inInclusiveRange(0, 30000));
          default:
            expect(value, inInclusiveRange(30, 260));
        }
      }
    });

    test('the clinical story in the notes matches the measurements', () {
      List<Observation> seriesFor(String patientId, VitalSignType type) =>
          seed.observations
              .where((o) => o.patientId == patientId && o.type == type)
              .toList()
            ..sort((a, b) => a.effectiveDateTime.compareTo(b.effectiveDateTime));

      // pat-002 was admitted 52 hours ago with a fever of 39.2, so the whole
      // stay is inside the 72-hour display window: the curve should start
      // febrile and come down on antibiotics.
      final pneumonia = seriesFor('pat-002', VitalSignType.bodyTemperature);
      expect(pneumonia.length, greaterThan(5));
      expect(pneumonia.first.value, greaterThan(38.5),
          reason: 'the pneumonia should start febrile');
      expect(pneumonia.last.value, lessThan(38.0),
          reason: 'the fever should be settling by day three');

      // pat-008 has been in for six days, so only the last three are plotted.
      // The visible window should still be a clear downward trend, ending
      // afebrile, which is what the intensive-care note describes.
      final sepsis = seriesFor('pat-008', VitalSignType.bodyTemperature);
      expect(sepsis.length, greaterThan(5));
      expect(sepsis.last.value, lessThan(sepsis.first.value),
          reason: 'the sepsis should be resolving across the window');
      expect(sepsis.last.value, lessThan(37.5),
          reason: 'the patient should be afebrile by day six');

      // pat-015 came in with rapid atrial fibrillation and is being rate
      // controlled: the heart rate must be visibly falling.
      final af = seriesFor('pat-015', VitalSignType.heartRate);
      expect(af.first.value, greaterThan(120),
          reason: 'atrial fibrillation should start fast');
      expect(af.last.value, lessThan(af.first.value - 20),
          reason: 'rate control should be working');

      // pat-013 is in rehabilitation: the step count is the outcome measure.
      final steps = seriesFor('pat-013', VitalSignType.activitySteps);
      expect(steps.last.value, greaterThan(steps.first.value),
          reason: 'rehabilitation should show increasing activity');
    });

    test('the dataset is reproducible for a fixed clock', () {
      final again = HospitalSeed.build(now: now);
      expect(again.observations.length, seed.observations.length);
      expect(
        again.observations.first.value,
        seed.observations.first.value,
      );
      expect(again.dispenses.length, seed.dispenses.length);
    });

    test('the pharmacy has something for the students to notice', () {
      expect(seed.stock.where((s) => s.isEmpty), isNotEmpty,
          reason: 'at least one empty slot');
      expect(seed.stock.where((s) => s.isExpired), isNotEmpty,
          reason: 'at least one expired lot');
      expect(seed.stock.where((s) => s.isLow && !s.isEmpty), isNotEmpty,
          reason: 'at least one slot at or below par');
      expect(seed.dispenses.where((d) => d.status == DispenseStatus.requested),
          isNotEmpty,
          reason: 'the dispensing queue should not open empty');
    });

    test('controlled substances are only stocked where they are used', () {
      for (final item in seed.stock.where((s) => s.medication.isControlled)) {
        expect(
          <String>['cab-icu', 'cab-surg', 'cab-emer'],
          contains(item.cabinetId),
        );
      }
    });
  });

  group('trilingual coverage', () {
    test('every ward, drug and allergy is written in all three languages', () {
      void expectTrilingual(String label, LocalizedText text) {
        expect(text.en.trim(), isNotEmpty, reason: '$label has no English');
        expect(text.fr.trim(), isNotEmpty, reason: '$label has no French');
        expect(text.nl.trim(), isNotEmpty, reason: '$label has no Dutch');
      }

      for (final ward in seed.wards) {
        expectTrilingual('ward ${ward.code} name', ward.name);
        expectTrilingual('ward ${ward.code} specialty', ward.specialty);
      }
      for (final medication in seed.formulary) {
        expectTrilingual('drug ${medication.code} name', medication.name);
        expectTrilingual('drug ${medication.code} form', medication.form);
      }
      for (final allergy in seed.patients.expand((p) => p.allergies)) {
        expectTrilingual('allergy ${allergy.id} substance', allergy.substance);
        expectTrilingual('allergy ${allergy.id} reaction', allergy.reaction);
      }
      for (final flow in seed.flows) {
        expectTrilingual('flow ${flow.id} name', flow.name);
        expectTrilingual('flow ${flow.id} description', flow.description);
      }
    });

    test('patients are spread across the language communities', () {
      final languages = seed.patients.map((p) => p.preferredLanguage).toSet();
      expect(languages, containsAll(<String>['fr', 'nl']));
    });
  });
}
