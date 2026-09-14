import 'dart:convert';
import 'dart:io';

/// A minimal client for Firebase Authentication's REST API, covering the two
/// halves the administration console needs.
///
/// There is no Firebase Admin SDK for Dart, and there does not need to be: the
/// Identity Toolkit REST API is the same surface the SDK wraps. Two kinds of
/// call are used here, and the difference matters.
///
/// * `/v1/accounts:lookup?key=API_KEY` takes an **ID token** and tells you who
///   it belongs to. Google validates the signature, the expiry and the
///   revocation state, which is why this file contains no JWT verification of
///   its own - hand-rolled token checking is exactly where authentication
///   bugs live.
/// * `/v1/projects/PROJECT/accounts...` takes a **Google access token** for a
///   service account with the Firebase Authentication Admin role, and is what
///   can create users and write custom claims. This is privileged: it must
///   never be reachable without the check above having passed first.
class IdentityToolkit {
  IdentityToolkit({
    required this.project,
    required this.apiKey,
    required this.accessTokens,
    JsonPost? post,
  }) : _post = post ?? postJson;

  /// The Firebase project, e.g. `my-hospital-2026`.
  final String project;

  /// The web API key. Identifies the project on the public endpoint; it
  /// authorises nothing on its own.
  final String apiKey;

  final AccessTokens accessTokens;
  final JsonPost _post;

  static const String _base = 'https://identitytoolkit.googleapis.com/v1';

  // ---- public endpoint: who is this? ---------------------------------------

  /// The account an ID token belongs to, or null if the token is not valid.
  Future<Account?> accountForIdToken(String idToken) async {
    final response = await _post(
      Uri.parse('$_base/accounts:lookup?key=$apiKey'),
      const <String, String>{},
      <String, dynamic>{'idToken': idToken},
    );
    if (!response.ok) return null;
    final users = response.body['users'];
    if (users is! List || users.isEmpty) return null;
    return Account.fromJson(users.first as Map<String, dynamic>);
  }

  // ---- privileged endpoints ------------------------------------------------

  Future<List<Account>> listAccounts() async {
    final response = await _privileged('accounts:query', <String, dynamic>{});
    if (!response.ok) throw IdentityFailure(response.errorMessage);
    final users = response.body['userInfo'];
    if (users is! List) return const <Account>[];
    return users
        .cast<Map<String, dynamic>>()
        .map(Account.fromJson)
        .toList(growable: false)
      ..sort((a, b) => a.email.compareTo(b.email));
  }

  Future<Account> createAccount({
    required String email,
    required String password,
    required String displayName,
    required String role,
  }) async {
    final created = await _privileged('accounts', <String, dynamic>{
      'email': email,
      'password': password,
      if (displayName.isNotEmpty) 'displayName': displayName,
    });
    final uid = created.body['localId']?.toString() ?? '';
    if (uid.isEmpty) throw IdentityFailure(created.errorMessage);

    await setRole(uid: uid, role: role);
    return Account(
      uid: uid,
      email: email,
      displayName: displayName,
      role: role,
      disabled: false,
    );
  }

  /// Writes the `role` custom claim - the one thing the Firebase console
  /// cannot do, and the reason this API exists at all.
  Future<void> setRole({required String uid, required String role}) => update(
    uid: uid,
    fields: <String, dynamic>{
      'customAttributes': jsonEncode(<String, String>{'role': role}),
    },
  );

  Future<void> update({
    required String uid,
    required Map<String, dynamic> fields,
  }) async {
    final response = await _privileged('accounts:update', <String, dynamic>{
      'localId': uid,
      ...fields,
    });
    if (!response.ok) throw IdentityFailure(response.errorMessage);
  }

  Future<void> deleteAccount(String uid) async {
    final response = await _privileged('accounts:delete', <String, dynamic>{
      'localId': uid,
    });
    if (!response.ok) throw IdentityFailure(response.errorMessage);
  }

  /// Every privileged call goes through here, so the access token is fetched
  /// in exactly one place. Failures are returned rather than thrown: the
  /// callers need the Identity Toolkit error code to say something useful.
  Future<IdentityResponse> _privileged(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final token = await accessTokens.get();
    return _post(
      Uri.parse('$_base/projects/$project/$endpoint'),
      <String, String>{'Authorization': 'Bearer $token'},
      body,
    );
  }
}

/// One Firebase account, as the console shows it plus the role claim.
class Account {
  const Account({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.disabled,
    this.createdAt,
    this.lastSignInAt,
  });

  final String uid;
  final String email;
  final String displayName;

  /// The `role` custom claim, or an empty string when the account has none -
  /// which the applications read as [UserRole.student].
  final String role;
  final bool disabled;
  final DateTime? createdAt;
  final DateTime? lastSignInAt;

  factory Account.fromJson(Map<String, dynamic> json) => Account(
    uid: json['localId']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    displayName: json['displayName']?.toString() ?? '',
    role: _roleFromClaims(json['customAttributes']),
    disabled: json['disabled'] == true,
    createdAt: _millis(json['createdAt']),
    lastSignInAt: _millis(json['lastLoginAt']),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'uid': uid,
    'email': email,
    'display_name': displayName,
    'role': role,
    'disabled': disabled,
    'created_at': createdAt?.toUtc().toIso8601String(),
    'last_sign_in_at': lastSignInAt?.toUtc().toIso8601String(),
  };

