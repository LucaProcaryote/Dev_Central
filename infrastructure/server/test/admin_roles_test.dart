@Tags(<String>['tool'])
library;

import 'dart:io';

import 'package:hospital_server/src/admin/admin_api.dart';
import 'package:test/test.dart';

/// The administration API refuses any role it does not know, which is only
/// safe if its list is the same list the applications use. The two live in
/// different packages - the server does not depend on Flutter - so nothing but
/// this test keeps them together.
void main() {
  test('the API knows exactly the roles hospital_core defines', () {
    final source = File(
      '${Directory.current.path}/../../packages/hospital_core'
      '/lib/src/models/hospital_user.dart',
    );
    if (!source.existsSync()) {
      markTestSkipped('hospital_core is not checked out next to the server');
      return;
    }

    final text = source.readAsStringSync();
    final enumBody = text.substring(
      text.indexOf('enum UserRole {'),
      text.indexOf('  const UserRole('),
    );
    // Every value is declared as `name(` at the start of a line.
    final declared = RegExp(
      r'^  ([a-zA-Z]+)\(',
      multiLine: true,
    ).allMatches(enumBody).map((m) => m.group(1)!).toList();

    expect(declared, isNotEmpty, reason: 'the enum could not be parsed');
    expect(
      AdminApi.defaultRoles.toSet(),
      declared.toSet(),
      reason:
          'AdminApi.defaultRoles has drifted from UserRole in hospital_core',
    );
  });
}
