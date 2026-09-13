import 'dart:convert';

import 'package:hospital_server/src/admin/admin_api.dart';
import 'package:hospital_server/src/admin/identity_toolkit.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

/// A stand-in for Identity Toolkit that answers from a script and records what
/// it was asked. Nothing here reaches the network.
class FakeIdentity {
  final List<({String endpoint, Map<String, dynamic> body})> calls =
      <({String endpoint, Map<String, dynamic> body})>[];

  /// endpoint (the last path segment, plus query) -> response
  final Map<String, IdentityResponse> responses = <String, IdentityResponse>{};

  Future<IdentityResponse> post(
    Uri url,
    Map<String, String> headers,
    Map<String, dynamic> body,
  ) async {
    final endpoint = url.pathSegments.last;
    calls.add((endpoint: endpoint, body: body));
    return responses[endpoint] ??
        const IdentityResponse(200, <String, dynamic>{});
  }
}

Map<String, dynamic> _account({
  String uid = 'uid-admin',
  String email = 'admin@mini-hospital.be',
  String? role = 'admin',
  bool disabled = false,
}) => <String, dynamic>{
  'localId': uid,
  'email': email,
  'displayName': 'Hospital Administrator',
  'disabled': disabled,
  if (role != null)
    'customAttributes': jsonEncode(<String, String>{'role': role}),
};

