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
    this.mqttUrl = '',
    this.mqttUsername = '',
    this.mqttPassword = '',
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

  /// `wss://...` address of the MQTT broker the connected devices publish to.
  /// Empty means no broker is configured and the MQTT features stay hidden
  /// rather than failing when somebody opens them.
  final String mqttUrl;

  final String mqttUsername;

  /// Compiled into a web build, and therefore readable by anyone who opens
  /// the page. It is a lock on a teaching broker, not a secret - which is
  /// exactly what the deployment script says when it prints it.
  final String mqttPassword;

  bool get usesMqtt => mqttUrl.isNotEmpty;

  /// Identity of this device simulator instance (`DEV1`..`DEV10`).
  /// Only meaningful for [HospitalApp.device].
  final String? deviceId;

  final String firebaseProjectId;

  /// Builds the configuration for [app] from compile-time `--dart-define`s,
  /// overridden where present by URL query parameters, falling back to values
  /// that work out of the box with no infrastructure.
  ///
  /// The query-parameter layer exists for hosted builds. A deployed web
  /// application cannot be rebuilt per student, so `?device=DEV3` is the only
  /// way ten people can share one URL and still be ten different devices - and
  /// `?backend=restApi&api=https://lab-api` lets a lecturer hand out a link
  /// that points the same build at a real server.
  ///
  /// `Uri.base` is the page URL on web and a harmless `file:` URI elsewhere,
  /// so this needs no platform check and no `dart:html`.
  factory AppConfig.fromEnvironment(HospitalApp app) {
    const backendRaw = String.fromEnvironment(
      'BACKEND',
      defaultValue: 'memory',
    );
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
    const mqttUrl = String.fromEnvironment('MQTT_URL');
    const mqttUsername = String.fromEnvironment('MQTT_USERNAME');
    const mqttPassword = String.fromEnvironment('MQTT_PASSWORD');

    return AppConfig.resolve(
      app: app,
      backend: backendRaw,
      auth: authRaw,
      apiBase: apiBase,
      fhirBase: fhirBase,
      eaiBase: eaiBase,
      deviceId: deviceId,
      mqttUrl: mqttUrl,
      mqttUsername: mqttUsername,
      mqttPassword: mqttPassword,
      query: queryOverrides(),
    );
  }

  /// Query parameters of the current page, lower-cased. Empty off the web.
  static Map<String, String> queryOverrides() {
    final parameters = Uri.base.queryParameters;
    if (parameters.isEmpty) return const <String, String>{};
    return <String, String>{
      for (final entry in parameters.entries)
        entry.key.toLowerCase(): entry.value,
    };
  }

  /// The resolution rules, separated from where the values came from so they
  /// can be tested without a browser.
  factory AppConfig.resolve({
    required HospitalApp app,
    required String backend,
    required String auth,
    required String apiBase,
    required String fhirBase,
    required String eaiBase,
    required String deviceId,
    String mqttUrl = '',
    String mqttUsername = '',
    String mqttPassword = '',
    Map<String, String> query = const <String, String>{},
  }) {
    String pick(String name, String fromDefine) {
      final override = query[name];
      return (override == null || override.isEmpty) ? fromDefine : override;
    }

    final resolvedApi = pick('api', apiBase);

    return AppConfig(
      app: app,
      backendMode: BackendMode.values.firstWhere(
        (m) => m.name.toLowerCase() == pick('backend', backend).toLowerCase(),
        orElse: () => BackendMode.memory,
      ),
      authMode: AuthMode.values.firstWhere(
        (m) => m.name.toLowerCase() == pick('auth', auth).toLowerCase(),
        orElse: () => AuthMode.demo,
      ),
      apiBaseUrl: resolvedApi.isNotEmpty
          ? resolvedApi
          : 'http://localhost:${app.defaultApiPort}',
      fhirBaseUrl: pick('fhir', fhirBase),
      eaiBaseUrl: pick('eai', eaiBase),
      // The address is overridable so a lecturer can point one build at
      // another broker; the credentials are not, because a link that carries
      // them would put them in every browser history in the room.
      mqttUrl: pick('mqtt', mqttUrl),
      mqttUsername: mqttUsername,
      mqttPassword: mqttPassword,
      deviceId: app == HospitalApp.device
          ? pick('device', deviceId).toUpperCase()
          : null,
    );
  }

  bool get usesFirebaseAuth => authMode == AuthMode.firebase;

  @override
  String toString() =>
      'AppConfig(${app.code}, backend: ${backendMode.name}, auth: ${authMode.name}, '
      'api: $apiBaseUrl, fhir: $fhirBaseUrl, mqtt: ${usesMqtt ? mqttUrl : 'off'})';
}
