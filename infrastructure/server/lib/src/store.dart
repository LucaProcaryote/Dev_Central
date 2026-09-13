import 'dart:convert';

import 'package:postgres/postgres.dart';

/// Thin SQL-to-JSON layer over one application's database.
///
/// Deliberately thin. The column names already match the JSON keys the Flutter
/// models parse, so there is no second copy of the domain model here to drift
/// out of step with the first. What this class does own is the SQL: every
/// query is written out, parameterised, and readable, because reading the SQL
/// is half the point of the exercise.
class HospitalStore {
  HospitalStore(this._db);

  /// A pool, not a single connection, and that is not a performance decision.
  ///
  /// One connection opened at start-up works on a laptop and fails on Cloud
  /// Run. Between requests the instance's CPU is frozen and Cloud SQL drops
  /// what it sees as an idle client; the socket is then dead, but nothing says
  /// so until a query is written into it and no answer ever comes back. A pool
  /// replaces a connection that has aged out instead of discovering it is dead
  /// halfway through somebody's request.
  final Pool<void> _db;

  /// How long a connection may live before the pool retires it. Comfortably
  /// under Cloud SQL's idle timeout, so a stale connection is never handed to
  /// a request in the first place.
  static const Duration _maxConnectionAge = Duration(minutes: 5);

  /// Nothing may hang for longer than this. The driver's own default is five
  /// minutes, which is far past the point where every caller has given up and
  /// the only visible symptom is silence.
  static const Duration _queryTimeout = Duration(seconds: 30);
  static const Duration _connectTimeout = Duration(seconds: 15);

  /// Builds the store. Opens nothing.
  ///
  /// This is deliberate, and it is the difference between a service that
  /// starts and one that does not. A pool creates connections when it is first
  /// asked to run something, so the process can listen immediately and report
  /// the database's state through `/health` - rather than holding the port
  /// hostage to a dependency and leaving the platform to guess why nothing
  /// ever answered.
  factory HospitalStore.open({
    required String host,
    required int port,
    required String database,
    required String username,
    required String password,
    bool isUnixSocket = false,
    SslMode sslMode = SslMode.disable,
    Duration connectTimeout = _connectTimeout,
    Duration queryTimeout = _queryTimeout,
  }) {
    final pool = Pool<void>.withEndpoints(
      <Endpoint>[
        Endpoint(
          host: host,
          port: port,
          database: database,
          username: username,
          password: password,
          isUnixSocket: isUnixSocket,
        ),
      ],
      settings: PoolSettings(
        // Plain TCP is right on a classroom network and on a unix socket,
        // where the kernel is the boundary. A connection that crosses a
        // network we do not own is given `--db-ssl require` instead.
        sslMode: sslMode,
        maxConnectionCount: 4,
        maxConnectionAge: _maxConnectionAge,
        connectTimeout: connectTimeout,
        queryTimeout: queryTimeout,
      ),
    );
    return HospitalStore(pool);
  }

  Future<void> close() => _db.close();

  /// Runs a query and returns each row as a JSON-ready map.
  ///
  /// `jsonb` columns arrive already decoded and `timestamptz` as [DateTime];
  /// both are normalised here so the API emits exactly what the Flutter models
  /// expect to parse.
  Future<List<Map<String, dynamic>>> _rows(
    String sql, [
    Map<String, Object?> values = const <String, Object?>{},
  ]) async {
    final result = await _db.execute(Sql.named(sql), parameters: values);
    return result.map((row) {
      final map = row.toColumnMap();
      return map.map((key, value) => MapEntry(key, _normalise(value)));
    }).toList();
  }

  static Object? _normalise(Object? value) {
    if (value is DateTime) return value.toIso8601String();
    if (value is UndecodedBytes) return value.asString;
    return value;
  }

  Future<Map<String, dynamic>?> _one(
    String sql, [
    Map<String, Object?> values = const <String, Object?>{},
  ]) async {
    final rows = await _rows(sql, values);
    return rows.isEmpty ? null : rows.first;
  }

  /// Whether the database answers, with its own short deadline.
  ///
  /// A health check that can hang is worse than no health check: it turns
  /// "the database is unreachable" into "the whole service is unreachable",
  /// which is a much harder thing to diagnose from outside.
  Future<bool> isHealthy() async {
    try {
      await _db.execute('SELECT 1').timeout(const Duration(seconds: 5));
      return true;
    } catch (_) {
      return false;
    }
  }

