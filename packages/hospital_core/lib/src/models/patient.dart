import 'package:flutter/foundation.dart';

import '../util/json.dart';
import '../util/localized_text.dart';
import 'codes.dart';

/// A recorded allergy or intolerance (FHIR `AllergyIntolerance`).
@immutable
class Allergy {
  const Allergy({
    required this.id,
    required this.patientId,
    required this.substance,
    required this.reaction,
    required this.criticality,
    required this.recordedDate,
  });

  final String id;
  final String patientId;

  /// Substance name. Kept trilingual because "peanut" must read "arachide" for
  /// a francophone nurse scanning an allergy banner in a hurry.
  final LocalizedText substance;
  final LocalizedText reaction;
  final AllergyCriticality criticality;
  final DateTime recordedDate;

  factory Allergy.fromJson(Map<String, dynamic> json) => Allergy(
    id: asString(json['id']),
    patientId: asString(json['patient_id'] ?? json['patientId']),
    substance: LocalizedText.fromJson(json['substance']),
    reaction: LocalizedText.fromJson(json['reaction']),
    criticality: AllergyCriticality.fromFhir(asString(json['criticality'])),
    recordedDate: asDateTime(json['recorded_date'] ?? json['recordedDate']),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'patient_id': patientId,
    'substance': substance.toJson(),
    'reaction': reaction.toJson(),
    'criticality': criticality.fhirCode,
    'recorded_date': recordedDate.toIso8601String(),
  };

  /// Renders this allergy as a FHIR R4 `AllergyIntolerance` resource.
  Map<String, dynamic> toFhir() => pruneNulls(<String, dynamic>{
    'resourceType': 'AllergyIntolerance',
    'id': id,
    'clinicalStatus': <String, dynamic>{
      'coding': <dynamic>[
        <String, dynamic>{
          'system':
              'http://terminology.hl7.org/CodeSystem/allergyintolerance-clinical',
          'code': 'active',
        },
      ],
    },
    'criticality': criticality.fhirCode,
    'code': <String, dynamic>{'text': substance.en},
    'patient': <String, dynamic>{'reference': 'Patient/$patientId'},
    'recordedDate': toFhirDateTime(recordedDate),
    'reaction': <dynamic>[
      <String, dynamic>{
        'manifestation': <dynamic>[
          <String, dynamic>{'text': reaction.en},
        ],
      },
    ],
  });
}

/// A postal address.
@immutable
class Address {
  const Address({
    required this.line,
    required this.city,
    required this.postalCode,
    this.country = 'BE',
  });

  final String line;
  final String city;
  final String postalCode;
  final String country;

  factory Address.fromJson(Map<String, dynamic> json) => Address(
    line: asString(json['line']),
    city: asString(json['city']),
    postalCode: asString(json['postal_code'] ?? json['postalCode']),
    country: asString(json['country'], fallback: 'BE'),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'line': line,
    'city': city,
    'postal_code': postalCode,
    'country': country,
  };

  Map<String, dynamic> toFhir() => <String, dynamic>{
    'line': <dynamic>[line],
    'city': city,
    'postalCode': postalCode,
    'country': country,
  };

  String get oneLine => '$line, $postalCode $city';

  @override
  String toString() => oneLine;
}

/// A patient of the mini-hospital (FHIR `Patient`).
@immutable
class Patient {
  const Patient({
    required this.id,
    required this.mrn,
    required this.familyName,
    required this.givenName,
    required this.gender,
    required this.birthDate,
    required this.address,
    this.nationalNumber,
    this.phone,
    this.email,
    this.preferredLanguage = 'fr',
    this.bloodGroup,
    this.allergies = const <Allergy>[],
    this.generalPractitioner,
    this.deceasedDate,
    this.photoUrl,
  });

  final String id;

  /// Medical record number - the identifier humans quote to each other.
  final String mrn;

  /// Belgian national register number (NISS/INSZ). Fictive, but well-formed.
  final String? nationalNumber;

  final String familyName;
  final String givenName;
  final AdministrativeGender gender;
  final DateTime birthDate;
  final Address address;
  final String? phone;
  final String? email;

  /// `en`, `fr` or `nl` - the language this patient should be addressed in.
  /// Drives the language of printed documents, independent of the language the
  /// clinician has selected for the interface.
  final String preferredLanguage;

