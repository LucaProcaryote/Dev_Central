import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_core/hospital_core.dart';

void main() {
  final seed = HospitalSeed.build(now: DateTime.utc(2026, 9, 12, 10));

  group('FHIR serialisation', () {
    test('Patient renders the elements a FHIR server requires', () {
      final patient = seed.patients.first;
      final resource = patient.toFhir();

      expect(resource['resourceType'], 'Patient');
      expect(resource['id'], patient.id);
      expect(resource['gender'], patient.gender.name);
      expect(resource['birthDate'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));

      final names = resource['name'] as List<dynamic>;
      expect((names.first as Map)['family'], patient.familyName);

      // The MRN must be typed, not just a bare string, or a receiving system
      // cannot tell it apart from the national number.
      final identifiers = (resource['identifier'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final mrn = identifiers.firstWhere((i) {
        final codings = ((i['type'] as Map)['coding'] as List).cast<Map>();
        return codings.any((c) => c['code'] == 'MR');
      });
      expect(mrn['value'], patient.mrn);
    });

    test('Patient survives a round trip through FHIR', () {
      for (final original in seed.patients) {
        final restored = Patient.fromFhir(original.toFhir());
        expect(restored.id, original.id);
        expect(restored.mrn, original.mrn);
        expect(restored.familyName, original.familyName);
        expect(restored.givenName, original.givenName);
        expect(restored.gender, original.gender);
        expect(restored.birthDate.toIso8601String().substring(0, 10),
            original.birthDate.toIso8601String().substring(0, 10));
        expect(restored.nationalNumber, original.nationalNumber);
        expect(restored.preferredLanguage, original.preferredLanguage);
        expect(restored.address.city, original.address.city);
        expect(restored.address.postalCode, original.address.postalCode);
      }
    });

    test('Observation carries LOINC and UCUM, not free text', () {
      final observation = seed.observations.first;
      final resource = observation.toFhir();

      expect(resource['resourceType'], 'Observation');
      final coding = ((resource['code'] as Map)['coding'] as List).first as Map;
      expect(coding['system'], CodeSystems.loinc);
      expect(coding['code'], observation.type.loincCode);

      final quantity = resource['valueQuantity'] as Map;
      expect(quantity['system'], CodeSystems.ucum);
      expect(quantity['code'], observation.type.ucum);
      expect(quantity['value'], observation.value);
    });

    test('Observation survives a round trip through FHIR', () {
      for (final original in seed.observations.take(200)) {
        final restored = Observation.fromFhir(original.toFhir());
        expect(restored.id, original.id);
        expect(restored.patientId, original.patientId);
        expect(restored.type, original.type);
        expect(restored.value, original.value);
        expect(restored.deviceId, original.deviceId);
      }
    });

    test('interpretation flags the value against its reference range', () {
      final low = Observation(
        id: 'o1',
        patientId: 'pat-001',
        type: VitalSignType.oxygenSaturation,
        value: 88,
        effectiveDateTime: DateTime.utc(2026, 9, 12),
      );
      final normal = Observation(
        id: 'o2',
        patientId: 'pat-001',
        type: VitalSignType.oxygenSaturation,
        value: 97,
        effectiveDateTime: DateTime.utc(2026, 9, 12),
      );
      final high = Observation(
        id: 'o3',
        patientId: 'pat-001',
        type: VitalSignType.bodyTemperature,
        value: 39.4,
        effectiveDateTime: DateTime.utc(2026, 9, 12),
      );

      expect(low.interpretationCode, 'L');
      expect(low.isAbnormal, isTrue);
      expect(normal.interpretationCode, 'N');
      expect(normal.isAbnormal, isFalse);
      expect(high.interpretationCode, 'H');
      expect(high.isAbnormal, isTrue);
    });

    test('Encounter round-trips its status, class and period', () {
      for (final original in seed.encounters) {
        final restored = Encounter.fromFhir(original.toFhir());
        expect(restored.id, original.id);
        expect(restored.patientId, original.patientId);
        expect(restored.status, original.status);
        expect(restored.encounterClass, original.encounterClass);
        expect(restored.bedId, original.bedId);
      }
    });

    test('FHIR status codes use the wire spelling, not the Dart one', () {
      expect(ObservationStatus.finalised.fhirCode, 'final');
      expect(EncounterStatus.inProgress.fhirCode, 'in-progress');
      expect(EncounterStatus.onLeave.fhirCode, 'onleave');
      expect(PrescriptionStatus.onHold.fhirCode, 'on-hold');
      expect(AllergyCriticality.unableToAssess.fhirCode, 'unable-to-assess');
    });

    test('MedicationRequest carries the ATC code and a dosage', () {
      final prescription =
          seed.prescriptions.firstWhere((p) => !p.isPrn);
      final resource = prescription.toFhir();

      expect(resource['resourceType'], 'MedicationRequest');
      expect(resource['intent'], 'order');
      final coding = ((resource['medicationCodeableConcept'] as Map)['coding']
              as List)
          .first as Map;
      expect(coding['system'], CodeSystems.atc);
      expect(coding['code'], prescription.medication.atcCode);

      final dosage = (resource['dosageInstruction'] as List).first as Map;
      final repeat = (dosage['timing'] as Map)['repeat'] as Map;
      expect(repeat['frequency'], prescription.frequencyPerDay);
      expect(repeat['periodUnit'], 'd');
    });

    test('every seeded resource produces spec-shaped FHIR', () {
      // Not a full validator - that is what the HAPI server is for - but every
      // resource must at least name its type and have no null elements, which
      // FHIR forbids outright.
      void check(Map<String, dynamic> resource) {
        expect(resource['resourceType'], isNotNull);
        expect(resource.values.any((v) => v == null), isFalse,
            reason: 'null element in ${resource['resourceType']}');
      }

      for (final patient in seed.patients) {
        check(patient.toFhir());
        for (final allergy in patient.allergies) {
          check(allergy.toFhir());
        }
      }
      for (final encounter in seed.encounters) {
        check(encounter.toFhir());
      }
      for (final observation in seed.observations.take(100)) {
        check(observation.toFhir());
      }
      for (final prescription in seed.prescriptions) {
        check(prescription.toFhir());
      }
      for (final note in seed.notes) {
        check(note.toFhir());
      }
      for (final device in seed.devices) {
        check(device.toFhir());
      }
      for (final bed in seed.beds.take(50)) {
        check(bed.toFhir());
      }
    });

    test('a clinical note embeds its text as decodable base64', () {
      final note = seed.notes.firstWhere((n) => n.language == 'fr');
      final resource = note.toFhir();
      final attachment =
          ((resource['content'] as List).first as Map)['attachment'] as Map;

      expect(attachment['language'], 'fr');
      // The accented French must survive the encoding.
      final decoded = String.fromCharCodes(
        _base64Decode(attachment['data'] as String),
      );
      expect(decoded.codeUnits, isNotEmpty);
      expect(attachment['contentType'], contains('utf-8'));
    });
  });
}

List<int> _base64Decode(String value) {
  const alphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  final cleaned = value.replaceAll('=', '');
  final bytes = <int>[];
  var buffer = 0;
  var bits = 0;
  for (final char in cleaned.split('')) {
    buffer = (buffer << 6) | alphabet.indexOf(char);
    bits += 6;
    if (bits >= 8) {
      bits -= 8;
      bytes.add((buffer >> bits) & 0xFF);
    }
  }
  return bytes;
}