  // ---- Patients ------------------------------------------------------------

  static const String _patientColumns = '''
    p.id, p.mrn, p.national_number, p.family_name, p.given_name, p.gender,
    p.birth_date, p.address, p.phone, p.email, p.preferred_language,
    p.blood_group, p.general_practitioner, p.deceased_date, p.photo_url,
    COALESCE(
      (SELECT jsonb_agg(jsonb_build_object(
                'id', a.id,
                'patient_id', a.patient_id,
                'substance', a.substance,
                'reaction', a.reaction,
                'criticality', a.criticality,
                'recorded_date', a.recorded_date)
              ORDER BY a.criticality DESC, a.id)
         FROM allergies a WHERE a.patient_id = p.id),
      '[]'::jsonb) AS allergies''';

  Future<List<Map<String, dynamic>>> listPatients({String? query}) async {
    if (query == null || query.trim().isEmpty) {
      return _rows(
        'SELECT $_patientColumns FROM patients p '
        'ORDER BY lower(p.family_name), lower(p.given_name)',
      );
    }
    return _rows(
      '''SELECT $_patientColumns FROM patients p
          WHERE lower(p.family_name) LIKE @q
             OR lower(p.given_name)  LIKE @q
             OR lower(p.mrn)         LIKE @q
             OR lower(COALESCE(p.national_number, '')) LIKE @q
          ORDER BY lower(p.family_name), lower(p.given_name)''',
      <String, Object?>{'q': '%${query.trim().toLowerCase()}%'},
    );
  }

  Future<Map<String, dynamic>?> findPatient(String id) => _one(
    'SELECT $_patientColumns FROM patients p WHERE p.id = @id',
    <String, Object?>{'id': id},
  );

  /// Resolves whatever identifier an inbound message happened to carry.
  Future<Map<String, dynamic>?> resolvePatient(String reference) => _one(
    '''SELECT $_patientColumns FROM patients p
            WHERE p.id = @ref OR p.mrn = @ref OR p.national_number = @ref''',
    <String, Object?>{'ref': reference},
  );

  Future<Map<String, dynamic>?> savePatient(Map<String, dynamic> body) async {
    await _db.execute(
      Sql.named('''
        INSERT INTO patients (id, mrn, national_number, family_name, given_name,
                              gender, birth_date, address, phone, email,
                              preferred_language, blood_group,
                              general_practitioner, deceased_date, photo_url)
        VALUES (@id, @mrn, @national_number, @family_name, @given_name, @gender,
                @birth_date, @address, @phone, @email, @preferred_language,
                @blood_group, @general_practitioner, @deceased_date, @photo_url)
        ON CONFLICT (id) DO UPDATE SET
          mrn = EXCLUDED.mrn,
          national_number = EXCLUDED.national_number,
          family_name = EXCLUDED.family_name,
          given_name = EXCLUDED.given_name,
          gender = EXCLUDED.gender,
          birth_date = EXCLUDED.birth_date,
          address = EXCLUDED.address,
          phone = EXCLUDED.phone,
          email = EXCLUDED.email,
          preferred_language = EXCLUDED.preferred_language,
          blood_group = EXCLUDED.blood_group,
          general_practitioner = EXCLUDED.general_practitioner,
          deceased_date = EXCLUDED.deceased_date,
          photo_url = EXCLUDED.photo_url,
          updated_at = now()'''),
      parameters: <String, Object?>{
        'id': body['id'],
        'mrn': body['mrn'],
        'national_number': body['national_number'],
        'family_name': body['family_name'],
        'given_name': body['given_name'],
        'gender': body['gender'] ?? 'unknown',
        'birth_date': _dateOnly(body['birth_date']),
        'address': _jsonb(body['address']),
        'phone': body['phone'],
        'email': body['email'],
        'preferred_language': body['preferred_language'] ?? 'fr',
        'blood_group': body['blood_group'],
        'general_practitioner': body['general_practitioner'],
        'deceased_date': _timestamp(body['deceased_date']),
        'photo_url': body['photo_url'],
      },
    );
    return findPatient(body['id'].toString());
  }

  // ---- Locations -----------------------------------------------------------

  Future<List<Map<String, dynamic>>> listWards() =>
      _rows('SELECT * FROM wards ORDER BY floor, code');