  /// Custom claims arrive as a JSON *string*, not an object, and an account
  /// that has never had claims set has no field at all.
  static String _roleFromClaims(Object? attributes) {
    if (attributes is! String || attributes.isEmpty) return '';
    try {
      final decoded = jsonDecode(attributes);
      if (decoded is Map && decoded['role'] is String) {
        return decoded['role'] as String;
      }
    } on FormatException {
      // A claim blob someone hand-edited in the console. Treat it as no role
      // rather than failing the whole listing.
    }
    return '';
  }

  static DateTime? _millis(Object? value) {
    final millis = int.tryParse(value?.toString() ?? '');
    if (millis == null || millis == 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
  }
}

class IdentityFailure implements Exception {
  const IdentityFailure(this.message);
  final String message;
  @override
  String toString() => 'IdentityFailure: $message';
}

// ---------------------------------------------------------------------------
// Transport
// ---------------------------------------------------------------------------

class IdentityResponse {
  const IdentityResponse(this.statusCode, this.body);

  final int statusCode;
  final Map<String, dynamic> body;

  bool get ok => statusCode >= 200 && statusCode < 300;

  /// Google returns `{"error": {"message": "EMAIL_EXISTS"}}`. The message is
  /// a stable identifier, so it is passed through to the console rather than
  /// flattened into "something went wrong".
  String get errorMessage {
    final error = body['error'];
    if (error is Map && error['message'] != null) {
      return error['message'].toString();
    }
    return 'HTTP $statusCode';
  }
}

typedef JsonPost =
    Future<IdentityResponse> Function(
      Uri url,
      Map<String, String> headers,
      Map<String, dynamic> body,
    );

Future<IdentityResponse> postJson(
  Uri url,
  Map<String, String> headers,
  Map<String, dynamic> body,
) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(url);
    request.headers.contentType = ContentType.json;
    headers.forEach(request.headers.set);
    request.write(jsonEncode(body));
    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    final decoded = text.isEmpty ? null : jsonDecode(text);
    return IdentityResponse(
      response.statusCode,
      decoded is Map<String, dynamic> ? decoded : <String, dynamic>{},
    );
  } finally {
    client.close(force: true);
  }
}

// ---------------------------------------------------------------------------
// Access tokens
// ---------------------------------------------------------------------------

/// Where the service-account access token for the privileged endpoints comes
/// from.
abstract class AccessTokens {
  Future<String> get();
}

/// A token handed in through the environment. Used locally, where the
/// developer runs `export GOOGLE_ACCESS_TOKEN=$(gcloud auth print-access-token)`
/// rather than downloading a service-account key - a key on a laptop is a
/// credential that outlives the laptop.
class StaticAccessToken implements AccessTokens {
  const StaticAccessToken(this.token);
  final String token;

  @override
  Future<String> get() async => token;
}

/// The token Cloud Run's own service account already has.
///
/// This is why the deployment needs no secret and no key file: the metadata
/// server mints a short-lived token for the identity the service runs as.
/// Grant that service account `roles/firebaseauth.admin` and nothing else.
class MetadataAccessToken implements AccessTokens {
  MetadataAccessToken({this.now = DateTime.now});

  final DateTime Function() now;

  /// Note `default/`. The path names *which* service account is wanted, and
  /// leaving it out asks for a collection rather than a token: the metadata
  /// server answers 404, which reaches the console as "metadata server: HTTP
  /// 404" and looks for all the world like a problem with the console.
  static final Uri url = Uri.parse(
    'http://metadata.google.internal/computeMetadata/v1/'
    'instance/service-account/default/token',
  );

  String? _cached;
  DateTime? _expires;

  @override
  Future<String> get() async {
    final cached = _cached;
    final expires = _expires;
    if (cached != null && expires != null && now().isBefore(expires)) {
      return cached;
    }
    final client = HttpClient();
    try {
      final request = await client.getUrl(url);
      request.headers.set('Metadata-Flavor', 'Google');
      final response = await request.close();
      final text = await response.transform(utf8.decoder).join();
      if (response.statusCode != 200) {
        // The path is part of the message: a 404 here is almost always the
        // URL being wrong rather than the server being unwell.
        throw IdentityFailure(
          'metadata server: HTTP ${response.statusCode} for ${url.path}',
        );
      }
      final json = jsonDecode(text) as Map<String, dynamic>;
      final token = json['access_token']?.toString() ?? '';
      if (token.isEmpty) {
        throw const IdentityFailure('metadata server: no token');
      }
      final seconds = int.tryParse(json['expires_in']?.toString() ?? '') ?? 300;
      // A minute of slack, so a request never starts with a token that
      // expires while it is in flight.
      _expires = now().add(Duration(seconds: seconds - 60));
      _cached = token;
      return token;
    } finally {
      client.close(force: true);
    }
  }
}
