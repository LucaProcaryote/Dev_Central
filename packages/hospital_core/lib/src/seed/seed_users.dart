import '../models/hospital_user.dart';

/// Staff accounts available in demo mode.
///
/// Deliberately covers every role, so a lecturer can demonstrate what each one
/// is and is not allowed to do without creating accounts first. The e-mail
/// addresses match the ones the Firebase setup script creates, so switching
/// `AUTH=firebase` keeps the same cast of characters.
const List<HospitalUser> seedUsers = <HospitalUser>[
  HospitalUser(
    uid: 'usr-001',
    email: 'anne.dubois@mini-hospital.be',
    displayName: 'Dr. Anne Dubois',
    role: UserRole.physician,
    wardIds: <String>['ward-card'],
    preferredLanguage: 'fr',
    registrationNumber: '1-12345-67-890',
  ),
  HospitalUser(
    uid: 'usr-002',
    email: 'jan.peeters@mini-hospital.be',
    displayName: 'Dr. Jan Peeters',
    role: UserRole.physician,
    wardIds: <String>['ward-int'],
    preferredLanguage: 'nl',
    registrationNumber: '1-23456-78-901',
  ),
  HospitalUser(
    uid: 'usr-003',
    email: 'marie.lambert@mini-hospital.be',
    displayName: 'Marie Lambert',
    role: UserRole.nurse,
    wardIds: <String>['ward-card'],
    preferredLanguage: 'fr',
  ),
  HospitalUser(
    uid: 'usr-004',
    email: 'sofie.declercq@mini-hospital.be',
    displayName: 'Sofie De Clercq',
    role: UserRole.nurse,
    wardIds: <String>['ward-icu'],
    preferredLanguage: 'nl',
  ),
  HospitalUser(
    uid: 'usr-005',
    email: 'paul.mertens@mini-hospital.be',
    displayName: 'Paul Mertens',
    role: UserRole.pharmacist,
    preferredLanguage: 'nl',
  ),
  HospitalUser(
    uid: 'usr-006',
    email: 'fatima.elamrani@mini-hospital.be',
    displayName: 'Fatima El Amrani',
    role: UserRole.admissionClerk,
    preferredLanguage: 'fr',
  ),
  HospitalUser(
    uid: 'usr-007',
    email: 'tom.vandenberg@mini-hospital.be',
    displayName: 'Tom Van den Berg',
    role: UserRole.integrationEngineer,
    preferredLanguage: 'en',
  ),
  HospitalUser(
    uid: 'usr-008',
    email: 'lucas.moreau@mini-hospital.be',
    displayName: 'Lucas Moreau',
    role: UserRole.biomedicalTechnician,
    preferredLanguage: 'fr',
  ),
  HospitalUser(
    uid: 'usr-009',
    email: 'student@mini-hospital.be',
    displayName: 'Student (full access)',
    role: UserRole.student,
    preferredLanguage: 'en',
  ),
];