  Future<List<Map<String, dynamic>>> listRooms({String? wardId}) => _rows(
    'SELECT * FROM rooms WHERE (@ward::text IS NULL OR ward_id = @ward) '
    'ORDER BY number',
    <String, Object?>{'ward': wardId},
  );

  Future<List<Map<String, dynamic>>> listBeds({
    String? wardId,
    String? status,
  }) => _rows(
    '''SELECT * FROM beds
            WHERE (@ward::text IS NULL OR ward_id = @ward)
              AND (@status::text IS NULL OR status = @status)
            ORDER BY label''',
    <String, Object?>{'ward': wardId, 'status': status},
  );

  Future<Map<String, dynamic>?> findBed(String id) =>
      _one('SELECT * FROM beds WHERE id = @id', <String, Object?>{'id': id});

  Future<Map<String, dynamic>?> saveBed(Map<String, dynamic> body) async {
    await _db.execute(
      Sql.named('''
        INSERT INTO beds (id, room_id, ward_id, label, status,
                          current_encounter_id, current_patient_id)
        VALUES (@id, @room_id, @ward_id, @label, @status, @encounter, @patient)
        ON CONFLICT (id) DO UPDATE SET
          status = EXCLUDED.status,
          current_encounter_id = EXCLUDED.current_encounter_id,
          current_patient_id = EXCLUDED.current_patient_id'''),
      parameters: <String, Object?>{
        'id': body['id'],
        'room_id': body['room_id'],
        'ward_id': body['ward_id'],
        'label': body['label'],
        'status': body['status'] ?? 'free',
        'encounter': body['current_encounter_id'],
        'patient': body['current_patient_id'],
      },
    );
    return findBed(body['id'].toString());
  }

  // ---- Encounters ----------------------------------------------------------

  Future<List<Map<String, dynamic>>> listEncounters({
    String? patientId,
    String? wardId,
    bool activeOnly = false,
  }) => _rows(
    '''SELECT * FROM encounters
            WHERE (@patient::text IS NULL OR patient_id = @patient)
              AND (@ward::text IS NULL OR ward_id = @ward)
              AND (@active = false OR status IN ('in-progress', 'onleave'))
            ORDER BY admission_date DESC''',
    <String, Object?>{
      'patient': patientId,
      'ward': wardId,
      'active': activeOnly,
    },
  );

  Future<Map<String, dynamic>?> findEncounter(String id) => _one(
    'SELECT * FROM encounters WHERE id = @id',
    <String, Object?>{'id': id},
  );

  Future<Map<String, dynamic>?> saveEncounter(Map<String, dynamic> body) async {
    await _db.execute(
      Sql.named('''
        INSERT INTO encounters (id, patient_id, status, encounter_class,
                                admission_date, discharge_date, ward_id, room_id,
                                bed_id, admitting_practitioner,
                                attending_practitioner, reason,
                                discharge_disposition, visit_number)
        VALUES (@id, @patient_id, @status, @encounter_class, @admission_date,
                @discharge_date, @ward_id, @room_id, @bed_id, @admitting,
                @attending, @reason, @disposition, @visit_number)
        ON CONFLICT (id) DO UPDATE SET
          status = EXCLUDED.status,
          encounter_class = EXCLUDED.encounter_class,
          discharge_date = EXCLUDED.discharge_date,
          ward_id = EXCLUDED.ward_id,
          room_id = EXCLUDED.room_id,
          bed_id = EXCLUDED.bed_id,
          attending_practitioner = EXCLUDED.attending_practitioner,
          reason = EXCLUDED.reason,
          discharge_disposition = EXCLUDED.discharge_disposition'''),
      parameters: <String, Object?>{
        'id': body['id'],
        'patient_id': body['patient_id'],
        'status': body['status'],
        'encounter_class': body['encounter_class'] ?? 'IMP',
        'admission_date': _timestamp(body['admission_date']),
        'discharge_date': _timestamp(body['discharge_date']),
        'ward_id': body['ward_id'],
        'room_id': body['room_id'],
        'bed_id': body['bed_id'],
        'admitting': body['admitting_practitioner'],
        'attending': body['attending_practitioner'],
        'reason': body['reason'],
        'disposition': body['discharge_disposition'],
        'visit_number': body['visit_number'],
      },
    );
    return findEncounter(body['id'].toString());
  }

