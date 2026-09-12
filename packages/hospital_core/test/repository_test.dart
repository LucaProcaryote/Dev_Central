import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_core/hospital_core.dart';

void main() {
  late MemoryHospitalRepository repository;

  setUp(() async {
    repository = MemoryHospitalRepository(
      seed: HospitalSeed.build(now: DateTime.utc(2026, 9, 12, 10)),
    );
    await repository.initialize();
  });

  group('reads', () {
    test('patient search matches name, MRN and national number', () async {
      final byFamily = await repository.listPatients(query: 'van damme');
      expect(byFamily.map((p) => p.id), contains('pat-001'));

      final byGiven = await repository.listPatients(query: 'sophie');
      expect(byGiven.map((p) => p.id), contains('pat-005'));

      final byMrn = await repository.listPatients(query: 'MRN000003');
      expect(byMrn.single.id, 'pat-003');

      final all = await repository.listPatients();
      expect(all, hasLength(20));
      // The default order is by family name, which is how ward lists read.
      final families = all.map((p) => p.familyName).toList();
      final sorted = List<String>.of(families)..sort();
      expect(families, sorted);
    });

    test('resolvePatient accepts an id, an MRN or a national number', () async {
      final patient = (await repository.findPatient('pat-007'))!;
      expect((await repository.resolvePatient('pat-007'))?.id, 'pat-007');
      expect((await repository.resolvePatient(patient.mrn))?.id, 'pat-007');
      expect(
        (await repository.resolvePatient(patient.nationalNumber!))?.id,
        'pat-007',
      );
      expect(await repository.resolvePatient('nobody'), isNull);
      expect(await repository.resolvePatient(''), isNull);
    });

    test('active encounters exclude discharged stays', () async {
      final active = await repository.listEncounters(activeOnly: true);
      expect(active, isNotEmpty);
      expect(active.every((e) => e.status.isActive), isTrue);

      final all = await repository.listEncounters();
      expect(all.length, greaterThan(active.length));
    });

    test('latestVitals returns one reading per measurement', () async {
      final vitals = await repository.latestVitals('pat-008');
      expect(vitals, isNotEmpty);

      for (final entry in vitals.entries) {
        final all = await repository.listObservations(
          patientId: 'pat-008',
          type: entry.key,
        );
        final newest = all
            .map((o) => o.effectiveDateTime)
            .reduce((a, b) => a.isAfter(b) ? a : b);
        expect(entry.value.effectiveDateTime, newest);
      }
    });

    test('observations can be filtered by type and time', () async {
      final since = DateTime.utc(2026, 9, 12, 10).subtract(const Duration(hours: 12));
      final recent = await repository.listObservations(
        patientId: 'pat-008',
        type: VitalSignType.heartRate,
        since: since,
      );
      expect(recent, isNotEmpty);
      expect(recent.every((o) => o.type == VitalSignType.heartRate), isTrue);
      expect(recent.every((o) => o.effectiveDateTime.isAfter(since)), isTrue);
    });

    test('resolvePlacement gives bed, room and ward together', () async {
      final encounter = (await repository.listEncounters(activeOnly: true))
          .firstWhere((e) => e.bedId != null);
      final placement = (await repository.resolvePlacement(encounter.bedId!))!;

      expect(placement.bed.id, encounter.bedId);
      expect(placement.room.id, placement.bed.roomId);
      expect(placement.ward.id, placement.bed.wardId);
      expect(placement.describe('fr'), contains(placement.bed.label));
    });

    test('the formulary is searchable in all three languages', () async {
      expect(
        (await repository.listFormulary(query: 'paracetamol')).map((m) => m.code),
        contains('MED-0101'),
      );
      // French spelling of ibuprofen.
      expect(
        (await repository.listFormulary(query: 'ibuprofène')).map((m) => m.code),
        contains('MED-0102'),
      );
      // Dutch spelling of ceftriaxone.
      expect(
        (await repository.listFormulary(query: 'ceftriaxon')).map((m) => m.code),
        contains('MED-0116'),
      );
      // ATC code lookup.
      expect(
        (await repository.listFormulary(query: 'N02BE01')).map((m) => m.code),
        contains('MED-0101'),
      );
    });
  });

  group('writes', () {
    test('saving a patient replaces rather than duplicates', () async {
      final before = await repository.listPatients();
      final patient = before.first;

      await repository.savePatient(patient.copyWith(phone: '+32 2 000 00 00'));

      final after = await repository.listPatients();
      expect(after.length, before.length);
      expect((await repository.findPatient(patient.id))!.phone,
          '+32 2 000 00 00');
    });

    test('saving a new record appends it', () async {
      final before = await repository.listNotes(patientId: 'pat-001');
      await repository.saveNote(ClinicalNote(
        id: 'note-new',
        patientId: 'pat-001',
        type: NoteType.progress,
        title: 'Test',
        body: 'Body',
        authorName: 'Tester',
        authorRole: 'Student',
        createdAt: DateTime.utc(2026, 9, 12, 11),
      ));
      final after = await repository.listNotes(patientId: 'pat-001');
      expect(after.length, before.length + 1);
      // Newest first.
      expect(after.first.id, 'note-new');
    });

    test('deleting a note removes it', () async {
      final notes = await repository.listNotes(patientId: 'pat-001');
      await repository.deleteNote(notes.first.id);
      final after = await repository.listNotes(patientId: 'pat-001');
      expect(after.map((n) => n.id), isNot(contains(notes.first.id)));
    });

    test('writes notify listeners so screens refresh', () async {
      var notifications = 0;
      repository.addListener(() => notifications++);

      await repository.saveBed(
        (await repository.listBeds()).first.copyWith(status: BedStatus.cleaning),
      );
      expect(notifications, 1);

      await repository.addObservation(Observation(
        id: 'obs-new',
        patientId: 'pat-001',
        type: VitalSignType.heartRate,
        value: 72,
        effectiveDateTime: DateTime.utc(2026, 9, 12, 11),
      ));
      expect(notifications, 2);
    });

    test('a full admission updates the encounter and the bed together',
        () async {
      // pat-007 is deliberately left unadmitted in the seed data.
      expect(await repository.activeEncounterFor('pat-007'), isNull);

      final freeBed = (await repository.listBeds(
        wardId: 'ward-int',
        status: BedStatus.free,
      )).first;

      final encounter = Encounter(
        id: 'enc-new',
        patientId: 'pat-007',
        status: EncounterStatus.inProgress,
        encounterClass: EncounterClass.inpatient,
        admissionDate: DateTime.utc(2026, 9, 12, 11),
        wardId: freeBed.wardId,
        roomId: freeBed.roomId,
        bedId: freeBed.id,
        reason: 'Test admission',
      );
      await repository.saveEncounter(encounter);
      await repository.saveBed(freeBed.copyWith(
        status: BedStatus.occupied,
        currentEncounterId: encounter.id,
        currentPatientId: 'pat-007',
      ));
      await repository.addMovement(Movement(
        id: 'mv-new',
        encounterId: encounter.id,
        patientId: 'pat-007',
        type: MovementType.admission,
        occurredAt: DateTime.utc(2026, 9, 12, 11),
        performedBy: 'Tester',
        toWardId: freeBed.wardId,
        toBedId: freeBed.id,
      ));

      expect((await repository.activeEncounterFor('pat-007'))?.id, 'enc-new');
      expect((await repository.findBed(freeBed.id))!.status, BedStatus.occupied);
      expect(
        (await repository.listMovements(patientId: 'pat-007')).single.type,
        MovementType.admission,
      );
    });
  });
}
