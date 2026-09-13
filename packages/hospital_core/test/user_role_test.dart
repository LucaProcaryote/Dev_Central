import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_core/hospital_core.dart';

void main() {
  group('UserRole', () {
    test('exactly one role may administer accounts', () {
      final administrators = UserRole.values
          .where((role) => role.canAdminister)
          .toList();

      expect(administrators, <UserRole>[UserRole.admin]);
    });

    test('the administrator has no clinical rights', () {
      // Managing accounts is not a licence to prescribe. Keeping the two apart
      // is the point of having a separate role rather than a "super student".
      expect(UserRole.admin.canPrescribe, isFalse);
      expect(UserRole.admin.canDispense, isFalse);
      expect(UserRole.admin.canAdmit, isFalse);
      expect(UserRole.admin.canWriteNotes, isFalse);
    });

    test('the student role stops short of administration', () {
      // Students are given every clinical right so the exercises work. The one
      // thing they cannot do is promote themselves.
      expect(UserRole.student.canPrescribe, isTrue);
      expect(UserRole.student.canAdminister, isFalse);
    });

    test('an unknown claim falls back to student, never to admin', () {
      expect(UserRole.fromName('root'), UserRole.student);
      expect(UserRole.fromName(''), UserRole.student);
      expect(UserRole.fromName('admin'), UserRole.admin);
    });

    test('every role is named in the three languages', () {
      for (final role in UserRole.values) {
        expect(role.display.en, isNotEmpty, reason: role.name);
        expect(role.display.fr, isNotEmpty, reason: role.name);
        expect(role.display.nl, isNotEmpty, reason: role.name);
      }
    });
  });

  group('the seeded staff', () {
    test('includes one administrator', () {
      final admins = seedUsers.where((u) => u.role == UserRole.admin).toList();

      expect(admins, hasLength(1));
      expect(admins.single.email, 'admin@mini-hospital.be');
    });

    test('covers every role, so each one can be demonstrated', () {
      final covered = seedUsers.map((u) => u.role).toSet();

      expect(covered, containsAll(UserRole.values));
    });
  });
}