  Future<List<Map<String, dynamic>>> listMovements({
    String? encounterId,
    String? patientId,
    int limit = 100,
  }) => _rows(
    '''SELECT * FROM movements
            WHERE (@encounter::text IS NULL OR encounter_id = @encounter)
              AND (@patient::text IS NULL OR patient_id = @patient)
            ORDER BY occurred_at DESC
            LIMIT @limit''',
    <String, Object?>{
      'encounter': encounterId,
      'patient': patientId,
      'limit': limit,
    },
  );

  Future<Map<String, dynamic>?> addMovement(Map<String, dynamic> body) async {
    await _db.execute(
      Sql.named('''
        INSERT INTO movements (id, encounter_id, patient_id, type, occurred_at,
                               performed_by, from_ward_id, from_bed_id,
                               to_ward_id, to_bed_id, note)
        VALUES (@id, @encounter_id, @patient_id, @type, @occurred_at,
                @performed_by, @from_ward, @from_bed, @to_ward, @to_bed, @note)
        ON CONFLICT (id) DO NOTHING'''),
      parameters: <String, Object?>{
        'id': body['id'],
        'encounter_id': body['encounter_id'],
        'patient_id': body['patient_id'],
        'type': body['type'],
        'occurred_at': _timestamp(body['occurred_at']),
        'performed_by': body['performed_by'] ?? '',
        'from_ward': body['from_ward_id'],
        'from_bed': body['from_bed_id'],
        'to_ward': body['to_ward_id'],
        'to_bed': body['to_bed_id'],
        'note': body['note'],
      },
    );
    return _one('SELECT * FROM movements WHERE id = @id', <String, Object?>{
      'id': body['id'],
    });
  }

  // ---- Observations --------------------------------------------------------

  Future<List<Map<String, dynamic>>> listObservations({
    String? patientId,
    String? encounterId,
    String? type,
    DateTime? since,
    int limit = 500,
  }) => _rows(
    '''SELECT * FROM observations
            WHERE (@patient::text IS NULL OR patient_id = @patient)
              AND (@encounter::text IS NULL OR encounter_id = @encounter)
              AND (@type::text IS NULL OR type = @type)
              AND (@since::timestamptz IS NULL OR effective_date_time > @since)
            ORDER BY effective_date_time DESC
            LIMIT @limit''',
    <String, Object?>{
      'patient': patientId,
      'encounter': encounterId,
      'type': type,
      'since': since,
      'limit': limit,
    },
  );

  Future<Map<String, dynamic>?> addObservation(
    Map<String, dynamic> body,
  ) async {
    await _db.execute(
      Sql.named('''
        INSERT INTO observations (id, patient_id, encounter_id, type, value,
                                  unit, effective_date_time, device_id,
                                  performer, status, note)
        VALUES (@id, @patient_id, @encounter_id, @type, @value, @unit,
                @effective, @device_id, @performer, @status, @note)
        ON CONFLICT (id) DO NOTHING'''),
      parameters: <String, Object?>{
        'id': body['id'],
        'patient_id': body['patient_id'],
        'encounter_id': body['encounter_id'],
        'type': body['type'],
        'value': (body['value'] as num).toDouble(),
        'unit': body['unit'] ?? '',
        'effective': _timestamp(body['effective_date_time']),
        'device_id': body['device_id'],
        'performer': body['performer'],
        'status': body['status'] ?? 'final',
        'note': body['note'],
      },
    );
    return _one('SELECT * FROM observations WHERE id = @id', <String, Object?>{
      'id': body['id'],
    });
  }

  /// The newest reading of each measurement for one patient.
  ///
  /// `DISTINCT ON` is the tidy PostgreSQL way to say "one row per group, the
  /// first by this ordering" - far clearer than a window function or a
  /// correlated subquery, and it uses the (patient, type, time) index directly.
  Future<List<Map<String, dynamic>>> latestVitals(String patientId) => _rows(
    '''SELECT DISTINCT ON (type) *
             FROM observations
            WHERE patient_id = @patient
            ORDER BY type, effective_date_time DESC''',
    <String, Object?>{'patient': patientId},
  );

  // ---- Formulary, prescriptions, dispensing --------------------------------

