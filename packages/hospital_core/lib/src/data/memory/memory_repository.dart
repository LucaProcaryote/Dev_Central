import '../../models/clinical_note.dart';
import '../../models/codes.dart';
import '../../models/device.dart';
import '../../models/encounter.dart';
import '../../models/integration.dart';
import '../../models/location.dart';
import '../../models/observation.dart';
import '../../models/patient.dart';
import '../../models/pharmacy.dart';
import '../../models/prescription.dart';
import '../../seed/hospital_seed.dart';
import '../hospital_repository.dart';

/// The whole hospital in RAM, seeded with the fictive dataset.
///
/// This is the default. It means a student can clone a repository, run
/// `flutter run -d chrome` and have a working hospital in front of them before
/// anyone has explained Docker or PostgreSQL - and the lecturer can demonstrate
/// any screen without infrastructure. Writes are lost when the tab closes,
/// which the backend banner says plainly.
class MemoryHospitalRepository extends HospitalRepository {
  MemoryHospitalRepository({HospitalSeed? seed})
    : _seed = seed ?? HospitalSeed.build();

  final HospitalSeed _seed;

  late final List<Patient> _patients;
  late final List<Ward> _wards;
  late final List<Room> _rooms;
  late final List<Bed> _beds;
  late final List<Encounter> _encounters;
  late final List<Movement> _movements;
  late final List<Observation> _observations;
  late final List<Prescription> _prescriptions;
  late final List<Dispense> _dispenses;
  late final List<ClinicalNote> _notes;
  late final List<Medication> _formulary;
  late final List<Cabinet> _cabinets;
  late final List<StockItem> _stock;
  late final List<MedicalDevice> _devices;
  late final List<IntegrationFlow> _flows;
  late final List<IntegrationMessage> _messages;

  var _initialized = false;

