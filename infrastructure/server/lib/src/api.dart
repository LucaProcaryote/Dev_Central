import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'store.dart';

/// The REST API the Flutter applications talk to.
///
/// The routes deliberately mirror `RestHospitalRepository` in `hospital_core`
/// one for one: if you can read that class, you can read this router, and a
/// student adding an endpoint knows exactly which two files to touch.
class HospitalApi {
  HospitalApi({required this.store, required this.app});

  final HospitalStore store;

  /// Which application this instance serves. Reported by `/health` so an
  /// operator hitting the wrong port finds out immediately.
  final String app;

  Handler get handler {
    final router = Router()
      ..get('/health', _health)
      ..get('/patients', _listPatients)
      ..get('/patients/resolve', _resolvePatient)
      ..get('/patients/<id>/latest-vitals', _latestVitals)
      ..get('/patients/<id>', _findPatient)
      ..put('/patients/<id>', _savePatient)
      ..get('/wards', _listWards)
      ..get('/rooms', _listRooms)
      ..get('/beds', _listBeds)
      ..get('/beds/<id>', _findBed)
      ..put('/beds/<id>', _saveBed)
      ..get('/encounters', _listEncounters)
      ..get('/encounters/<id>', _findEncounter)
      ..put('/encounters/<id>', _saveEncounter)
      ..get('/movements', _listMovements)
      ..post('/movements', _addMovement)
      ..get('/observations', _listObservations)
      ..post('/observations', _addObservation)
      ..get('/formulary', _listFormulary)
      ..get('/prescriptions', _listPrescriptions)
      ..get('/prescriptions/<id>', _findPrescription)
      ..put('/prescriptions/<id>', _savePrescription)
      ..get('/dispenses', _listDispenses)
      ..put('/dispenses/<id>', _saveDispense)
      ..get('/cabinets', _listCabinets)
      ..get('/cabinets/<id>', _findCabinet)
      ..put('/cabinets/<id>', _saveCabinet)
      ..get('/stock', _listStock)
      ..get('/stock/<id>', _findStockItem)
      ..put('/stock/<id>', _saveStockItem)
      ..get('/devices', _listDevices)
      ..get('/devices/<code>', _findDevice)
      ..put('/devices/<id>', _saveDevice)
      ..get('/notes', _listNotes)
      ..put('/notes/<id>', _saveNote)
      ..delete('/notes/<id>', _deleteNote)
      ..get('/flows', _listFlows)
      ..get('/flows/<id>', _findFlow)
      ..put('/flows/<id>', _saveFlow)
      ..delete('/flows/<id>', _deleteFlow)
      ..get('/messages', _listMessages)
      ..put('/messages/<id>', _saveMessage)
      // The inbox other applications post events to. The ADT and device
      // simulators use this; it is the one route without a repository twin.
      ..post('/messages', _receiveMessage);

    return const Pipeline()
        .addMiddleware(_cors)
        .addMiddleware(logRequests())
        .addMiddleware(_errors)
        .addHandler(router.call);
  }

  // ---- Middleware ----------------------------------------------------------

  /// The Flutter web applications are served from a different origin, so
  /// without this the browser refuses every request before it is sent.
  /// Wide open is right for a classroom on a laptop and wrong anywhere else.
  static const Map<String, String> _corsHeaders = <String, String>{
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization',
    'Access-Control-Max-Age': '86400',
  };

