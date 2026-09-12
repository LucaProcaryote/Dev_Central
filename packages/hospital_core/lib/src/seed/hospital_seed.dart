import '../models/clinical_note.dart';
import '../models/codes.dart';
import '../models/device.dart';
import '../models/encounter.dart';
import '../models/hospital_user.dart';
import '../models/integration.dart';
import '../models/location.dart';
import '../models/observation.dart';
import '../models/patient.dart';
import '../models/pharmacy.dart';
import '../models/prescription.dart';
import 'seed_clinical.dart';
import 'seed_devices.dart';
import 'seed_flows.dart';
import 'seed_formulary.dart';
import 'seed_locations.dart';
import 'seed_observations.dart';
import 'seed_patients.dart';
import 'seed_pharmacy.dart';
import 'seed_users.dart';

/// A complete, internally consistent snapshot of the mini-hospital.
///
/// Every application builds one of these at start-up in memory mode, and the
/// SQL seed script is generated from the same source, so the classroom sees the
/// same hospital whichever backend it is pointed at.
class HospitalSeed {
  const HospitalSeed({
    required this.generatedAt,
    required this.patients,
    required this.wards,
    required this.rooms,
    required this.beds,
    required this.encounters,
    required this.movements,
    required this.observations,
    required this.prescriptions,
    required this.dispenses,
    required this.notes,
    required this.formulary,
    required this.cabinets,
    required this.stock,
    required this.devices,
    required this.flows,
    required this.users,
  });

  final DateTime generatedAt;
  final List<Patient> patients;
  final List<Ward> wards;
  final List<Room> rooms;
  final List<Bed> beds;
  final List<Encounter> encounters;
  final List<Movement> movements;
  final List<Observation> observations;
  final List<Prescription> prescriptions;
  final List<Dispense> dispenses;
  final List<ClinicalNote> notes;
  final List<Medication> formulary;
  final List<Cabinet> cabinets;
  final List<StockItem> stock;
  final List<MedicalDevice> devices;
  final List<IntegrationFlow> flows;
  final List<HospitalUser> users;

  /// Builds the snapshot. Pass [now] in tests to make the output reproducible;
  /// production callers let it default so the data always looks current.
  factory HospitalSeed.build({DateTime? now}) {
    final reference = now ?? DateTime.now();
    final rooms = buildSeedRooms();
    final beds = buildSeedBeds(rooms);
    final clinical = buildSeedEncounters(reference);

    final encounterIdByPatient = <String, String>{
      for (final encounter in clinical.encounters)
        if (encounter.status.isActive) encounter.patientId: encounter.id,
    };

    // Mark the beds that the active encounters are sitting in. Doing it here
    // rather than hard-coding a status on each bed keeps the two in step: if a
    // stay is added or removed above, the bed board follows automatically.
    final occupancy = <String, Encounter>{
      for (final encounter in clinical.encounters)
        if (encounter.status.isActive && encounter.bedId != null)
          encounter.bedId!: encounter,
    };

    final resolvedBeds = <Bed>[];
    for (final bed in beds) {
      final encounter = occupancy[bed.id];
      if (encounter != null) {
        resolvedBeds.add(
          bed.copyWith(
            status: BedStatus.occupied,
            currentEncounterId: encounter.id,
            currentPatientId: encounter.patientId,
          ),
        );
      } else if (bed.id.hashCode % 29 == 0) {
        // A few beds are being turned over, so the bed board is not a wall of
        // green and the transfer screen has to skip them.
        resolvedBeds.add(bed.copyWith(status: BedStatus.cleaning));
      } else if (bed.id.hashCode % 53 == 0) {
        resolvedBeds.add(bed.copyWith(status: BedStatus.blocked));
      } else {
        resolvedBeds.add(bed);
      }
    }

    final prescriptions = buildSeedPrescriptions(
      reference,
      encounterIdByPatient,
    );

    return HospitalSeed(
      generatedAt: reference,
      patients: seedPatients,
      wards: seedWards,
      rooms: rooms,
      beds: resolvedBeds,
      encounters: clinical.encounters,
      movements: clinical.movements,
      observations: buildSeedObservations(reference, clinical.encounters),
      prescriptions: prescriptions,
      dispenses: _buildDispenses(reference, prescriptions),
      notes: buildSeedNotes(reference, encounterIdByPatient),
      formulary: seedFormulary,
      cabinets: seedCabinets,
      stock: buildSeedStock(reference),
      devices: buildSeedDevices(reference),
      flows: buildSeedFlows(reference),
      users: seedUsers,
    );
  }

  Patient? patientById(String id) {
    for (final patient in patients) {
      if (patient.id == id) return patient;
    }
    return null;
  }

  Ward? wardById(String id) {
    for (final ward in wards) {
      if (ward.id == id) return ward;
    }
    return null;
  }
}

/// Builds the dispensing history for the scheduled prescriptions.
///
/// Only doses that were actually due before now are marked as handed over, and
/// the most recent round is left as `requested` so the pharmacy screen opens
/// with real work waiting in the queue rather than an empty list.
List<Dispense> _buildDispenses(DateTime now, List<Prescription> prescriptions) {
  final dispenses = <Dispense>[];
  var counter = 0;

  const cabinetByWardPrefix = <String, String>{
    'pat-001': 'cab-card',
    'pat-002': 'cab-int',
    'pat-003': 'cab-surg',
    'pat-008': 'cab-icu',
    'pat-010': 'cab-ped',
    'pat-013': 'cab-geri',
    'pat-015': 'cab-card',
    'pat-016': 'cab-ped',
    'pat-018': 'cab-int',
    'pat-020': 'cab-card',
  };

  for (final prescription in prescriptions) {
    if (prescription.status != PrescriptionStatus.active) continue;
    if (prescription.isPrn) continue;

    final cabinetId = cabinetByWardPrefix[prescription.patientId];
    if (cabinetId == null) continue;

    final intervalHours = (24 / prescription.frequencyPerDay).round();
    final hoursActive = now.difference(prescription.startDate).inHours;
    // Cap the history at three days so the queue stays readable.
    final maxDoses = (hoursActive ~/ intervalHours).clamp(0, 18);

    for (var dose = 0; dose < maxDoses; dose++) {
      final dueAt = prescription.startDate.add(
        Duration(hours: intervalHours * dose),
      );
      if (dueAt.isAfter(now)) break;
      counter++;

      // The most recent dose of each prescription is still waiting to be given.
      final isLatest = dose == maxDoses - 1;
      dispenses.add(
        Dispense(
          id: 'disp-${counter.toString().padLeft(5, '0')}',
          prescriptionId: prescription.id,
          patientId: prescription.patientId,
          quantity: prescription.doseQuantity,
          status: isLatest
              ? DispenseStatus.requested
              : DispenseStatus.dispensed,
          requestedAt: dueAt,
          dispensedAt: isLatest ? null : dueAt.add(const Duration(minutes: 12)),
          dispensedBy: isLatest ? null : 'Marie Lambert',
          cabinetId: cabinetId,
          slot: null,
          lotNumber: isLatest ? null : 'LOT${240000 + (counter * 13) % 5000}',
        ),
      );
    }
  }

  dispenses.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
  return dispenses;
}