  Future<List<Map<String, dynamic>>> listFormulary({String? query}) {
    if (query == null || query.trim().isEmpty) {
      return _rows('SELECT * FROM medications ORDER BY code');
    }
    return _rows(
      '''SELECT * FROM medications
          WHERE lower(name->>'en') LIKE @q
             OR lower(name->>'fr') LIKE @q
             OR lower(name->>'nl') LIKE @q
             OR lower(code)        LIKE @q
             OR lower(atc_code)    LIKE @q
          ORDER BY code''',
      <String, Object?>{'q': '%${query.trim().toLowerCase()}%'},
    );
  }

  Future<List<Map<String, dynamic>>> listPrescriptions({
    String? patientId,
    String? encounterId,
    bool activeOnly = false,
  }) => _rows(
    '''SELECT * FROM prescriptions
            WHERE (@patient::text IS NULL OR patient_id = @patient)
              AND (@encounter::text IS NULL OR encounter_id = @encounter)
              AND (@active = false OR status = 'active')
            ORDER BY start_date DESC''',
    <String, Object?>{
      'patient': patientId,
      'encounter': encounterId,
      'active': activeOnly,
    },
  );

  Future<Map<String, dynamic>?> findPrescription(String id) => _one(
    'SELECT * FROM prescriptions WHERE id = @id',
    <String, Object?>{'id': id},
  );

