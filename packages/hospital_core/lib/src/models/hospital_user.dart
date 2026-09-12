import 'package:flutter/foundation.dart';

import '../util/json.dart';
import '../util/localized_text.dart';

/// What a signed-in user is allowed to do.
///
/// Permissions in this teaching hospital are deliberately coarse: one role per
/// user, checked at the screen and action level. Real hospitals layer far more
/// on top, which is a good discussion to have with the students.
enum UserRole {
  physician(
    LocalizedText(en: 'Physician', fr: 'Médecin', nl: 'Arts'),
    canPrescribe: true,
    canDispense: false,
    canAdmit: true,
    canWriteNotes: true,
    canConfigureIntegration: false,
  ),
  nurse(
    LocalizedText(en: 'Nurse', fr: 'Infirmier·ère', nl: 'Verpleegkundige'),
    canPrescribe: false,
    canDispense: true,
    canAdmit: true,
    canWriteNotes: true,
    canConfigureIntegration: false,
  ),
  pharmacist(
    LocalizedText(en: 'Pharmacist', fr: 'Pharmacien·ne', nl: 'Apotheker'),
    canPrescribe: false,
    canDispense: true,
    canAdmit: false,
    canWriteNotes: false,
    canConfigureIntegration: false,
  ),
  admissionClerk(
    LocalizedText(
      en: 'Admission clerk',
      fr: "Agent d'admission",
      nl: 'Opnamemedewerker',
    ),
    canPrescribe: false,
    canDispense: false,
    canAdmit: true,
    canWriteNotes: false,
    canConfigureIntegration: false,
  ),
  integrationEngineer(
    LocalizedText(
      en: 'Integration engineer',
      fr: "Ingénieur d'intégration",
      nl: 'Integratie-ingenieur',
    ),
    canPrescribe: false,
    canDispense: false,
    canAdmit: false,
    canWriteNotes: false,
    canConfigureIntegration: true,
  ),
  biomedicalTechnician(
    LocalizedText(
      en: 'Biomedical technician',
      fr: 'Technicien biomédical',
      nl: 'Biomedisch technicus',
    ),
    canPrescribe: false,
    canDispense: false,
    canAdmit: false,
    canWriteNotes: false,
    canConfigureIntegration: false,
  ),
  student(
    LocalizedText(en: 'Student', fr: 'Étudiant·e', nl: 'Student'),
    canPrescribe: true,
    canDispense: true,
    canAdmit: true,
    canWriteNotes: true,
    canConfigureIntegration: true,
  );

  const UserRole(
    this.display, {
    required this.canPrescribe,
    required this.canDispense,
    required this.canAdmit,
    required this.canWriteNotes,
    required this.canConfigureIntegration,
  });

  final LocalizedText display;
  final bool canPrescribe;
  final bool canDispense;
  final bool canAdmit;
  final bool canWriteNotes;
  final bool canConfigureIntegration;

  static UserRole fromName(String value) =>
      values.firstWhere((r) => r.name == value, orElse: () => UserRole.student);
}

/// A signed-in member of staff.
///
/// When [AuthMode.firebase] is active the [uid] is the Firebase Auth UID; in
/// demo mode it is the seed identifier.
@immutable
class HospitalUser {
  const HospitalUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.wardIds = const <String>[],
    this.preferredLanguage = 'en',
    this.photoUrl,
    this.registrationNumber,
  });

  final String uid;
  final String email;
  final String displayName;
  final UserRole role;

  /// Wards this user works on. Empty means hospital-wide access.
  final List<String> wardIds;

  final String preferredLanguage;
  final String? photoUrl;

  /// Professional registration (INAMI/RIZIV) number, shown on prescriptions.
  final String? registrationNumber;

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  bool canAccessWard(String wardId) =>
      wardIds.isEmpty || wardIds.contains(wardId);

  factory HospitalUser.fromJson(Map<String, dynamic> json) => HospitalUser(
        uid: asString(json['uid'] ?? json['id']),
        email: asString(json['email']),
        displayName: asString(json['display_name'] ?? json['displayName']),
        role: UserRole.fromName(asString(json['role'], fallback: 'student')),
        wardIds: asStringList(json['ward_ids'] ?? json['wardIds']),
        preferredLanguage: asString(
          json['preferred_language'] ?? json['preferredLanguage'],
          fallback: 'en',
        ),
        photoUrl: asStringOrNull(json['photo_url'] ?? json['photoUrl']),
        registrationNumber: asStringOrNull(
          json['registration_number'] ?? json['registrationNumber'],
        ),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'uid': uid,
        'email': email,
        'display_name': displayName,
        'role': role.name,
        'ward_ids': wardIds,
        'preferred_language': preferredLanguage,
        'photo_url': photoUrl,
        'registration_number': registrationNumber,
      };
}