  static Handler Function(Handler) get _cors => (Handler inner) =>
      (Request request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok(null, headers: _corsHeaders);
        }
        final response = await inner(request);
        return response.change(headers: _corsHeaders);
      };

  /// Turns an exception into a JSON error with a status code that means
  /// something, rather than an HTML page or a blanket 500.
  ///
  /// A database constraint rejecting a write is not a server fault - it is the
  /// schema doing its job, and the client needs to be told which rule it broke.
  /// Passing the raw driver message through ("Severity.error 23505: duplicate
  /// key value violates unique constraint …") tells a student nothing.
  static Handler Function(Handler) get _errors => (Handler inner) =>
      (Request request) async {
        try {
          return await inner(request);
        } on ServerException catch (error) {
          final mapped = _describeDatabaseError(error);
          // ignore: avoid_print
          print('   ${request.method} ${request.requestedUri.path} → '
              '${mapped.status}: ${mapped.message}');
          return _json(
            <String, dynamic>{
              'error': mapped.message,
              'constraint': error.constraintName,
              'code': error.code,
            },
            status: mapped.status,
          );
        } on FormatException catch (error) {
          return _json(
            <String, dynamic>{'error': 'Malformed request body: ${error.message}'},
            status: 400,
          );
        } catch (error, stack) {
          // ignore: avoid_print
          print('!! ${request.method} ${request.requestedUri.path}: $error\n$stack');
          return _json(<String, dynamic>{'error': '$error'}, status: 500);
        }
      };

  /// Maps a PostgreSQL error onto an HTTP status and a sentence a person can
  /// act on. The named constraints in the schema are what make this possible.
  static ({int status, String message}) _describeDatabaseError(
    ServerException error,
  ) {
    final constraint = error.constraintName ?? '';

    // 409 means "this clashes with something already there"; 422 means "this
    // record is not internally coherent". The distinction matters to a client
    // deciding whether to retry, and to a student reading the network tab.
    const conflicts = <String, String>{
      'encounters_one_active_per_patient':
          'That patient is already admitted. Discharge the current stay first.',
      'encounters_one_active_per_bed':
          'That bed is already occupied by another patient.',
      'stock_items_cabinet_id_slot_key':
          'That drawer already holds a different product.',
      'stock_items_cabinet_id_medication_code_key':
          'That product already has a drawer in this cabinet.',
      'patients_mrn_key':
          'That medical record number is already in use.',
      'patients_national_number_key':
          'That national register number is already in use.',
      'wards_code_key': 'That ward code is already in use.',
      'cabinets_code_key': 'That cabinet code is already in use.',
      'devices_code_key': 'That device code is already in use.',
    };

    const unprocessable = <String, String>{
      'bed_occupancy_consistent':
          'An occupied bed must name its occupant, and a free bed must not.',
      'encounter_period_ordered':
          'A stay cannot end before it began.',
      'encounter_discharge_consistent':
          'A finished stay needs a discharge date.',
      'prescription_period_ordered':
          'A prescription cannot end before it starts.',
      'dispense_completion_consistent':
          'A dispensed dose must record when it was handed over and by whom.',
      'dispense_refusal_has_reason':
          'A refused dose must record why it was refused.',
      'stock_items_quantity_on_hand_check': 'Stock cannot go negative.',
      'prescriptions_dose_quantity_check':
          'A prescription needs a dose greater than zero.',
    };

    if (conflicts.containsKey(constraint)) {
      return (status: 409, message: conflicts[constraint]!);
    }
    if (unprocessable.containsKey(constraint)) {
      return (status: 422, message: unprocessable[constraint]!);
    }

    // Fall back on the SQLSTATE class when the constraint is not one we have
    // written a sentence for.
    return switch (error.code) {
      // unique_violation, foreign_key_violation
      '23505' => (
          status: 409,
          message: 'That record already exists${constraint.isEmpty ? '' : ' ($constraint)'}.'
        ),
      '23503' => (
          status: 409,
          message: 'It refers to something that does not exist'
              '${constraint.isEmpty ? '' : ' ($constraint)'}.'
        ),
      // check_violation, not_null_violation
      '23514' => (
          status: 422,
          message: 'The value breaks a rule the database enforces'
              '${constraint.isEmpty ? '' : ' ($constraint)'}.'
        ),
      '23502' => (status: 422, message: 'A required field was missing.'),
      _ => (status: 500, message: error.message),
    };
  }

  // ---- Helpers -------------------------------------------------------------

  static Response _json(Object? body, {int status = 200}) => Response(
        status,
        body: jsonEncode(body),
        headers: const <String, String>{
          'Content-Type': 'application/json; charset=utf-8',
        },
      );

  static Response _notFound() =>
      _json(<String, dynamic>{'error': 'not found'}, status: 404);

  static Future<Map<String, dynamic>> _body(Request request) async {
    final text = await request.readAsString();
    if (text.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(text);
    if (decoded is! Map) {
      throw const FormatException('Expected a JSON object');
    }
    return decoded.cast<String, dynamic>();
  }

  static String? _query(Request request, String name) {
    final value = request.url.queryParameters[name];
    return (value == null || value.isEmpty) ? null : value;
  }

  static bool _flag(Request request, String name) =>
      request.url.queryParameters[name] == 'true';

  static int _limit(Request request, int fallback) =>
      int.tryParse(request.url.queryParameters['limit'] ?? '') ?? fallback;

  // ---- Handlers ------------------------------------------------------------

  Future<Response> _health(Request request) async => _json(<String, dynamic>{
        'status': await store.isHealthy() ? 'ok' : 'degraded',
        'app': app,
        'time': DateTime.now().toIso8601String(),
      });

  Future<Response> _listPatients(Request request) async =>
      _json(await store.listPatients(query: _query(request, 'query')));

  Future<Response> _findPatient(Request request, String id) async {
    final patient = await store.findPatient(id);
    return patient == null ? _notFound() : _json(patient);
  }

  Future<Response> _resolvePatient(Request request) async {
    final reference = _query(request, 'ref');
    if (reference == null) return _notFound();
    final patient = await store.resolvePatient(reference);
    return patient == null ? _notFound() : _json(patient);
  }

  Future<Response> _savePatient(Request request, String id) async =>
      _json(await store.savePatient(<String, dynamic>{
        ...await _body(request),
        'id': id,
      }));

  Future<Response> _listWards(Request request) async =>
      _json(await store.listWards());

  Future<Response> _listRooms(Request request) async =>
      _json(await store.listRooms(wardId: _query(request, 'wardId')));

  Future<Response> _listBeds(Request request) async => _json(await store.listBeds(
        wardId: _query(request, 'wardId'),
        status: _query(request, 'status'),
      ));

  Future<Response> _findBed(Request request, String id) async {
    final bed = await store.findBed(id);
    return bed == null ? _notFound() : _json(bed);
  }

  Future<Response> _saveBed(Request request, String id) async =>
      _json(await store.saveBed(<String, dynamic>{
        ...await _body(request),
        'id': id,
      }));

  Future<Response> _listEncounters(Request request) async =>
      _json(await store.listEncounters(
        patientId: _query(request, 'patientId'),
        wardId: _query(request, 'wardId'),
        activeOnly: _flag(request, 'active'),
      ));

  Future<Response> _findEncounter(Request request, String id) async {
    final encounter = await store.findEncounter(id);
    return encounter == null ? _notFound() : _json(encounter);
  }

  Future<Response> _saveEncounter(Request request, String id) async =>
      _json(await store.saveEncounter(<String, dynamic>{
        ...await _body(request),
        'id': id,
      }));

  Future<Response> _listMovements(Request request) async =>
      _json(await store.listMovements(
        encounterId: _query(request, 'encounterId'),
        patientId: _query(request, 'patientId'),
        limit: _limit(request, 100),
      ));

  Future<Response> _addMovement(Request request) async =>
      _json(await store.addMovement(await _body(request)));

  Future<Response> _listObservations(Request request) async =>
      _json(await store.listObservations(
        patientId: _query(request, 'patientId'),
        encounterId: _query(request, 'encounterId'),
        type: _query(request, 'type'),
        since: DateTime.tryParse(_query(request, 'since') ?? ''),
        limit: _limit(request, 500),
      ));

  Future<Response> _addObservation(Request request) async =>
      _json(await store.addObservation(await _body(request)));

  Future<Response> _latestVitals(Request request, String id) async =>
      _json(await store.latestVitals(id));

  Future<Response> _listFormulary(Request request) async =>
      _json(await store.listFormulary(query: _query(request, 'query')));

  Future<Response> _listPrescriptions(Request request) async =>
      _json(await store.listPrescriptions(
        patientId: _query(request, 'patientId'),
        encounterId: _query(request, 'encounterId'),
        activeOnly: _flag(request, 'active'),
      ));

  Future<Response> _findPrescription(Request request, String id) async {
    final prescription = await store.findPrescription(id);
    return prescription == null ? _notFound() : _json(prescription);
  }

  Future<Response> _savePrescription(Request request, String id) async =>
      _json(await store.savePrescription(<String, dynamic>{
        ...await _body(request),
        'id': id,
      }));

  Future<Response> _listDispenses(Request request) async =>
      _json(await store.listDispenses(
        patientId: _query(request, 'patientId'),
        prescriptionId: _query(request, 'prescriptionId'),
        cabinetId: _query(request, 'cabinetId'),
        status: _query(request, 'status'),
        limit: _limit(request, 200),
      ));

  Future<Response> _saveDispense(Request request, String id) async =>
      _json(await store.saveDispense(<String, dynamic>{
        ...await _body(request),
        'id': id,
      }));

  Future<Response> _listCabinets(Request request) async =>
      _json(await store.listCabinets(wardId: _query(request, 'wardId')));

  Future<Response> _findCabinet(Request request, String id) async {
    final cabinet = await store.findCabinet(id);
    return cabinet == null ? _notFound() : _json(cabinet);
  }

  Future<Response> _saveCabinet(Request request, String id) async =>
      _json(await store.saveCabinet(<String, dynamic>{
        ...await _body(request),
        'id': id,
      }));

  Future<Response> _listStock(Request request) async => _json(await store.listStock(
        cabinetId: _query(request, 'cabinetId'),
        query: _query(request, 'query'),
      ));

  Future<Response> _findStockItem(Request request, String id) async {
    final item = await store.findStockItem(id);
    return item == null ? _notFound() : _json(item);
  }

  Future<Response> _saveStockItem(Request request, String id) async =>
      _json(await store.saveStockItem(<String, dynamic>{
        ...await _body(request),
        'id': id,
      }));

  Future<Response> _listDevices(Request request) async =>
      _json(await store.listDevices(wardId: _query(request, 'wardId')));

  Future<Response> _findDevice(Request request, String code) async {
    final device = await store.findDeviceByCode(code);
    return device == null ? _notFound() : _json(device);
  }

  Future<Response> _saveDevice(Request request, String id) async =>
      _json(await store.saveDevice(<String, dynamic>{
        ...await _body(request),
        'id': id,
      }));

  Future<Response> _listNotes(Request request) async => _json(await store.listNotes(
        patientId: _query(request, 'patientId'),
        encounterId: _query(request, 'encounterId'),
        type: _query(request, 'type'),
      ));

  Future<Response> _saveNote(Request request, String id) async =>
      _json(await store.saveNote(<String, dynamic>{
        ...await _body(request),
        'id': id,
      }));

  Future<Response> _deleteNote(Request request, String id) async {
    await store.deleteNote(id);
    return Response(204);
  }

  Future<Response> _listFlows(Request request) async =>
      _json(await store.listFlows());

  Future<Response> _findFlow(Request request, String id) async {
    final flow = await store.findFlow(id);
    return flow == null ? _notFound() : _json(flow);
  }

  Future<Response> _saveFlow(Request request, String id) async =>
      _json(await store.saveFlow(<String, dynamic>{
        ...await _body(request),
        'id': id,
      }));

  Future<Response> _deleteFlow(Request request, String id) async {
    await store.deleteFlow(id);
    return Response(204);
  }

  Future<Response> _listMessages(Request request) async =>
      _json(await store.listMessages(
        flowId: _query(request, 'flowId'),
        status: _query(request, 'status'),
        limit: _limit(request, 100),
      ));

  Future<Response> _saveMessage(Request request, String id) async =>
      _json(await store.saveMessage(<String, dynamic>{
        ...await _body(request),
        'id': id,
      }));

  /// Accepts an event from another application and records it.
  ///
  /// The engine's own inbox. It stores the message and answers immediately -
  /// the sender must not be made to wait for downstream processing, and must
  /// not fail if a destination is down. Which flows then pick it up is the
  /// EAI application's business.
  Future<Response> _receiveMessage(Request request) async {
    final body = await _body(request);
    final id = body['id']?.toString() ??
        'msg-${DateTime.now().microsecondsSinceEpoch}';

    final stored = await store.saveMessage(<String, dynamic>{
      ...body,
      'id': id,
      'status': body['status'] ?? 'received',
      'received_at': body['received_at'] ?? DateTime.now().toIso8601String(),
    });
    return _json(stored, status: 202);
  }
}
