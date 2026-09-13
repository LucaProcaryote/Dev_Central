import 'package:firebase_core/firebase_core.dart';

/// The Firebase project an application signs in against.
///
/// Supplied as `--dart-define`s rather than through a generated
/// `firebase_options.dart`, for two reasons. One build of this repository can
/// then be pointed at a teaching project or at a throwaway one without
/// regenerating a file, which is the same shape every other setting here has.
/// And the repository stays compilable for someone who has never run
/// `flutterfire configure`, which matters when ten students clone it on the
/// first morning.
///
/// None of these values is a secret. A Firebase web API key identifies the
/// project; it does not authorise anything on its own. What protects the
/// hospital is the authentication itself, the authorised-domains list and the
/// rules on the data - never the obscurity of this key. It is deliberately
/// *not* readable from the query string, though: letting a visitor repoint the
/// application at another project would be a phishing surface.
class FirebaseConfig {
  const FirebaseConfig({
    required this.apiKey,
    required this.appId,
    required this.messagingSenderId,
    required this.projectId,
    required this.authDomain,
    required this.storageBucket,
  });

  final String apiKey;
  final String appId;
  final String messagingSenderId;
  final String projectId;
  final String authDomain;
  final String storageBucket;

  static const String _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String _sender = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const String _projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'my-hospital-2026',
  );
  static const String _authDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
  );
  static const String _bucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );

  factory FirebaseConfig.fromEnvironment() => FirebaseConfig(
    apiKey: _apiKey,
    appId: _appId,
    messagingSenderId: _sender,
    projectId: _projectId,
    // Both of these are derivable from the project id, and are what the
    // console shows for a default project, so they are worth defaulting rather
    // than making someone paste two more values that are already implied.
    authDomain: _authDomain.isNotEmpty
        ? _authDomain
        : '$_projectId.firebaseapp.com',
    storageBucket: _bucket.isNotEmpty
        ? _bucket
        : '$_projectId.firebasestorage.app',
  );

  /// The four values Firebase genuinely cannot work without.
  bool get isComplete =>
      apiKey.isNotEmpty &&
      appId.isNotEmpty &&
      messagingSenderId.isNotEmpty &&
      projectId.isNotEmpty;

  /// Which values are missing, for an error message that says what to do
  /// rather than that something went wrong.
  List<String> get missing => <String>[
    if (apiKey.isEmpty) 'FIREBASE_API_KEY',
    if (appId.isEmpty) 'FIREBASE_APP_ID',
    if (messagingSenderId.isEmpty) 'FIREBASE_MESSAGING_SENDER_ID',
    if (projectId.isEmpty) 'FIREBASE_PROJECT_ID',
  ];

  FirebaseOptions toOptions() => FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    authDomain: authDomain,
    storageBucket: storageBucket,
  );

  @override
  String toString() =>
      'FirebaseConfig($projectId, app $appId, '
      '${isComplete ? "complete" : "missing ${missing.join(", ")}"})';
}
