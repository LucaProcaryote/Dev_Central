import 'package:flutter/foundation.dart';

import '../models/clinical_note.dart';
import '../models/codes.dart';
import '../models/device.dart';
import '../models/encounter.dart';
import '../models/integration.dart';
import '../models/location.dart';
import '../models/observation.dart';
import '../models/patient.dart';
import '../models/pharmacy.dart';
import '../models/prescription.dart';

/// Everything the applications need from storage.
///
/// One interface rather than a dozen small ones: the students read this file to
/// understand what the hospital can do, and each implementation below it
/// answers the same questions from a different place - memory, the local
/// PostgreSQL API, or Firebase Data Connect.
///
/// Implementations are [ChangeNotifier]s and notify after every write, so a
/// screen listening to the repository refreshes without any manual plumbing.
abstract class HospitalRepository extends ChangeNotifier {
  /// Loads whatever the implementation needs before the first read.
  Future<void> initialize();

  /// Human-readable description of where the data is coming from, shown in the
  /// backend banner so nobody demonstrates in-memory data thinking it is live.
  String get backendDescription;

  // ---- Patients ------------------------------------------------------------

  /// All patients, optionally narrowed by a free-text [query] matched against
  /// name, MRN and national number.
  Future<List<Patient>> listPatients({String? query});

  Future<Patient?> findPatient(String id);

  /// Finds a patient by MRN, national number or id - what an inbound message
  /// might carry.
  Future<Patient?> resolvePatient(String reference);

  Future<Patient> savePatient(Patient patient);

  // ---- Locations -----------------------------------------------------------

  Future<List<Ward>> listWards();
  Future<List<Room>> listRooms({String? wardId});
  Future<List<Bed>> listBeds({String? wardId, BedStatus? status});
  Future<Bed?> findBed(String id);
  Future<Bed> saveBed(Bed bed);

  /// Bed, room and ward resolved together, ready for display.
  Future<BedPlacement?> resolvePlacement(String bedId);

  // ---- Encounters and movements -------------------------------------------

  Future<List<Encounter>> listEncounters({
    String? patientId,
    String? wardId,
    bool activeOnly = false,
  });

  Future<Encounter?> findEncounter(String id);

  /// The stay a patient is currently in, if any.
  Future<Encounter?> activeEncounterFor(String patientId);

  Future<Encounter> saveEncounter(Encounter encounter);

  Future<List<Movement>> listMovements({
    String? encounterId,
    String? patientId,
    int limit = 100,
  });

  Future<Movement> addMovement(Movement movement);

  // ---- Observations --------------------------------------------------------

  Future<List<Observation>> listObservations({
    String? patientId,
    String? encounterId,
    VitalSignType? type,
    DateTime? since,
    int limit = 500,
  });

  Future<Observation> addObservation(Observation observation);

  /// The most recent reading of each vital sign for a patient - what the
  /// patient fiche shows at the top.
  Future<Map<VitalSignType, Observation>> latestVitals(String patientId);

  // ---- Prescriptions and dispensing ---------------------------------------

  Future<List<Medication>> listFormulary({String? query});

  Future<List<Prescription>> listPrescriptions({
    String? patientId,
    String? encounterId,
    bool activeOnly = false,
  });

  Future<Prescription?> findPrescription(String id);
  Future<Prescription> savePrescription(Prescription prescription);

  Future<List<Dispense>> listDispenses({
    String? patientId,
    String? prescriptionId,
    String? cabinetId,
    DispenseStatus? status,
    int limit = 200,
  });

  Future<Dispense> saveDispense(Dispense dispense);

  // ---- Pharmacy stock ------------------------------------------------------

  Future<List<Cabinet>> listCabinets({String? wardId});
  Future<Cabinet?> findCabinet(String id);
  Future<Cabinet> saveCabinet(Cabinet cabinet);

  Future<List<StockItem>> listStock({String? cabinetId, String? query});
  Future<StockItem?> findStockItem(String id);
  Future<StockItem> saveStockItem(StockItem item);

  // ---- Devices -------------------------------------------------------------

  Future<List<MedicalDevice>> listDevices({String? wardId});
  Future<MedicalDevice?> findDeviceByCode(String code);
  Future<MedicalDevice> saveDevice(MedicalDevice device);

  // ---- Clinical notes ------------------------------------------------------

  Future<List<ClinicalNote>> listNotes({
    String? patientId,
    String? encounterId,
    NoteType? type,
  });

  Future<ClinicalNote> saveNote(ClinicalNote note);
  Future<void> deleteNote(String id);

  // ---- Integration ---------------------------------------------------------

  Future<List<IntegrationFlow>> listFlows();
  Future<IntegrationFlow?> findFlow(String id);
  Future<IntegrationFlow> saveFlow(IntegrationFlow flow);
  Future<void> deleteFlow(String id);

  Future<List<IntegrationMessage>> listMessages({
    String? flowId,
    MessageStatus? status,
    int limit = 100,
  });

  Future<IntegrationMessage> saveMessage(IntegrationMessage message);
}
