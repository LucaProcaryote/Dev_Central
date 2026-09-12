import 'dart:convert';

import 'package:http/http.dart' as http;

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
import '../../util/json.dart';
import '../hospital_repository.dart';

/// Raised when the API answers with something other than success.
class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Talks to the Dart `shelf` API server that fronts this application's
/// PostgreSQL database.
///
/// The browser cannot open a PostgreSQL socket and an application should not
/// carry database credentials anyway, so every deployment - web and mobile
/// alike - goes through this HTTP layer. That is the same three-tier shape a
/// real hospital application has, which is the point.
class RestHospitalRepository extends HospitalRepository {
  RestHospitalRepository({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  /// e.g. `http://localhost:8081`.
  final String baseUrl;
  final http.Client _client;

  @override
  String get backendDescription => 'restApi';

  @override
  Future<void> initialize() async {
    // Fail fast and loudly if the API is not up: a silent empty patient list is
    // far more confusing to debug than a clear connection error.
    await _get('/health');
  }

  Uri _uri(String path, [Map<String, String?> query = const <String, String?>{}]) {
    final filtered = <String, String>{};
    query.forEach((key, value) {
      if (value != null && value.isNotEmpty) filtered[key] = value;
    });
    return Uri.parse('$baseUrl$path').replace(
      queryParameters: filtered.isEmpty ? null : filtered,
    );
  }

  Future<dynamic> _get(String path,
      [Map<String, String?> query = const <String, String?>{}]) async {
    final response = await _client.get(
      _uri(path, query),
      headers: const <String, String>{'Accept': 'application/json'},
    );
    return _decode(response);
  }

  Future<dynamic> _send(
    String method,
    String path,
    Map<String, dynamic> body,
  ) async {
    final request = http.Request(method, _uri(path))
      ..headers.addAll(const <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      })
      ..body = jsonEncode(body);
    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    final decoded = _decode(response);
    notifyListeners();
    return decoded;
  }

  dynamic _decode(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    String message = response.body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['error'] != null) {
        message = decoded['error'].toString();
      }
    } catch (_) {
      // Body was not JSON; the raw text is the best message available.
    }
    throw ApiException(response.statusCode, message);
  }

  List<Map<String, dynamic>> _rows(dynamic decoded) => asMapList(decoded);

  Map<String, dynamic>? _row(dynamic decoded) =>
      decoded is Map ? decoded.cast<String, dynamic>() : null;

  // ---- Patients ------------------------------------------------------------

  @override
  Future<List<Patient>> listPatients({String? query}) async =>
      _rows(await _get('/patients', <String, String?>{'query': query}))
          .map(Patient.fromJson)
          .toList();

  @override
  Future<Patient?> findPatient(String id) async {
    try {
      final row = _row(await _get('/patients/$id'));
      return row == null ? null : Patient.fromJson(row);
    } on ApiException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<Patient?> resolvePatient(String reference) async {
    final row = _row(
      await _get('/patients/resolve', <String, String?>{'ref': reference}),
    );
    return row == null ? null : Patient.fromJson(row);
  }

  @override
  Future<Patient> savePatient(Patient patient) async => Patient.fromJson(
        _row(await _send('PUT', '/patients/${patient.id}', patient.toJson()))!,
      );

  // ---- Locations -----------------------------------------------------------

  @override
  Future<List<Ward>> listWards() async =>
      _rows(await _get('/wards')).map(Ward.fromJson).toList();

  @override
  Future<List<Room>> listRooms({String? wardId}) async =>
      _rows(await _get('/rooms', <String, String?>{'wardId': wardId}))
          .map(Room.fromJson)
          .toList();

  @override
  Future<List<Bed>> listBeds({String? wardId, BedStatus? status}) async =>
      _rows(await _get('/beds', <String, String?>{
        'wardId': wardId,
        'status': status?.name,
      })).map(Bed.fromJson).toList();

  @override
  Future<Bed?> findBed(String id) async {
    final row = _row(await _get('/beds/$id'));
    return row == null ? null : Bed.fromJson(row);
  }

  @override
  Future<Bed> saveBed(Bed bed) async =>
      Bed.fromJson(_row(await _send('PUT', '/beds/${bed.id}', bed.toJson()))!);

  @override
  Future<BedPlacement?> resolvePlacement(String bedId) async {
    final bed = await findBed(bedId);
    if (bed == null) return null;
    final rooms = await listRooms(wardId: bed.wardId);
    final wards = await listWards();
    Room? room;
    for (final candidate in rooms) {
      if (candidate.id == bed.roomId) room = candidate;
    }
    Ward? ward;
    for (final candidate in wards) {
      if (candidate.id == bed.wardId) ward = candidate;
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
  }) async =>
      _rows(await _get('/encounters', <String, String?>{
        'patientId': patientId,
        'wardId': wardId,
        'active': activeOnly ? 'true' : null,
      })).map(Encounter.fromJson).toList();

  @override
  Future<Encounter?> findEncounter(String id) async {
    final row = _row(await _get('/encounters/$id'));
    return row == null ? null : Encounter.fromJson(row);
  }

  @override
  Future<Encounter?> activeEncounterFor(String patientId) async {
    final encounters =
        await listEncounters(patientId: patientId, activeOnly: true);
    return encounters.isEmpty ? null : encounters.first;
  }

  @override
  Future<Encounter> saveEncounter(Encounter encounter) async =>
      Encounter.fromJson(_row(
        await _send('PUT', '/encounters/${encounter.id}', encounter.toJson()),
      )!);

  @override
  Future<List<Movement>> listMovements({
    String? encounterId,
    String? patientId,
    int limit = 100,
  }) async =>
      _rows(await _get('/movements', <String, String?>{
        'encounterId': encounterId,
        'patientId': patientId,
        'limit': '$limit',
      })).map(Movement.fromJson).toList();

  @override
  Future<Movement> addMovement(Movement movement) async => Movement.fromJson(
        _row(await _send('POST', '/movements', movement.toJson()))!,
      );

  // ---- Observations --------------------------------------------------------

  @override
  Future<List<Observation>> listObservations({
    String? patientId,
    String? encounterId,
    VitalSignType? type,
    DateTime? since,
    int limit = 500,
  }) async =>
      _rows(await _get('/observations', <String, String?>{
        'patientId': patientId,
        'encounterId': encounterId,
        'type': type?.name,
        'since': since?.toIso8601String(),
        'limit': '$limit',
      })).map(Observation.fromJson).toList();

  @override
  Future<Observation> addObservation(Observation observation) async =>
      Observation.fromJson(
        _row(await _send('POST', '/observations', observation.toJson()))!,
      );

  @override
  Future<Map<VitalSignType, Observation>> latestVitals(String patientId) async {
    final rows = _rows(await _get('/patients/$patientId/latest-vitals'));
    final result = <VitalSignType, Observation>{};
    for (final row in rows) {
      final observation = Observation.fromJson(row);
      result[observation.type] = observation;
    }
    return result;
  }

  // ---- Prescriptions -------------------------------------------------------

  @override
  Future<List<Medication>> listFormulary({String? query}) async =>
      _rows(await _get('/formulary', <String, String?>{'query': query}))
          .map(Medication.fromJson)
          .toList();

  @override
  Future<List<Prescription>> listPrescriptions({
    String? patientId,
    String? encounterId,
    bool activeOnly = false,
  }) async =>
      _rows(await _get('/prescriptions', <String, String?>{
        'patientId': patientId,
        'encounterId': encounterId,
        'active': activeOnly ? 'true' : null,
      })).map(Prescription.fromJson).toList();

  @override
  Future<Prescription?> findPrescription(String id) async {
    final row = _row(await _get('/prescriptions/$id'));
    return row == null ? null : Prescription.fromJson(row);
  }

  @override
  Future<Prescription> savePrescription(Prescription prescription) async =>
      Prescription.fromJson(_row(await _send(
        'PUT',
        '/prescriptions/${prescription.id}',
        prescription.toJson(),
      ))!);

  @override
  Future<List<Dispense>> listDispenses({
    String? patientId,
    String? prescriptionId,
    String? cabinetId,
    DispenseStatus? status,
    int limit = 200,
  }) async =>
      _rows(await _get('/dispenses', <String, String?>{
        'patientId': patientId,
        'prescriptionId': prescriptionId,
        'cabinetId': cabinetId,
        'status': status?.name,
        'limit': '$limit',
      })).map(Dispense.fromJson).toList();

  @override
  Future<Dispense> saveDispense(Dispense dispense) async => Dispense.fromJson(
        _row(await _send('PUT', '/dispenses/${dispense.id}', dispense.toJson()))!,
      );

  // ---- Pharmacy stock ------------------------------------------------------

  @override
  Future<List<Cabinet>> listCabinets({String? wardId}) async =>
      _rows(await _get('/cabinets', <String, String?>{'wardId': wardId}))
          .map(Cabinet.fromJson)
          .toList();

  @override
  Future<Cabinet?> findCabinet(String id) async {
    final row = _row(await _get('/cabinets/$id'));
    return row == null ? null : Cabinet.fromJson(row);
  }

  @override
  Future<Cabinet> saveCabinet(Cabinet cabinet) async => Cabinet.fromJson(
        _row(await _send('PUT', '/cabinets/${cabinet.id}', cabinet.toJson()))!,
      );

  @override
  Future<List<StockItem>> listStock({String? cabinetId, String? query}) async =>
      _rows(await _get('/stock', <String, String?>{
        'cabinetId': cabinetId,
        'query': query,
      })).map(StockItem.fromJson).toList();

  @override
  Future<StockItem?> findStockItem(String id) async {
    final row = _row(await _get('/stock/$id'));
    return row == null ? null : StockItem.fromJson(row);
  }

  @override
  Future<StockItem> saveStockItem(StockItem item) async => StockItem.fromJson(
        _row(await _send('PUT', '/stock/${item.id}', item.toJson()))!,
      );

  // ---- Devices -------------------------------------------------------------

  @override
  Future<List<MedicalDevice>> listDevices({String? wardId}) async =>
      _rows(await _get('/devices', <String, String?>{'wardId': wardId}))
          .map(MedicalDevice.fromJson)
          .toList();

  @override
  Future<MedicalDevice?> findDeviceByCode(String code) async {
    final row = _row(await _get('/devices/$code'));
    return row == null ? null : MedicalDevice.fromJson(row);
  }

  @override
  Future<MedicalDevice> saveDevice(MedicalDevice device) async =>
      MedicalDevice.fromJson(
        _row(await _send('PUT', '/devices/${device.id}', device.toJson()))!,
      );

  // ---- Notes ---------------------------------------------------------------

  @override
  Future<List<ClinicalNote>> listNotes({
    String? patientId,
    String? encounterId,
    NoteType? type,
  }) async =>
      _rows(await _get('/notes', <String, String?>{
        'patientId': patientId,
        'encounterId': encounterId,
        'type': type?.name,
      })).map(ClinicalNote.fromJson).toList();

  @override
  Future<ClinicalNote> saveNote(ClinicalNote note) async => ClinicalNote.fromJson(
        _row(await _send('PUT', '/notes/${note.id}', note.toJson()))!,
      );

  @override
  Future<void> deleteNote(String id) async {
    await _send('DELETE', '/notes/$id', const <String, dynamic>{});
  }

  // ---- Integration ---------------------------------------------------------

  @override
  Future<List<IntegrationFlow>> listFlows() async =>
      _rows(await _get('/flows')).map(IntegrationFlow.fromJson).toList();

  @override
  Future<IntegrationFlow?> findFlow(String id) async {
    final row = _row(await _get('/flows/$id'));
    return row == null ? null : IntegrationFlow.fromJson(row);
  }

  @override
  Future<IntegrationFlow> saveFlow(IntegrationFlow flow) async =>
      IntegrationFlow.fromJson(
        _row(await _send('PUT', '/flows/${flow.id}', flow.toJson()))!,
      );

  @override
  Future<void> deleteFlow(String id) async {
    await _send('DELETE', '/flows/$id', const <String, dynamic>{});
  }

  @override
  Future<List<IntegrationMessage>> listMessages({
    String? flowId,
    MessageStatus? status,
    int limit = 100,
  }) async =>
      _rows(await _get('/messages', <String, String?>{
        'flowId': flowId,
        'status': status?.name,
        'limit': '$limit',
      })).map(IntegrationMessage.fromJson).toList();

  @override
  Future<IntegrationMessage> saveMessage(IntegrationMessage message) async =>
      IntegrationMessage.fromJson(
        _row(await _send('PUT', '/messages/${message.id}', message.toJson()))!,
      );

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