  final String? bloodGroup;
  final List<Allergy> allergies;
  final String? generalPractitioner;
  final DateTime? deceasedDate;
  final String? photoUrl;

  String get fullName => '$givenName $familyName';

  /// Family name first, which is how ward lists and search results are sorted.
  String get listName => '${familyName.toUpperCase()}, $givenName';

  bool get isDeceased => deceasedDate != null;

  /// Age in completed years at [on] (default: today).
  int ageAt([DateTime? on]) {
    final reference = deceasedDate ?? on ?? DateTime.now();
    var age = reference.year - birthDate.year;
    final hadBirthday =
        reference.month > birthDate.month ||
        (reference.month == birthDate.month && reference.day >= birthDate.day);
    if (!hadBirthday) age--;
    return age < 0 ? 0 : age;
  }

  bool get hasHighRiskAllergy =>
      allergies.any((a) => a.criticality == AllergyCriticality.high);

  /// Initials for the avatar placeholder.
  String get initials {
    final g = givenName.isNotEmpty ? givenName[0] : '';
    final f = familyName.isNotEmpty ? familyName[0] : '';
    return '$g$f'.toUpperCase();
  }

  Patient copyWith({
    String? mrn,
    String? familyName,
    String? givenName,
    AdministrativeGender? gender,
    DateTime? birthDate,
    Address? address,
    String? nationalNumber,
    String? phone,
    String? email,
    String? preferredLanguage,
    String? bloodGroup,
    List<Allergy>? allergies,
    String? generalPractitioner,
    DateTime? deceasedDate,
    String? photoUrl,
  }) => Patient(
    id: id,
    mrn: mrn ?? this.mrn,
    familyName: familyName ?? this.familyName,
    givenName: givenName ?? this.givenName,
    gender: gender ?? this.gender,
    birthDate: birthDate ?? this.birthDate,
    address: address ?? this.address,
    nationalNumber: nationalNumber ?? this.nationalNumber,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    bloodGroup: bloodGroup ?? this.bloodGroup,
    allergies: allergies ?? this.allergies,
    generalPractitioner: generalPractitioner ?? this.generalPractitioner,
    deceasedDate: deceasedDate ?? this.deceasedDate,
    photoUrl: photoUrl ?? this.photoUrl,
  );

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
    id: asString(json['id']),
    mrn: asString(json['mrn']),
    nationalNumber: asStringOrNull(
      json['national_number'] ?? json['nationalNumber'],
    ),
    familyName: asString(json['family_name'] ?? json['familyName']),
    givenName: asString(json['given_name'] ?? json['givenName']),
    gender: AdministrativeGender.fromFhir(asString(json['gender'])),
    birthDate: asDateTime(json['birth_date'] ?? json['birthDate']),
    address: Address.fromJson(
      (json['address'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
    ),
    phone: asStringOrNull(json['phone']),
    email: asStringOrNull(json['email']),
    preferredLanguage: asString(
      json['preferred_language'] ?? json['preferredLanguage'],
      fallback: 'fr',
    ),
    bloodGroup: asStringOrNull(json['blood_group'] ?? json['bloodGroup']),
    allergies: asMapList(json['allergies']).map(Allergy.fromJson).toList(),
    generalPractitioner: asStringOrNull(
      json['general_practitioner'] ?? json['generalPractitioner'],
    ),
    deceasedDate: asDateTimeOrNull(
      json['deceased_date'] ?? json['deceasedDate'],
    ),
    photoUrl: asStringOrNull(json['photo_url'] ?? json['photoUrl']),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'mrn': mrn,
    'national_number': nationalNumber,
    'family_name': familyName,
    'given_name': givenName,
    'gender': gender.name,
    'birth_date': toFhirDate(birthDate),
    'address': address.toJson(),
    'phone': phone,
    'email': email,
    'preferred_language': preferredLanguage,
    'blood_group': bloodGroup,
    'allergies': allergies.map((a) => a.toJson()).toList(),
    'general_practitioner': generalPractitioner,
    'deceased_date': deceasedDate?.toIso8601String(),
    'photo_url': photoUrl,
  };

  /// Renders this patient as a FHIR R4 `Patient` resource.
  Map<String, dynamic> toFhir() => pruneNulls(<String, dynamic>{
    'resourceType': 'Patient',
    'id': id,
    'identifier': <dynamic>[
      <String, dynamic>{
        'use': 'usual',
        'type': <String, dynamic>{
          'coding': <dynamic>[
            <String, dynamic>{
              'system': CodeSystems.identifierType,
              'code': 'MR',
              'display': 'Medical record number',
            },
          ],
        },
        'system': 'http://mini-hospital.example.org/mrn',
        'value': mrn,
      },
      if (nationalNumber != null)
        <String, dynamic>{
          'use': 'official',
          'type': <String, dynamic>{
            'coding': <dynamic>[
              <String, dynamic>{
                'system': CodeSystems.identifierType,
                'code': 'NI',
                'display': 'National unique individual identifier',
              },
            ],
          },
          'system': 'urn:oid:2.16.56.1.1.1.1', // Belgian NISS
          'value': nationalNumber,
        },
    ],
    'active': !isDeceased,
    'name': <dynamic>[
      <String, dynamic>{
        'use': 'official',
        'family': familyName,
        'given': <dynamic>[givenName],
      },
    ],
    'telecom': <dynamic>[
      if (phone != null)
        <String, dynamic>{'system': 'phone', 'value': phone, 'use': 'home'},
      if (email != null) <String, dynamic>{'system': 'email', 'value': email},
    ],
    'gender': gender.name,
    'birthDate': toFhirDate(birthDate),
    if (deceasedDate != null) 'deceasedDateTime': toFhirDateTime(deceasedDate!),
    'address': <dynamic>[address.toFhir()],
    'communication': <dynamic>[
      <String, dynamic>{
        'language': <String, dynamic>{
          'coding': <dynamic>[
            <String, dynamic>{
              'system': 'urn:ietf:bcp:47',
              'code': preferredLanguage,
            },
          ],
        },
        'preferred': true,
      },
    ],
  });

  /// Parses a FHIR R4 `Patient` resource coming back from the HAPI server.
  factory Patient.fromFhir(Map<String, dynamic> resource) {
    final identifiers = asMapList(resource['identifier']);
    String? findIdentifier(String typeCode) {
      for (final identifier in identifiers) {
        final codings = asMapList((identifier['type'] as Map?)?['coding']);
        if (codings.any((c) => c['code'] == typeCode)) {
          return asStringOrNull(identifier['value']);
        }
      }
      return null;
    }

    final names = asMapList(resource['name']);
    final name = names.isNotEmpty ? names.first : const <String, dynamic>{};
    final givens = asStringList(name['given']);

    final telecoms = asMapList(resource['telecom']);
    String? findTelecom(String system) {
      for (final telecom in telecoms) {
        if (telecom['system'] == system) {
          return asStringOrNull(telecom['value']);
        }
      }
      return null;
    }

    final addresses = asMapList(resource['address']);
    final addr = addresses.isNotEmpty
        ? addresses.first
        : const <String, dynamic>{};

    final communications = asMapList(resource['communication']);
    String language = 'fr';
    if (communications.isNotEmpty) {
      final codings = asMapList(
        (communications.first['language'] as Map?)?['coding'],
      );
      if (codings.isNotEmpty) {
        language = asString(codings.first['code'], fallback: 'fr');
      }
    }

    return Patient(
      id: asString(resource['id']),
      mrn: findIdentifier('MR') ?? asString(resource['id']),
      nationalNumber: findIdentifier('NI'),
      familyName: asString(name['family']),
      givenName: givens.isNotEmpty ? givens.first : '',
      gender: AdministrativeGender.fromFhir(asStringOrNull(resource['gender'])),
      birthDate: asDateTime(resource['birthDate']),
      address: Address(
        line: asStringList(addr['line']).firstOrNull ?? '',
        city: asString(addr['city']),
        postalCode: asString(addr['postalCode']),
        country: asString(addr['country'], fallback: 'BE'),
      ),
      phone: findTelecom('phone'),
      email: findTelecom('email'),
      preferredLanguage: language,
      deceasedDate: asDateTimeOrNull(resource['deceasedDateTime']),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
