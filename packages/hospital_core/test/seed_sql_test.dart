@Tags(<String>['tool'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_core/hospital_core.dart';

/// Generates `infrastructure/db/seed.sql` from the Dart seed dataset, and
/// fails if the committed file has drifted from it.
///
/// The SQL seed and the in-memory seed have to be the same hospital, or a
/// student switching `BACKEND=restApi` finds different patients and reasonably
/// concludes the software is broken. Generating one from the other and
/// checking it in CI is the only way to keep that true.
///
/// To regenerate after changing the Dart seed:
///
///     UPDATE_SEED_SQL=1 flutter test test/seed_sql_test.dart
void main() {
  // A fixed reference instant. Timestamps are written relative to it as
  // `now() + interval '<n> seconds'`, so the seeded hospital is always as
  // current as the in-memory one rather than frozen on the day it was
  // generated.
  final reference = DateTime.utc(2026, 1, 1, 12);
  final seed = HospitalSeed.build(now: reference);

  test('the committed seed.sql matches the Dart dataset', () {
    final sql = _generate(seed, reference);
    final file = File(_seedPath());

    if (Platform.environment['UPDATE_SEED_SQL'] == '1') {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(sql);
      // ignore: avoid_print
      print('Wrote ${file.path} (${sql.split('\n').length} lines)');
      return;
    }

    expect(
      file.existsSync(),
      isTrue,
      reason: 'run: UPDATE_SEED_SQL=1 flutter test test/seed_sql_test.dart',
    );
    expect(
      file.readAsStringSync(),
      sql,
      reason: 'seed.sql is out of date with the Dart seed. Regenerate it:\n'
          '  UPDATE_SEED_SQL=1 flutter test test/seed_sql_test.dart',
    );
  });
}

/// The generator only runs from inside Dev_Central, which owns the canonical
/// package and the infrastructure directory beside it.
String _seedPath() => '${Directory.current.path}/../../infrastructure/db/seed.sql';

// ---------------------------------------------------------------------------
// SQL emission
// ---------------------------------------------------------------------------

String _quote(Object? value) {
  if (value == null) return 'NULL';
  if (value is bool) return value ? 'true' : 'false';
  if (value is num) return '$value';
  return "'${value.toString().replaceAll("'", "''")}'";
}

String _json(Object? value) =>
    value == null ? 'NULL' : "${_quote(jsonEncode(value))}::jsonb";

/// Writes a timestamp as an offset from the moment the seed is loaded.
String _at(DateTime? value, DateTime reference) {
  if (value == null) return 'NULL';
  final seconds = value.difference(reference).inSeconds;
  if (seconds == 0) return 'now()';
  final sign = seconds < 0 ? '-' : '+';
  return "now() $sign interval '${seconds.abs()} seconds'";
}

String _date(DateTime value) => "'${value.toIso8601String().substring(0, 10)}'";

String _textArray(List<String> values) =>
    values.isEmpty ? "'{}'" : "ARRAY[${values.map(_quote).join(', ')}]";

String _generate(HospitalSeed seed, DateTime reference) {
  final out = StringBuffer();

  out.writeln('-- Mini-Hospital 2026 - seed data');
  out.writeln('--');
  out.writeln('-- GENERATED FILE. Do not edit by hand.');
  out.writeln('-- Source: packages/hospital_core/lib/src/seed/, in Dev_Central.');
  out.writeln('-- Regenerate: UPDATE_SEED_SQL=1 flutter test test/seed_sql_test.dart');
  out.writeln('--');
  out.writeln('-- Every patient, address, telephone number and national register');
  out.writeln('-- number here is invented. The NISS check digits are computed');
  out.writeln('-- correctly so format validation has something honest to work on,');
  out.writeln('-- but the numbers belong to nobody.');
  out.writeln('--');
  out.writeln('-- Timestamps are written relative to load time, so the hospital is');
  out.writeln('-- always as current as the in-memory dataset rather than frozen on');
  out.writeln('-- the day this file was generated.');
  out.writeln();
  out.writeln('BEGIN;');
  out.writeln();

  // Loading twice must not double the hospital.
  out.writeln('-- Idempotent: loading this file twice leaves one hospital, not two.');
  out.writeln('TRUNCATE TABLE integration_messages, integration_flows, devices,');
  out.writeln('               dispenses, stock_items, cabinets, clinical_notes,');
  out.writeln('               prescriptions, observations, movements, encounters,');
  out.writeln('               allergies, patients, staff, medications, beds, rooms,');
  out.writeln('               wards RESTART IDENTITY CASCADE;');
  out.writeln();

  void section(String title) {
    out.writeln();
    out.writeln('-- ${'-' * 74}');
    out.writeln('-- $title');
    out.writeln('-- ${'-' * 74}');
  }

  section('Wards, rooms and beds');
  for (final ward in seed.wards) {
    out.writeln(
      'INSERT INTO wards (id, code, name, floor, specialty, phone_extension) '
      'VALUES (${_quote(ward.id)}, ${_quote(ward.code)}, ${_json(ward.name.toJson())}, '
      '${ward.floor}, ${_json(ward.specialty.toJson())}, ${_quote(ward.phoneExtension)});',
    );
  }
  out.writeln();
  for (final room in seed.rooms) {
    out.writeln(
      'INSERT INTO rooms (id, ward_id, number, is_isolation) '
      'VALUES (${_quote(room.id)}, ${_quote(room.wardId)}, ${_quote(room.number)}, '
      '${_quote(room.isIsolation)});',
    );
  }
  out.writeln();
  // Beds are inserted free; occupancy is set after the encounters exist,
  // because the consistency constraint requires the occupant to be named.
  for (final bed in seed.beds) {
    final status = bed.status == BedStatus.occupied ? 'free' : bed.status.name;
    out.writeln(
      'INSERT INTO beds (id, room_id, ward_id, label, status) '
      'VALUES (${_quote(bed.id)}, ${_quote(bed.roomId)}, ${_quote(bed.wardId)}, '
      '${_quote(bed.label)}, ${_quote(status)});',
    );
  }

  section('Staff');
  for (final user in seed.users) {
    out.writeln(
      'INSERT INTO staff (uid, email, display_name, role, ward_ids, '
      'preferred_language, registration_number) '
      'VALUES (${_quote(user.uid)}, ${_quote(user.email)}, ${_quote(user.displayName)}, '
      '${_quote(user.role.name)}, ${_textArray(user.wardIds)}, '
      '${_quote(user.preferredLanguage)}, ${_quote(user.registrationNumber)});',
    );
  }

  section('Formulary');
  for (final medication in seed.formulary) {
    out.writeln(
      'INSERT INTO medications (code, name, form, strength, atc_code, is_controlled) '
      'VALUES (${_quote(medication.code)}, ${_json(medication.name.toJson())}, '
      '${_json(medication.form.toJson())}, ${_quote(medication.strength)}, '
      '${_quote(medication.atcCode)}, ${_quote(medication.isControlled)});',
    );
  }

  section('Patients');
  for (final patient in seed.patients) {
    out.writeln(
      'INSERT INTO patients (id, mrn, national_number, family_name, given_name, '
      'gender, birth_date, address, phone, email, preferred_language, blood_group, '
      'general_practitioner, deceased_date) VALUES ('
      '${_quote(patient.id)}, ${_quote(patient.mrn)}, ${_quote(patient.nationalNumber)}, '
      '${_quote(patient.familyName)}, ${_quote(patient.givenName)}, '
      '${_quote(patient.gender.name)}, ${_date(patient.birthDate)}, '
      '${_json(patient.address.toJson())}, ${_quote(patient.phone)}, '
      '${_quote(patient.email)}, ${_quote(patient.preferredLanguage)}, '
      '${_quote(patient.bloodGroup)}, ${_quote(patient.generalPractitioner)}, '
      '${_at(patient.deceasedDate, reference)});',
    );
  }

  section('Allergies');
  for (final allergy in seed.patients.expand((p) => p.allergies)) {
    out.writeln(
      'INSERT INTO allergies (id, patient_id, substance, reaction, criticality, '
      'recorded_date) VALUES (${_quote(allergy.id)}, ${_quote(allergy.patientId)}, '
      '${_json(allergy.substance.toJson())}, ${_json(allergy.reaction.toJson())}, '
      '${_quote(allergy.criticality.fhirCode)}, ${_at(allergy.recordedDate, reference)});',
    );
  }

  section('Encounters and movements');
  for (final encounter in seed.encounters) {
    out.writeln(
      'INSERT INTO encounters (id, patient_id, status, encounter_class, '
      'admission_date, discharge_date, ward_id, room_id, bed_id, '
      'admitting_practitioner, attending_practitioner, reason, '
      'discharge_disposition, visit_number) VALUES ('
      '${_quote(encounter.id)}, ${_quote(encounter.patientId)}, '
      '${_quote(encounter.status.fhirCode)}, ${_quote(encounter.encounterClass.code)}, '
      '${_at(encounter.admissionDate, reference)}, '
      '${_at(encounter.dischargeDate, reference)}, ${_quote(encounter.wardId)}, '
      '${_quote(encounter.roomId)}, ${_quote(encounter.bedId)}, '
      '${_quote(encounter.admittingPractitioner)}, '
      '${_quote(encounter.attendingPractitioner)}, ${_quote(encounter.reason)}, '
      '${_quote(encounter.dischargeDisposition)}, ${_quote(encounter.visitNumber)});',
    );
  }
  out.writeln();
  for (final movement in seed.movements.reversed) {
    out.writeln(
      'INSERT INTO movements (id, encounter_id, patient_id, type, occurred_at, '
      'performed_by, from_ward_id, from_bed_id, to_ward_id, to_bed_id, note) VALUES ('
      '${_quote(movement.id)}, ${_quote(movement.encounterId)}, '
      '${_quote(movement.patientId)}, ${_quote(movement.type.name)}, '
      '${_at(movement.occurredAt, reference)}, ${_quote(movement.performedBy)}, '
      '${_quote(movement.fromWardId)}, ${_quote(movement.fromBedId)}, '
      '${_quote(movement.toWardId)}, ${_quote(movement.toBedId)}, '
      '${_quote(movement.note)});',
    );
  }

  out.writeln();
  out.writeln('-- Now that the encounters exist, mark the occupied beds. Doing this');
  out.writeln('-- as an UPDATE derived from the encounters - rather than as literals -');
  out.writeln('-- means the bed board and the patient list cannot disagree.');
  out.writeln('''UPDATE beds b
   SET status = 'occupied',
       current_encounter_id = e.id,
       current_patient_id = e.patient_id
  FROM encounters e
 WHERE e.bed_id = b.id
   AND e.status IN ('in-progress', 'onleave');''');

  section('Observations');
  for (final observation in seed.observations.reversed) {
    out.writeln(
      'INSERT INTO observations (id, patient_id, encounter_id, type, value, unit, '
      'effective_date_time, device_id, performer, status) VALUES ('
      '${_quote(observation.id)}, ${_quote(observation.patientId)}, '
      '${_quote(observation.encounterId)}, ${_quote(observation.type.name)}, '
      '${observation.value}, ${_quote(observation.type.unit)}, '
      '${_at(observation.effectiveDateTime, reference)}, '
      '${_quote(observation.deviceId)}, ${_quote(observation.performer)}, '
      '${_quote(observation.status.fhirCode)});',
    );
  }

  section('Prescriptions');
  for (final prescription in seed.prescriptions) {
    out.writeln(
      'INSERT INTO prescriptions (id, patient_id, encounter_id, medication_code, '
      'medication, dose_quantity, dose_unit, frequency_per_day, route, start_date, '
      'end_date, prescriber, status, is_prn, indication, instructions) VALUES ('
      '${_quote(prescription.id)}, ${_quote(prescription.patientId)}, '
      '${_quote(prescription.encounterId)}, ${_quote(prescription.medication.code)}, '
      '${_json(prescription.medication.toJson())}, ${prescription.doseQuantity}, '
      '${_quote(prescription.doseUnit)}, ${prescription.frequencyPerDay}, '
      '${_quote(prescription.route.name)}, ${_at(prescription.startDate, reference)}, '
      '${_at(prescription.endDate, reference)}, ${_quote(prescription.prescriber)}, '
      '${_quote(prescription.status.fhirCode)}, ${_quote(prescription.isPrn)}, '
      '${_quote(prescription.indication)}, ${_quote(prescription.instructions)});',
    );
  }

  section('Clinical notes');
  for (final note in seed.notes) {
    out.writeln(
      'INSERT INTO clinical_notes (id, patient_id, encounter_id, type, title, body, '
      'author_name, author_role, created_at, updated_at, is_signed, language) VALUES ('
      '${_quote(note.id)}, ${_quote(note.patientId)}, ${_quote(note.encounterId)}, '
      '${_quote(note.type.name)}, ${_quote(note.title)}, ${_quote(note.body)}, '
      '${_quote(note.authorName)}, ${_quote(note.authorRole)}, '
      '${_at(note.createdAt, reference)}, ${_at(note.updatedAt, reference)}, '
      '${_quote(note.isSigned)}, ${_quote(note.language)});',
    );
  }

  section('Pharmacy');
  for (final cabinet in seed.cabinets) {
    out.writeln(
      'INSERT INTO cabinets (id, code, name, ward_id, is_locked, temperature_celsius) '
      'VALUES (${_quote(cabinet.id)}, ${_quote(cabinet.code)}, '
      '${_json(cabinet.name.toJson())}, ${_quote(cabinet.wardId)}, '
      '${_quote(cabinet.isLocked)}, ${cabinet.temperatureCelsius ?? 'NULL'});',
    );
  }
  out.writeln();
  for (final item in seed.stock) {
    out.writeln(
      'INSERT INTO stock_items (id, cabinet_id, slot, medication_code, medication, '
      'quantity_on_hand, par_level, expiry_date, lot_number) VALUES ('
      '${_quote(item.id)}, ${_quote(item.cabinetId)}, ${_quote(item.slot)}, '
      '${_quote(item.medication.code)}, ${_json(item.medication.toJson())}, '
      '${item.quantityOnHand}, ${item.parLevel}, ${_at(item.expiryDate, reference)}, '
      '${_quote(item.lotNumber)});',
    );
  }
  out.writeln();
  for (final dispense in seed.dispenses.reversed) {
    out.writeln(
      'INSERT INTO dispenses (id, prescription_id, patient_id, quantity, status, '
      'requested_at, dispensed_at, dispensed_by, cabinet_id, slot, refusal_reason, '
      'lot_number) VALUES ('
      '${_quote(dispense.id)}, ${_quote(dispense.prescriptionId)}, '
      '${_quote(dispense.patientId)}, ${dispense.quantity}, '
      '${_quote(dispense.status.name)}, ${_at(dispense.requestedAt, reference)}, '
      '${_at(dispense.dispensedAt, reference)}, ${_quote(dispense.dispensedBy)}, '
      '${_quote(dispense.cabinetId)}, ${_quote(dispense.slot)}, '
      '${_quote(dispense.refusalReason)}, ${_quote(dispense.lotNumber)});',
    );
  }

  section('Devices');
  for (final device in seed.devices) {
    out.writeln(
      'INSERT INTO devices (id, code, kind, manufacturer, model, serial_number, '
      'status, assigned_patient_id, assigned_bed_id, ward_id, last_seen_at, '
      'battery_percent, owner_student) VALUES ('
      '${_quote(device.id)}, ${_quote(device.code)}, ${_quote(device.kind.name)}, '
      '${_quote(device.manufacturer)}, ${_quote(device.model)}, '
      '${_quote(device.serialNumber)}, ${_quote(device.status.name)}, '
      '${_quote(device.assignedPatientId)}, ${_quote(device.assignedBedId)}, '
      '${_quote(device.wardId)}, ${_at(device.lastSeenAt, reference)}, '
      '${device.batteryPercent ?? 'NULL'}, ${_quote(device.ownerStudent)});',
    );
  }

  section('Integration flows');
  for (final flow in seed.flows) {
    out.writeln(
      'INSERT INTO integration_flows (id, name, description, is_enabled, nodes, '
      'connections, updated_at, messages_processed, messages_failed) VALUES ('
      '${_quote(flow.id)}, ${_json(flow.name.toJson())}, '
      '${_json(flow.description.toJson())}, ${_quote(flow.isEnabled)}, '
      '${_json(flow.nodes.map((n) => n.toJson()).toList())}, '
      '${_json(flow.connections.map((c) => c.toJson()).toList())}, '
      '${_at(flow.updatedAt, reference)}, ${flow.messagesProcessed}, '
      '${flow.messagesFailed});',
    );
  }

  out.writeln();
  out.writeln('COMMIT;');
  return out.toString();
}
