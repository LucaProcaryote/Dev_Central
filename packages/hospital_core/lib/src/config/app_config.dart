import 'package:flutter/foundation.dart';

/// Which application of the mini-hospital is currently running.
enum HospitalApp {
  ehr('EHR', 'EHR_DB', 8081),
  adt('ADT', 'ADT_DB', 8082),
  pharm('PHARM', 'PHARM_DB', 8083),
  eai('EAI', 'EAI_DB', 8084),
  device('DEV', 'DEV_DB', 8085);

  const HospitalApp(this.code, this.databaseName, this.defaultApiPort);

  /// Short code used in logs, FHIR `source` tags and HL7 sending-application.
  final String code;

  /// Name of the PostgreSQL database backing this application.
  final String databaseName;

  /// Port the bundled Dart API server listens on in the local stack.
  final int defaultApiPort;
}

/// Where the application reads and writes its data.
enum BackendMode {
  /// Everything lives in RAM, seeded with the fictive patient dataset.
  /// No Docker, no database, no network. This is the zero-setup classroom mode.
  memory,

  /// Talks to the bundled Dart `shelf` API server, which owns the PostgreSQL
  /// database. This is the local Docker stack.
  restApi,

  /// Talks to Firebase Data Connect (Cloud SQL for PostgreSQL) in the
  /// `my-hospital-2026` Firebase project. Requires the Blaze plan.
  dataConnect,
}

/// How users sign in.
enum AuthMode {
  /// Local accounts from the seed dataset, no network. Passwords are not
  /// checked; picking a user is enough. Classroom default.
  demo,

  /// Real Firebase Authentication against the `my-hospital-2026` project.
  firebase,
}

/// Immutable runtime configuration, resolved from `--dart-define` values so a
/// single build can be pointed at any backend without editing source.
///
/// Example:
/// ```
/// flutter run -d chrome \
///   --dart-define=BACKEND=restApi \
///   --dart-define=AUTH=firebase \
///   --dart-define=API_BASE=http://localhost:8081
/// ```
@immutable
class AppConfig {
  const AppConfig({
    required this.app,
    required this.backendMode,
    required this.authMode,
    required this.apiBaseUrl,
    required this.fhirBaseUrl,
    required this.eaiBaseUrl,
    this.deviceId,
    this.firebaseProjectId = 'my-hospital-2026',
  });

  final HospitalApp app;
  final BackendMode backendMode;
  final AuthMode authMode;

  /// Base URL of this application's own REST API.
  final String apiBaseUrl;

  /// Base URL of the HAPI FHIR R4 server (`.../fhir`).
  final String fhirBaseUrl;

  /// Base URL of the EAI integration engine, where applications post events.
  final String eaiBaseUrl;

  /// Identity of this device simulator instance (`DEV1`..`DEV10`).
  /// Only meaningful for [HospitalApp.device].
  final String? deviceId;

  final String firebaseProjectId;

  /// Builds the configuration for [app] from compile-time `--dart-define`s,
  /// falling back to values that work out of the box with no infrastructure.
  factory AppConfig.fromEnvironment(HospitalApp app) {
    const backendRaw = String.fromEnvironment('BACKEND', defaultValue: 'memory');
    const authRaw = String.fromEnvironment('AUTH', defaultValue: 'demo');
    const apiBase = String.fromEnvironment('API_BASE');
    const fhirBase = String.fromEnvironment(
      'FHIR_BASE',
      defaultValue: 'http://localhost:8080/fhir',
    );
    const eaiBase = String.fromEnvironment(
      'EAI_BASE',
      defaultValue: 'http://localhost:8084',
    );
    const deviceId = String.fromEnvironment('DEVICE_ID', defaultValue: 'DEV1');

    return AppConfig(
      app: app,
      backendMode: BackendMode.values.firstWhere(
        (m) => m.name.toLowerCase() == backendRaw.toLowerCase(),
        orElse: () => BackendMode.memory,
      ),
      authMode: AuthMode.values.firstWhere(
        (m) => m.name.toLowerCase() == authRaw.toLowerCase(),
        orElse: () => AuthMode.demo,
      ),
      apiBaseUrl:
          apiBase.isNotEmpty ? apiBase : 'http://localhost:${app.defaultApiPort}',
      fhirBaseUrl: fhirBase,
      eaiBaseUrl: eaiBase,
      deviceId: app == HospitalApp.device ? deviceId : null,
    );
  }

  bool get usesFirebaseAuth => authMode == AuthMode.firebase;

  @override
  String toString() =>
      'AppConfig(${app.code}, backend: ${backendMode.name}, auth: ${authMode.name}, '
      'api: $apiBaseUrl, fhir: $fhirBaseUrl)';
}