  Future<Map<String, dynamic>?> savePrescription(
    Map<String, dynamic> body,
  ) async {
    final medication =
        (body['medication'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    await _db.execute(
      Sql.named('''
        INSERT INTO prescriptions (id, patient_id, encounter_id, medication_code,
                                   medication, dose_quantity, dose_unit,
                                   frequency_per_day, route, start_date,
                                   end_date, prescriber, status, is_prn,
                                   indication, instructions)
        VALUES (@id, @patient_id, @encounter_id, @medication_code, @medication,
                @dose_quantity, @dose_unit, @frequency, @route, @start_date,
                @end_date, @prescriber, @status, @is_prn, @indication,
                @instructions)
        ON CONFLICT (id) DO UPDATE SET
          status = EXCLUDED.status,
          end_date = EXCLUDED.end_date,
          instructions = EXCLUDED.instructions'''),
      parameters: <String, Object?>{
        'id': body['id'],
        'patient_id': body['patient_id'],
        'encounter_id': body['encounter_id'],
        'medication_code': medication['code'] ?? '',
        'medication': _jsonb(medication),
        'dose_quantity': (body['dose_quantity'] as num).toDouble(),
        'dose_unit': body['dose_unit'] ?? '',
        'frequency': body['frequency_per_day'] ?? 1,
        'route': body['route'] ?? 'oral',
        'start_date': _timestamp(body['start_date']),
        'end_date': _timestamp(body['end_date']),
        'prescriber': body['prescriber'] ?? '',
        'status': body['status'] ?? 'draft',
        'is_prn': body['is_prn'] == true,
        'indication': body['indication'],
        'instructions': body['instructions'],
      },
    );
    return findPrescription(body['id'].toString());
  }

  Future<List<Map<String, dynamic>>> listDispenses({
    String? patientId,
    String? prescriptionId,
    String? cabinetId,
    String? status,
    int limit = 200,
  }) => _rows(
    '''SELECT * FROM dispenses
            WHERE (@patient::text IS NULL OR patient_id = @patient)
              AND (@prescription::text IS NULL OR prescription_id = @prescription)
              AND (@cabinet::text IS NULL OR cabinet_id = @cabinet)
              AND (@status::text IS NULL OR status = @status)
            ORDER BY requested_at DESC
            LIMIT @limit''',
    <String, Object?>{
      'patient': patientId,
      'prescription': prescriptionId,
      'cabinet': cabinetId,
      'status': status,
      'limit': limit,
    },
  );

  Future<Map<String, dynamic>?> saveDispense(Map<String, dynamic> body) async {
    await _db.execute(
      Sql.named('''
        INSERT INTO dispenses (id, prescription_id, patient_id, quantity, status,
                               requested_at, dispensed_at, dispensed_by,
                               cabinet_id, slot, refusal_reason, lot_number)
        VALUES (@id, @prescription_id, @patient_id, @quantity, @status,
                @requested_at, @dispensed_at, @dispensed_by, @cabinet_id, @slot,
                @refusal_reason, @lot_number)
        ON CONFLICT (id) DO UPDATE SET
          status = EXCLUDED.status,
          dispensed_at = EXCLUDED.dispensed_at,
          dispensed_by = EXCLUDED.dispensed_by,
          refusal_reason = EXCLUDED.refusal_reason,
          lot_number = EXCLUDED.lot_number'''),
      parameters: <String, Object?>{
        'id': body['id'],
        'prescription_id': body['prescription_id'],
        'patient_id': body['patient_id'],
        'quantity': (body['quantity'] as num).toDouble(),
        'status': body['status'] ?? 'requested',
        'requested_at': _timestamp(body['requested_at']),
        'dispensed_at': _timestamp(body['dispensed_at']),
        'dispensed_by': body['dispensed_by'],
        'cabinet_id': body['cabinet_id'],
        'slot': body['slot'],
        'refusal_reason': body['refusal_reason'],
        'lot_number': body['lot_number'],
      },
    );
    return _one('SELECT * FROM dispenses WHERE id = @id', <String, Object?>{
      'id': body['id'],
    });
  }

  // ---- Pharmacy stock ------------------------------------------------------

  Future<List<Map<String, dynamic>>> listCabinets({String? wardId}) => _rows(
    'SELECT * FROM cabinets WHERE (@ward::text IS NULL OR ward_id = @ward) '
    'ORDER BY code',
    <String, Object?>{'ward': wardId},
  );

  Future<Map<String, dynamic>?> findCabinet(String id) => _one(
    'SELECT * FROM cabinets WHERE id = @id',
    <String, Object?>{'id': id},
  );

  Future<Map<String, dynamic>?> saveCabinet(Map<String, dynamic> body) async {
    await _db.execute(
      Sql.named('''
        INSERT INTO cabinets (id, code, name, ward_id, is_locked,
                              temperature_celsius)
        VALUES (@id, @code, @name, @ward_id, @is_locked, @temperature)
        ON CONFLICT (id) DO UPDATE SET
          is_locked = EXCLUDED.is_locked,
          temperature_celsius = EXCLUDED.temperature_celsius'''),
      parameters: <String, Object?>{
        'id': body['id'],
        'code': body['code'],
        'name': _jsonb(body['name']),
        'ward_id': body['ward_id'],
        'is_locked': body['is_locked'] != false,
        'temperature': body['temperature_celsius'],
      },
    );
    return findCabinet(body['id'].toString());
  }

  Future<List<Map<String, dynamic>>> listStock({
    String? cabinetId,
    String? query,
  }) => _rows(
    '''SELECT * FROM stock_items
            WHERE (@cabinet::text IS NULL OR cabinet_id = @cabinet)
              AND (@q::text IS NULL
                   OR lower(medication->'name'->>'en') LIKE @q
                   OR lower(medication->'name'->>'fr') LIKE @q
                   OR lower(medication->'name'->>'nl') LIKE @q
                   OR lower(slot) LIKE @q)
            ORDER BY slot''',
    <String, Object?>{
      'cabinet': cabinetId,
      'q': (query == null || query.trim().isEmpty)
          ? null
          : '%${query.trim().toLowerCase()}%',
    },
  );

  Future<Map<String, dynamic>?> findStockItem(String id) => _one(
    'SELECT * FROM stock_items WHERE id = @id',
    <String, Object?>{'id': id},
  );

  Future<Map<String, dynamic>?> saveStockItem(Map<String, dynamic> body) async {
    final medication =
        (body['medication'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    await _db.execute(
      Sql.named('''
        INSERT INTO stock_items (id, cabinet_id, slot, medication_code,
                                 medication, quantity_on_hand, par_level,
                                 expiry_date, lot_number)
        VALUES (@id, @cabinet_id, @slot, @medication_code, @medication,
                @quantity, @par_level, @expiry, @lot)
        ON CONFLICT (id) DO UPDATE SET
          quantity_on_hand = EXCLUDED.quantity_on_hand,
          expiry_date = EXCLUDED.expiry_date,
          lot_number = EXCLUDED.lot_number'''),
      parameters: <String, Object?>{
        'id': body['id'],
        'cabinet_id': body['cabinet_id'],
        'slot': body['slot'],
        'medication_code': medication['code'] ?? '',
        'medication': _jsonb(medication),
        'quantity': body['quantity_on_hand'] ?? 0,
        'par_level': body['par_level'] ?? 0,
        'expiry': _timestamp(body['expiry_date']),
        'lot': body['lot_number'] ?? '',
      },
    );
    return findStockItem(body['id'].toString());
  }

  // ---- Devices -------------------------------------------------------------

  Future<List<Map<String, dynamic>>> listDevices({String? wardId}) => _rows(
    'SELECT * FROM devices WHERE (@ward::text IS NULL OR ward_id = @ward) '
    'ORDER BY code',
    <String, Object?>{'ward': wardId},
  );

  Future<Map<String, dynamic>?> findDeviceByCode(String code) => _one(
    'SELECT * FROM devices WHERE upper(code) = upper(@code) OR id = @code',
    <String, Object?>{'code': code},
  );

  Future<Map<String, dynamic>?> saveDevice(Map<String, dynamic> body) async {
    await _db.execute(
      Sql.named('''
        INSERT INTO devices (id, code, kind, manufacturer, model, serial_number,
                             status, assigned_patient_id, assigned_bed_id,
                             ward_id, last_seen_at, battery_percent,
                             owner_student)
        VALUES (@id, @code, @kind, @manufacturer, @model, @serial, @status,
                @patient, @bed, @ward, @last_seen, @battery, @owner)
        ON CONFLICT (id) DO UPDATE SET
          status = EXCLUDED.status,
          assigned_patient_id = EXCLUDED.assigned_patient_id,
          assigned_bed_id = EXCLUDED.assigned_bed_id,
          ward_id = EXCLUDED.ward_id,
          last_seen_at = EXCLUDED.last_seen_at,
          battery_percent = EXCLUDED.battery_percent'''),
      parameters: <String, Object?>{
        'id': body['id'],
        'code': body['code'],
        'kind': body['kind'],
        'manufacturer': body['manufacturer'] ?? '',
        'model': body['model'] ?? '',
        'serial': body['serial_number'] ?? '',
        'status': body['status'] ?? 'offline',
        'patient': body['assigned_patient_id'],
        'bed': body['assigned_bed_id'],
        'ward': body['ward_id'],
        'last_seen': _timestamp(body['last_seen_at']),
        'battery': body['battery_percent'],
        'owner': body['owner_student'],
      },
    );
    return findDeviceByCode(body['code'].toString());
  }

  // ---- Notes ---------------------------------------------------------------

  Future<List<Map<String, dynamic>>> listNotes({
    String? patientId,
    String? encounterId,
    String? type,
  }) => _rows(
    '''SELECT * FROM clinical_notes
            WHERE (@patient::text IS NULL OR patient_id = @patient)
              AND (@encounter::text IS NULL OR encounter_id = @encounter)
              AND (@type::text IS NULL OR type = @type)
            ORDER BY created_at DESC''',
    <String, Object?>{
      'patient': patientId,
      'encounter': encounterId,
      'type': type,
    },
  );

  Future<Map<String, dynamic>?> saveNote(Map<String, dynamic> body) async {
    await _db.execute(
      Sql.named('''
        INSERT INTO clinical_notes (id, patient_id, encounter_id, type, title,
                                    body, author_name, author_role, created_at,
                                    updated_at, is_signed, language)
        VALUES (@id, @patient_id, @encounter_id, @type, @title, @body,
                @author_name, @author_role, @created_at, @updated_at,
                @is_signed, @language)
        ON CONFLICT (id) DO UPDATE SET
          type = EXCLUDED.type,
          title = EXCLUDED.title,
          body = EXCLUDED.body,
          updated_at = EXCLUDED.updated_at,
          is_signed = EXCLUDED.is_signed'''),
      parameters: <String, Object?>{
        'id': body['id'],
        'patient_id': body['patient_id'],
        'encounter_id': body['encounter_id'],
        'type': body['type'] ?? 'progress',
        'title': body['title'] ?? '',
        'body': body['body'] ?? '',
        'author_name': body['author_name'] ?? '',
        'author_role': body['author_role'] ?? '',
        'created_at': _timestamp(body['created_at']) ?? DateTime.now(),
        'updated_at': _timestamp(body['updated_at']),
        'is_signed': body['is_signed'] == true,
        'language': body['language'] ?? 'fr',
      },
    );
    return _one(
      'SELECT * FROM clinical_notes WHERE id = @id',
      <String, Object?>{'id': body['id']},
    );
  }

  Future<void> deleteNote(String id) => _db
      .execute(
        Sql.named('DELETE FROM clinical_notes WHERE id = @id'),
        parameters: <String, Object?>{'id': id},
      )
      .then((_) {});

  // ---- Integration ---------------------------------------------------------

  Future<List<Map<String, dynamic>>> listFlows() =>
      _rows('SELECT * FROM integration_flows ORDER BY updated_at DESC');

  Future<Map<String, dynamic>?> findFlow(String id) => _one(
    'SELECT * FROM integration_flows WHERE id = @id',
    <String, Object?>{'id': id},
  );

  Future<Map<String, dynamic>?> saveFlow(Map<String, dynamic> body) async {
    await _db.execute(
      Sql.named('''
        INSERT INTO integration_flows (id, name, description, is_enabled, nodes,
                                       connections, updated_at,
                                       messages_processed, messages_failed)
        VALUES (@id, @name, @description, @is_enabled, @nodes, @connections,
                now(), @processed, @failed)
        ON CONFLICT (id) DO UPDATE SET
          name = EXCLUDED.name,
          description = EXCLUDED.description,
          is_enabled = EXCLUDED.is_enabled,
          nodes = EXCLUDED.nodes,
          connections = EXCLUDED.connections,
          updated_at = now(),
          messages_processed = EXCLUDED.messages_processed,
          messages_failed = EXCLUDED.messages_failed'''),
      parameters: <String, Object?>{
        'id': body['id'],
        'name': _jsonb(body['name']),
        'description': _jsonb(body['description']),
        'is_enabled': body['is_enabled'] != false,
        'nodes': _jsonb(body['nodes'] ?? <dynamic>[]),
        'connections': _jsonb(body['connections'] ?? <dynamic>[]),
        'processed': body['messages_processed'] ?? 0,
        'failed': body['messages_failed'] ?? 0,
      },
    );
    return findFlow(body['id'].toString());
  }

  Future<void> deleteFlow(String id) => _db
      .execute(
        Sql.named('DELETE FROM integration_flows WHERE id = @id'),
        parameters: <String, Object?>{'id': id},
      )
      .then((_) {});

  Future<List<Map<String, dynamic>>> listMessages({
    String? flowId,
    String? status,
    int limit = 100,
  }) => _rows(
    '''SELECT * FROM integration_messages
            WHERE (@flow::text IS NULL OR flow_id = @flow)
              AND (@status::text IS NULL OR status = @status)
            ORDER BY received_at DESC
            LIMIT @limit''',
    <String, Object?>{'flow': flowId, 'status': status, 'limit': limit},
  );

  Future<Map<String, dynamic>?> saveMessage(Map<String, dynamic> body) async {
    await _db.execute(
      Sql.named('''
        INSERT INTO integration_messages (id, message_type, source_app,
                                          target_app, flow_id, patient_id,
                                          payload, trace, status, received_at,
                                          processed_at, error)
        VALUES (@id, @message_type, @source_app, @target_app, @flow_id,
                @patient_id, @payload, @trace, @status, @received_at,
                @processed_at, @error)
        ON CONFLICT (id) DO UPDATE SET
          target_app = EXCLUDED.target_app,
          flow_id = EXCLUDED.flow_id,
          trace = EXCLUDED.trace,
          status = EXCLUDED.status,
          processed_at = EXCLUDED.processed_at,
          error = EXCLUDED.error'''),
      parameters: <String, Object?>{
        'id': body['id'],
        'message_type': body['message_type'] ?? 'unknown',
        'source_app': body['source_app'] ?? 'unknown',
        'target_app': body['target_app'],
        'flow_id': body['flow_id'],
        'patient_id': body['patient_id'],
        'payload': _jsonb(body['payload'] ?? <String, dynamic>{}),
        'trace': _jsonb(body['trace'] ?? <dynamic>[]),
        'status': body['status'] ?? 'received',
        'received_at': _timestamp(body['received_at']) ?? DateTime.now(),
        'processed_at': _timestamp(body['processed_at']),
        'error': body['error'],
      },
    );
    return _one(
      'SELECT * FROM integration_messages WHERE id = @id',
      <String, Object?>{'id': body['id']},
    );
  }

  // ---- Coercion ------------------------------------------------------------

  /// jsonb parameters must be sent as text and cast, not as a Dart Map.
  static Object? _jsonb(Object? value) =>
      value == null ? null : TypedValue(Type.json, jsonEncode(value));

  static DateTime? _timestamp(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static DateTime? _dateOnly(Object? value) {
    final parsed = _timestamp(value);
    return parsed == null
        ? null
        : DateTime.utc(parsed.year, parsed.month, parsed.day);
  }
}