  @override
  String get backendDescription => 'memory';

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _patients = List<Patient>.of(_seed.patients);
    _wards = List<Ward>.of(_seed.wards);
    _rooms = List<Room>.of(_seed.rooms);
    _beds = List<Bed>.of(_seed.beds);
    _encounters = List<Encounter>.of(_seed.encounters);
    _movements = List<Movement>.of(_seed.movements);
    _observations = List<Observation>.of(_seed.observations);
    _prescriptions = List<Prescription>.of(_seed.prescriptions);
    _dispenses = List<Dispense>.of(_seed.dispenses);
    _notes = List<ClinicalNote>.of(_seed.notes);
    _formulary = List<Medication>.of(_seed.formulary);
    _cabinets = List<Cabinet>.of(_seed.cabinets);
    _stock = List<StockItem>.of(_seed.stock);
    _devices = List<MedicalDevice>.of(_seed.devices);
    _flows = List<IntegrationFlow>.of(_seed.flows);
    _messages = <IntegrationMessage>[];
    _initialized = true;
    notifyListeners();
  }

  /// Replaces the element with the same id, or appends it if it is new.
  T _upsert<T>(List<T> list, T value, String Function(T) idOf) {
    final id = idOf(value);
    final index = list.indexWhere((element) => idOf(element) == id);
    if (index >= 0) {
      list[index] = value;
    } else {
      list.add(value);
    }
    notifyListeners();
    return value;
  }

  // ---- Patients ------------------------------------------------------------

  @override
  Future<List<Patient>> listPatients({String? query}) async {
    final sorted = List<Patient>.of(_patients)
      ..sort((a, b) => a.familyName.compareTo(b.familyName));
    if (query == null || query.trim().isEmpty) return sorted;
    final needle = query.trim().toLowerCase();
    return sorted
        .where(
          (p) =>
              p.familyName.toLowerCase().contains(needle) ||
              p.givenName.toLowerCase().contains(needle) ||
              p.mrn.toLowerCase().contains(needle) ||
              (p.nationalNumber ?? '').toLowerCase().contains(needle),
        )
        .toList();
  }

  @override
  Future<Patient?> findPatient(String id) async {
    for (final patient in _patients) {
      if (patient.id == id) return patient;
    }
    return null;
  }

  @override
  Future<Patient?> resolvePatient(String reference) async {
    final needle = reference.trim().toLowerCase();
    if (needle.isEmpty) return null;
    for (final patient in _patients) {
      if (patient.id.toLowerCase() == needle ||
          patient.mrn.toLowerCase() == needle ||
          (patient.nationalNumber ?? '').toLowerCase() == needle) {
        return patient;
      }
    }
    return null;
  }

  @override
  Future<Patient> savePatient(Patient patient) async =>
      _upsert<Patient>(_patients, patient, (p) => p.id);

  // ---- Locations -----------------------------------------------------------

  @override
  Future<List<Ward>> listWards() async => List<Ward>.unmodifiable(_wards);

  @override
  Future<List<Room>> listRooms({String? wardId}) async => _rooms
      .where((room) => wardId == null || room.wardId == wardId)
      .toList(growable: false);

  @override
  Future<List<Bed>> listBeds({String? wardId, BedStatus? status}) async => _beds
      .where(
        (bed) =>
            (wardId == null || bed.wardId == wardId) &&
            (status == null || bed.status == status),
      )
      .toList(growable: false);

  @override
  Future<Bed?> findBed(String id) async {
    for (final bed in _beds) {
      if (bed.id == id) return bed;
    }
    return null;
  }

  @override
  Future<Bed> saveBed(Bed bed) async => _upsert<Bed>(_beds, bed, (b) => b.id);

  @override
  Future<BedPlacement?> resolvePlacement(String bedId) async {
    final bed = await findBed(bedId);
    if (bed == null) return null;
    Room? room;
    for (final candidate in _rooms) {
      if (candidate.id == bed.roomId) {
        room = candidate;
        break;
      }
    }
    Ward? ward;
    for (final candidate in _wards) {
      if (candidate.id == bed.wardId) {
        ward = candidate;
        break;
      }
    }
    if (room == null || ward == null) return null;
    return BedPlacement(bed: bed, room: room, ward: ward);
  }

  // ---- Encounters ----------------------------------------------------------

  @override
  Future<List<Encounter>> listEncounters({
    String? patientId,
    String? wardId,
    bool activeOnly = false,
  }) async {
    final result = _encounters
        .where(
          (e) =>
              (patientId == null || e.patientId == patientId) &&
              (wardId == null || e.wardId == wardId) &&
              (!activeOnly || e.status.isActive),
        )
        .toList();
    result.sort((a, b) => b.admissionDate.compareTo(a.admissionDate));
    return result;
  }

  @override
  Future<Encounter?> findEncounter(String id) async {
    for (final encounter in _encounters) {
      if (encounter.id == id) return encounter;
    }
    return null;
  }

  @override
  Future<Encounter?> activeEncounterFor(String patientId) async {
    for (final encounter in _encounters) {
      if (encounter.patientId == patientId && encounter.status.isActive) {
        return encounter;
      }
    }
    return null;
  }

  @override
  Future<Encounter> saveEncounter(Encounter encounter) async =>
      _upsert<Encounter>(_encounters, encounter, (e) => e.id);

  @override
  Future<List<Movement>> listMovements({
    String? encounterId,
    String? patientId,
    int limit = 100,
  }) async {
    final result = _movements
        .where(
          (m) =>
              (encounterId == null || m.encounterId == encounterId) &&
              (patientId == null || m.patientId == patientId),
        )
        .toList();
    result.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return result.take(limit).toList(growable: false);
  }

  @override
  Future<Movement> addMovement(Movement movement) async =>
      _upsert<Movement>(_movements, movement, (m) => m.id);

  // ---- Observations --------------------------------------------------------

  @override
  Future<List<Observation>> listObservations({
    String? patientId,
    String? encounterId,
    VitalSignType? type,
    DateTime? since,
    int limit = 500,
  }) async {
    final result = _observations
        .where(
          (o) =>
              (patientId == null || o.patientId == patientId) &&
              (encounterId == null || o.encounterId == encounterId) &&
              (type == null || o.type == type) &&
              (since == null || o.effectiveDateTime.isAfter(since)),
        )
        .toList();
    result.sort((a, b) => b.effectiveDateTime.compareTo(a.effectiveDateTime));
    return result.take(limit).toList(growable: false);
  }

  @override
  Future<Observation> addObservation(Observation observation) async =>
      _upsert<Observation>(_observations, observation, (o) => o.id);

  @override
  Future<Map<VitalSignType, Observation>> latestVitals(String patientId) async {
    final latest = <VitalSignType, Observation>{};
    for (final observation in _observations) {
      if (observation.patientId != patientId) continue;
      final existing = latest[observation.type];
      if (existing == null ||
          observation.effectiveDateTime.isAfter(existing.effectiveDateTime)) {
        latest[observation.type] = observation;
      }
    }
    return latest;
  }

  // ---- Prescriptions -------------------------------------------------------

  @override
  Future<List<Medication>> listFormulary({String? query}) async {
    if (query == null || query.trim().isEmpty) {
      return List<Medication>.unmodifiable(_formulary);
    }
    final needle = query.trim().toLowerCase();
    return _formulary
        .where(
          (m) =>
              m.name.en.toLowerCase().contains(needle) ||
              m.name.fr.toLowerCase().contains(needle) ||
              m.name.nl.toLowerCase().contains(needle) ||
              m.code.toLowerCase().contains(needle) ||
              m.atcCode.toLowerCase().contains(needle),
        )
        .toList(growable: false);
  }

  @override
  Future<List<Prescription>> listPrescriptions({
    String? patientId,
    String? encounterId,
    bool activeOnly = false,
  }) async {
    final result = _prescriptions
        .where(
          (p) =>
              (patientId == null || p.patientId == patientId) &&
              (encounterId == null || p.encounterId == encounterId) &&
              (!activeOnly || p.isActive),
        )
        .toList();
    result.sort((a, b) => b.startDate.compareTo(a.startDate));
    return result;
  }

  @override
  Future<Prescription?> findPrescription(String id) async {
    for (final prescription in _prescriptions) {
      if (prescription.id == id) return prescription;
    }
    return null;
  }

  @override
  Future<Prescription> savePrescription(Prescription prescription) async =>
      _upsert<Prescription>(_prescriptions, prescription, (p) => p.id);

  @override
  Future<List<Dispense>> listDispenses({
    String? patientId,
    String? prescriptionId,
    String? cabinetId,
    DispenseStatus? status,
    int limit = 200,
  }) async {
    final result = _dispenses
        .where(
          (d) =>
              (patientId == null || d.patientId == patientId) &&
              (prescriptionId == null || d.prescriptionId == prescriptionId) &&
              (cabinetId == null || d.cabinetId == cabinetId) &&
              (status == null || d.status == status),
        )
        .toList();
    result.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    return result.take(limit).toList(growable: false);
  }

  @override
  Future<Dispense> saveDispense(Dispense dispense) async =>
      _upsert<Dispense>(_dispenses, dispense, (d) => d.id);

  // ---- Pharmacy stock ------------------------------------------------------

  @override
  Future<List<Cabinet>> listCabinets({String? wardId}) async => _cabinets
      .where((c) => wardId == null || c.wardId == wardId)
      .toList(growable: false);

  @override
  Future<Cabinet?> findCabinet(String id) async {
    for (final cabinet in _cabinets) {
      if (cabinet.id == id) return cabinet;
    }
    return null;
  }

  @override
  Future<Cabinet> saveCabinet(Cabinet cabinet) async =>
      _upsert<Cabinet>(_cabinets, cabinet, (c) => c.id);

  @override
  Future<List<StockItem>> listStock({String? cabinetId, String? query}) async {
    final needle = query?.trim().toLowerCase() ?? '';
    final result = _stock
        .where(
          (s) =>
              (cabinetId == null || s.cabinetId == cabinetId) &&
              (needle.isEmpty ||
                  s.medication.name.en.toLowerCase().contains(needle) ||
                  s.medication.name.fr.toLowerCase().contains(needle) ||
                  s.medication.name.nl.toLowerCase().contains(needle) ||
                  s.slot.toLowerCase().contains(needle)),
        )
        .toList();
    result.sort((a, b) => a.slot.compareTo(b.slot));
    return result;
  }

  @override
  Future<StockItem?> findStockItem(String id) async {
    for (final item in _stock) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<StockItem> saveStockItem(StockItem item) async =>
      _upsert<StockItem>(_stock, item, (s) => s.id);

  // ---- Devices -------------------------------------------------------------

  @override
  Future<List<MedicalDevice>> listDevices({String? wardId}) async {
    final result = _devices
        .where((d) => wardId == null || d.wardId == wardId)
        .toList();
    result.sort((a, b) => a.code.compareTo(b.code));
    return result;
  }

  @override
  Future<MedicalDevice?> findDeviceByCode(String code) async {
    for (final device in _devices) {
      if (device.code.toUpperCase() == code.toUpperCase()) return device;
    }
    return null;
  }

  @override
  Future<MedicalDevice> saveDevice(MedicalDevice device) async =>
      _upsert<MedicalDevice>(_devices, device, (d) => d.id);

  // ---- Notes ---------------------------------------------------------------

  @override
  Future<List<ClinicalNote>> listNotes({
    String? patientId,
    String? encounterId,
    NoteType? type,
  }) async {
    final result = _notes
        .where(
          (n) =>
              (patientId == null || n.patientId == patientId) &&
              (encounterId == null || n.encounterId == encounterId) &&
              (type == null || n.type == type),
        )
        .toList();
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  @override
  Future<ClinicalNote> saveNote(ClinicalNote note) async =>
      _upsert<ClinicalNote>(_notes, note, (n) => n.id);

  @override
  Future<void> deleteNote(String id) async {
    _notes.removeWhere((note) => note.id == id);
    notifyListeners();
  }

  // ---- Integration ---------------------------------------------------------

  @override
  Future<List<IntegrationFlow>> listFlows() async =>
      List<IntegrationFlow>.unmodifiable(_flows);

  @override
  Future<IntegrationFlow?> findFlow(String id) async {
    for (final flow in _flows) {
      if (flow.id == id) return flow;
    }
    return null;
  }

  @override
  Future<IntegrationFlow> saveFlow(IntegrationFlow flow) async =>
      _upsert<IntegrationFlow>(_flows, flow, (f) => f.id);

  @override
  Future<void> deleteFlow(String id) async {
    _flows.removeWhere((flow) => flow.id == id);
    notifyListeners();
  }

  @override
  Future<List<IntegrationMessage>> listMessages({
    String? flowId,
    MessageStatus? status,
    int limit = 100,
  }) async {
    final result = _messages
        .where(
          (m) =>
              (flowId == null || m.flowId == flowId) &&
              (status == null || m.status == status),
        )
        .toList();
    result.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    return result.take(limit).toList(growable: false);
  }

  @override
  Future<IntegrationMessage> saveMessage(IntegrationMessage message) async =>
      _upsert<IntegrationMessage>(_messages, message, (m) => m.id);
}
