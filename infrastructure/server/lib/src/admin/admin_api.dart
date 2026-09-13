import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'identity_toolkit.dart';

/// The account-management API behind the portal's administration console.
///
/// Why this has to be server-side: giving a user a role means writing a custom
/// claim, and custom claims can only be written with service-account
/// credentials. Those credentials cannot go into a Flutter web build - every
/// byte of it is downloadable - so the console asks this API, and this API
/// checks who is asking before it does anything.
///
/// The check is deliberately boring. Every request must carry the caller's own
/// Firebase ID token; Google validates it; the `role` claim on the account it
/// belongs to must be `admin`. There is no second way in, no shared secret and
/// no "internal" bypass.
class AdminApi {
  AdminApi({required this.identity, this.knownRoles = defaultRoles});

  final IdentityToolkit identity;

  /// The roles an account may be given. Anything else is refused, so a typo
  /// cannot quietly create a role no application knows about - which would
  /// land the user on [UserRole.student] with no explanation.
  ///
  /// Kept in step with `UserRole` in hospital_core by `test/admin_roles_test.dart`.
  final List<String> knownRoles;

  static const List<String> defaultRoles = <String>[
    'physician',
    'nurse',
    'pharmacist',
    'admissionClerk',
    'integrationEngineer',
    'biomedicalTechnician',
    'student',
    'admin',
  ];

  Handler get handler {
    final router = Router()
      ..get('/whoami', _whoami)
      ..get('/roles', _roles)
      ..get('/users', _listUsers)
      ..post('/users', _createUser)
      ..patch('/users/<uid>', _updateUser)
      ..delete('/users/<uid>', _deleteUser);

    return const Pipeline()
        .addMiddleware(_requireAdmin)
        .addHandler(router.call);
  }

  // ---- authentication ------------------------------------------------------

  static const String _callerKey = 'admin.caller';

  /// Rejects everything that is not a signed-in administrator.
  ///
  /// `OPTIONS` is let through unauthenticated because the browser sends the
  /// CORS preflight without the Authorization header. Mounted inside
  /// [HospitalApi] the preflight is already answered further out; the bypass
  /// is here so this router is also correct served on its own.
  Middleware get _requireAdmin => (Handler inner) {
    return (Request request) async {
      if (request.method == 'OPTIONS') return inner(request);

      final header = request.headers['authorization'] ?? '';
      if (!header.toLowerCase().startsWith('bearer ')) {
        return _error(401, 'missing-token');
      }
      final Account? caller;
      try {
        caller = await identity.accountForIdToken(header.substring(7).trim());
      } on IdentityFailure catch (failure) {
        return _error(502, failure.message);
      }
      if (caller == null) return _error(401, 'invalid-token');
      if (caller.disabled) return _error(403, 'account-disabled');
      if (caller.role != 'admin') return _error(403, 'not-an-administrator');

      return inner(
        request.change(context: <String, Object>{_callerKey: caller}),
      );
    };
  };

  static Account _caller(Request request) =>
      request.context[_callerKey]! as Account;

  // ---- routes --------------------------------------------------------------

  Response _whoami(Request request) {
    final caller = _caller(request);
    return _json(<String, dynamic>{'user': caller.toJson()});
  }

  Response _roles(Request request) =>
      _json(<String, dynamic>{'roles': knownRoles});

  Future<Response> _listUsers(Request request) async {
    final users = await identity.listAccounts();
    return _json(<String, dynamic>{
      'users': users.map((a) => a.toJson()).toList(growable: false),
    });
  }

  Future<Response> _createUser(Request request) async {
    final body = await _body(request);
    if (body == null) return _error(400, 'invalid-body');

    final email = (body['email'] ?? '').toString().trim();
    final password = (body['password'] ?? '').toString();
    final displayName = (body['display_name'] ?? body['displayName'] ?? '')
        .toString()
        .trim();
    final role = (body['role'] ?? 'student').toString();

    if (!email.contains('@')) return _error(400, 'invalid-email');
    // Firebase itself accepts six characters. Eight is the floor here because
    // these accounts are reachable from the public internet.
    if (password.length < 8) return _error(400, 'weak-password');
    if (!knownRoles.contains(role)) return _error(400, 'unknown-role');

    try {
      final created = await identity.createAccount(
        email: email,
        password: password,
        displayName: displayName,
        role: role,
      );
      return _json(<String, dynamic>{'user': created.toJson()}, status: 201);
    } on IdentityFailure catch (failure) {
      return _error(409, failure.message);
    }
  }

  Future<Response> _updateUser(Request request, String uid) async {
    final body = await _body(request);
    if (body == null) return _error(400, 'invalid-body');
    final caller = _caller(request);

    final role = body['role']?.toString();
    final disabled = body['disabled'];
    final password = body['password']?.toString();
    final displayName = (body['display_name'] ?? body['displayName'])
        ?.toString();

    if (role != null && !knownRoles.contains(role)) {
      return _error(400, 'unknown-role');
    }
    if (password != null && password.length < 8) {
      return _error(400, 'weak-password');
    }
    // Locking the last administrator out of the console is the classic way to
    // lose an installation, and it always happens by accident.
    if (uid == caller.uid && role != null && role != 'admin') {
      return _error(400, 'cannot-demote-yourself');
    }
    if (uid == caller.uid && disabled == true) {
      return _error(400, 'cannot-disable-yourself');
    }

    final fields = <String, dynamic>{
      if (displayName != null) 'displayName': displayName,
      if (password != null) 'password': password,
      if (disabled is bool) 'disableUser': disabled,
      if (role != null)
        'customAttributes': jsonEncode(<String, String>{'role': role}),
    };
    if (fields.isEmpty) return _error(400, 'nothing-to-change');

    try {
      await identity.update(uid: uid, fields: fields);
    } on IdentityFailure catch (failure) {
      return _error(400, failure.message);
    }
    return _json(<String, dynamic>{
      'uid': uid,
      'updated': fields.keys.toList(),
    });
  }

  Future<Response> _deleteUser(Request request, String uid) async {
    if (uid == _caller(request).uid) {
      return _error(400, 'cannot-delete-yourself');
    }
    try {
      await identity.deleteAccount(uid);
    } on IdentityFailure catch (failure) {
      return _error(400, failure.message);
    }
    return _json(<String, dynamic>{'uid': uid, 'deleted': true});
  }

  // ---- helpers -------------------------------------------------------------

  static Future<Map<String, dynamic>?> _body(Request request) async {
    try {
      final text = await request.readAsString();
      if (text.trim().isEmpty) return <String, dynamic>{};
      final decoded = jsonDecode(text);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  static Response _json(Map<String, dynamic> body, {int status = 200}) =>
      Response(
        status,
        body: jsonEncode(body),
        headers: const <String, String>{
          'content-type': 'application/json; charset=utf-8',
        },
      );

  static Response _error(int status, String code) =>
      _json(<String, dynamic>{'error': code}, status: status);
}