void main() {
  late FakeIdentity fake;
  late Handler handler;

  setUp(() {
    fake = FakeIdentity();
    // Every request starts with the caller lookup, so give it a default.
    fake.responses['accounts:lookup'] = IdentityResponse(200, <String, dynamic>{
      'users': <Map<String, dynamic>>[_account()],
    });
    handler = AdminApi(
      identity: IdentityToolkit(
        project: 'my-hospital-2026',
        apiKey: 'test-key',
        accessTokens: const StaticAccessToken('access-token'),
        post: fake.post,
      ),
    ).handler;
  });

  Future<Response> call(
    String method,
    String path, {
    Object? body,
    String? token = 'id-token',
  }) async => handler(
    Request(
      method,
      Uri.parse('http://localhost/$path'),
      headers: <String, String>{
        if (token != null) 'authorization': 'Bearer $token',
      },
      body: body == null ? null : jsonEncode(body),
    ),
  );

  Future<Map<String, dynamic>> bodyOf(Response response) async =>
      jsonDecode(await response.readAsString()) as Map<String, dynamic>;

  group('who may call it', () {
    test('no token is refused before anything is looked up', () async {
      final response = await call('GET', 'users', token: null);

      expect(response.statusCode, 401);
      expect((await bodyOf(response))['error'], 'missing-token');
      expect(fake.calls, isEmpty);
    });

    test('a token Google does not recognise is refused', () async {
      fake.responses['accounts:lookup'] = const IdentityResponse(
        400,
        <String, dynamic>{},
      );

      final response = await call('GET', 'users');

      expect(response.statusCode, 401);
      expect((await bodyOf(response))['error'], 'invalid-token');
    });

    test('a signed-in nurse is refused', () async {
      // The whole point: holding a valid session is not holding the console.
      fake.responses['accounts:lookup'] = IdentityResponse(
        200,
        <String, dynamic>{
          'users': <Map<String, dynamic>>[
            _account(uid: 'uid-nurse', role: 'nurse'),
          ],
        },
      );

      final response = await call('GET', 'users');

      expect(response.statusCode, 403);
      expect((await bodyOf(response))['error'], 'not-an-administrator');
      // and nothing privileged was attempted
      expect(fake.calls.map((c) => c.endpoint), <String>['accounts:lookup']);
    });

    test('an account with no role claim at all is refused', () async {
      fake.responses['accounts:lookup'] = IdentityResponse(
        200,
        <String, dynamic>{
          'users': <Map<String, dynamic>>[_account(role: null)],
        },
      );

      expect((await call('GET', 'users')).statusCode, 403);
    });

    test('a disabled administrator is refused', () async {
      fake.responses['accounts:lookup'] = IdentityResponse(
        200,
        <String, dynamic>{
          'users': <Map<String, dynamic>>[_account(disabled: true)],
        },
      );

      final response = await call('GET', 'users');

      expect(response.statusCode, 403);
      expect((await bodyOf(response))['error'], 'account-disabled');
    });

    test('the CORS preflight is answered without a token', () async {
      // The browser sends OPTIONS with no Authorization header. Refusing it
      // would make every console request fail before it was sent.
      final response = await call('OPTIONS', 'users', token: null);

      expect(response.statusCode, isNot(401));
    });
  });

  group('listing', () {
    test('reads the role out of the custom-claims blob', () async {
      fake.responses['accounts:query'] = IdentityResponse(
        200,
        <String, dynamic>{
          'userInfo': <Map<String, dynamic>>[
            _account(uid: 'uid-2', email: 'marie@x.be', role: 'nurse'),
            _account(uid: 'uid-1', email: 'anne@x.be', role: 'physician'),
          ],
        },
      );

      final users =
          (await bodyOf(await call('GET', 'users')))['users'] as List<dynamic>;

      expect(users, hasLength(2));
      // sorted by e-mail, so the list does not reshuffle between refreshes
      expect((users.first as Map)['email'], 'anne@x.be');
      expect((users.first as Map)['role'], 'physician');
    });

    test('an account with no claims is reported with an empty role', () async {
      fake.responses['accounts:query'] = IdentityResponse(
        200,
        <String, dynamic>{
          'userInfo': <Map<String, dynamic>>[_account(role: null)],
        },
      );

      final users =
          (await bodyOf(await call('GET', 'users')))['users'] as List<dynamic>;

      expect((users.single as Map)['role'], '');
    });
  });

  group('creating', () {
    test('creates the account and then writes the role claim', () async {
      fake.responses['accounts'] = const IdentityResponse(
        200,
        <String, dynamic>{'localId': 'uid-new'},
      );

      final response = await call(
        'POST',
        'users',
        body: <String, dynamic>{
          'email': 'nieuwe@mini-hospital.be',
          'password': 'Hospital2026!',
          'display_name': 'Nieuwe Collega',
          'role': 'nurse',
        },
      );

      expect(response.statusCode, 201);
      final endpoints = fake.calls.map((c) => c.endpoint).toList();
      expect(endpoints, <String>[
        'accounts:lookup',
        'accounts',
        'accounts:update',
      ]);

      final claim = fake.calls.last.body['customAttributes'] as String;
      expect(jsonDecode(claim), <String, String>{'role': 'nurse'});
      expect(fake.calls.last.body['localId'], 'uid-new');
    });

    test('refuses a role no application knows about', () async {
      final response = await call(
        'POST',
        'users',
        body: <String, dynamic>{
          'email': 'x@y.be',
          'password': 'Hospital2026!',
          'role': 'superuser',
        },
      );

      expect(response.statusCode, 400);
      expect((await bodyOf(response))['error'], 'unknown-role');
      expect(fake.calls.map((c) => c.endpoint), <String>['accounts:lookup']);
    });

    test('refuses a password shorter than eight characters', () async {
      final response = await call(
        'POST',
        'users',
        body: <String, dynamic>{'email': 'x@y.be', 'password': 'short12'},
      );

      expect((await bodyOf(response))['error'], 'weak-password');
    });

    test('passes the Identity Toolkit error code through', () async {
      fake.responses['accounts'] = const IdentityResponse(
        400,
        <String, dynamic>{
          'error': <String, dynamic>{'message': 'EMAIL_EXISTS'},
        },
      );

      final response = await call(
        'POST',
        'users',
        body: <String, dynamic>{
          'email': 'admin@mini-hospital.be',
          'password': 'Hospital2026!',
          'role': 'student',
        },
      );

      expect(response.statusCode, 409);
      expect((await bodyOf(response))['error'], 'EMAIL_EXISTS');
    });
  });

  group('changing and removing', () {
    test('sets a new role', () async {
      final response = await call(
        'PATCH',
        'users/uid-7',
        body: <String, dynamic>{'role': 'pharmacist'},
      );

      expect(response.statusCode, 200);
      expect(fake.calls.last.endpoint, 'accounts:update');
      expect(
        jsonDecode(fake.calls.last.body['customAttributes'] as String),
        <String, String>{'role': 'pharmacist'},
      );
    });

    test('disabling is spelled the way Identity Toolkit spells it', () async {
      await call(
        'PATCH',
        'users/uid-7',
        body: <String, dynamic>{'disabled': true},
      );

      expect(fake.calls.last.body['disableUser'], isTrue);
    });

    test('an administrator cannot demote themselves', () async {
      // One misclick away from an installation nobody can administer.
      final response = await call(
        'PATCH',
        'users/uid-admin',
        body: <String, dynamic>{'role': 'student'},
      );

      expect(response.statusCode, 400);
      expect((await bodyOf(response))['error'], 'cannot-demote-yourself');
      expect(fake.calls.map((c) => c.endpoint), <String>['accounts:lookup']);
    });

    test('an administrator cannot disable themselves', () async {
      final response = await call(
        'PATCH',
        'users/uid-admin',
        body: <String, dynamic>{'disabled': true},
      );

      expect((await bodyOf(response))['error'], 'cannot-disable-yourself');
    });

    test('an administrator may still rename themselves', () async {
      final response = await call(
        'PATCH',
        'users/uid-admin',
        body: <String, dynamic>{'display_name': 'Luca'},
      );

      expect(response.statusCode, 200);
      expect(fake.calls.last.body['displayName'], 'Luca');
    });

    test('an empty change is refused rather than sent', () async {
      final response = await call(
        'PATCH',
        'users/uid-7',
        body: <String, dynamic>{},
      );

      expect((await bodyOf(response))['error'], 'nothing-to-change');
    });

    test('deletes another account', () async {
      final response = await call('DELETE', 'users/uid-7');

      expect(response.statusCode, 200);
      expect(fake.calls.last.endpoint, 'accounts:delete');
      expect(fake.calls.last.body['localId'], 'uid-7');
    });

    test('an administrator cannot delete themselves', () async {
      final response = await call('DELETE', 'users/uid-admin');

      expect((await bodyOf(response))['error'], 'cannot-delete-yourself');
      expect(fake.calls.map((c) => c.endpoint), <String>['accounts:lookup']);
    });
  });

  test(
    'whoami reports the caller, so the console can prove it is admin',
    () async {
      final body = await bodyOf(await call('GET', 'whoami'));

      expect((body['user'] as Map)['email'], 'admin@mini-hospital.be');
      expect((body['user'] as Map)['role'], 'admin');
    },
  );

  test('the roles endpoint offers exactly the roles that may be set', () async {
    final body = await bodyOf(await call('GET', 'roles'));

    expect(body['roles'], AdminApi.defaultRoles);
  });
}
