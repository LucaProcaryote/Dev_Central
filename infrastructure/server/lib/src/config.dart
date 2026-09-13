import 'dart:io';

import 'package:args/args.dart';
import 'package:postgres/postgres.dart';

/// Which application this instance is serving, and how to reach its database.
///
/// One binary, launched once per application: same code, five deployments.
/// That is how a hospital runs the same vendor product for several
/// departments, and it keeps the students looking at one server rather than
/// five that have quietly drifted apart.
class ServerConfig {
  const ServerConfig({
    required this.app,
    required this.port,
    required this.host,
    required this.databaseHost,
    required this.databasePort,
    required this.databaseName,
    required this.databaseUser,
    required this.databasePassword,
    required this.databaseSsl,
    this.firebaseProject = '',
    this.firebaseApiKey = '',
    this.googleAccessToken = '',
  });

  /// `EHR`, `ADT`, `PHARM`, `EAI` or `DEV`.
  final String app;

  final int port;
  final String host;

  final String databaseHost;
  final int databasePort;
  final String databaseName;
  final String databaseUser;
  final String databasePassword;

  /// `disable` on a classroom network and over a unix socket, `require` when
  /// the connection crosses a network we do not own.
  final String databaseSsl;

  /// The Firebase project whose accounts the administration API manages, and
  /// the web API key used to validate the caller's ID token. Both empty means
  /// no administration API: the rest of the server runs exactly as before.
  final String firebaseProject;
  final String firebaseApiKey;

  /// A Google access token supplied from outside, for running the
  /// administration API on a laptop:
  ///
  ///     export GOOGLE_ACCESS_TOKEN=$(gcloud auth print-access-token)
  ///
  /// On Cloud Run this stays empty and the service's own identity is used
  /// instead, so nothing has to be issued, stored or rotated.
  final String googleAccessToken;

  /// Whether `/admin` is mounted. It takes both values because one without
  /// the other cannot work: the key alone cannot write claims, and the
  /// project alone cannot check who is asking.
  bool get servesAdmin =>
      firebaseProject.isNotEmpty && firebaseApiKey.isNotEmpty;

  /// A [databaseHost] beginning with `/` names a directory holding a unix
  /// socket, the same convention `psql` and libpq use. Cloud Run mounts the
  /// Cloud SQL socket that way, at
  /// `/cloudsql/PROJECT:REGION:INSTANCE`.
  bool get usesUnixSocket => databaseHost.startsWith('/');

  /// What to hand the driver as its host: the socket file itself when
  /// [usesUnixSocket], otherwise the hostname unchanged. PostgreSQL names the
  /// socket after the port, which is why the port is part of the path.
  String get databaseEndpointHost =>
      usesUnixSocket ? '$databaseHost/.s.PGSQL.$databasePort' : databaseHost;

  /// What to hand `shelf_io.serve` as its address.
  ///
  /// A *string* would send Dart through `getaddrinfo`, and the runtime image
  /// is `FROM scratch`: it has a libc, but none of the NSS plugins glibc
  /// dlopens to resolve a name. Handing over an [InternetAddress] skips name
  /// resolution altogether - which is both correct and, when it is wrong,
  /// wrong immediately rather than after a health-check deadline.
  Object get bindAddress => switch (host) {
    '0.0.0.0' => InternetAddress.anyIPv4,
    '::' || '::0' => InternetAddress.anyIPv6,
    _ => host,
  };

  static const Map<String, ({int port, String database})> defaults =
      <String, ({int port, String database})>{
        'EHR': (port: 8081, database: 'EHR_DB'),
        'ADT': (port: 8082, database: 'ADT_DB'),
        'PHARM': (port: 8083, database: 'PHARM_DB'),
        'EAI': (port: 8084, database: 'EAI_DB'),
        'DEV': (port: 8085, database: 'DEV_DB'),
      };

  static ArgParser parser() => ArgParser()
    ..addOption(
      'app',
      abbr: 'a',
      help: 'Which application to serve',
      allowed: defaults.keys,
      defaultsTo: 'EHR',
    )
    ..addOption('port', abbr: 'p', help: 'Port to listen on (default: per app)')
    ..addOption('host', defaultsTo: '0.0.0.0')
    ..addOption('db-host', defaultsTo: 'localhost')
    ..addOption('db-port', defaultsTo: '5432')
    ..addOption('db-name', help: 'Database name (default: per app)')
    ..addOption('db-user', defaultsTo: 'hospital')
    ..addOption('db-password', defaultsTo: 'hospital')
    ..addOption(
      'db-ssl',
      help: 'TLS to the database',
      allowed: <String>['disable', 'require', 'verifyFull'],
      defaultsTo: 'disable',
    )
    ..addOption(
      'firebase-project',
      help: 'Firebase project for the administration API (enables /admin)',
      defaultsTo: '',
    )
    ..addOption(
      'firebase-api-key',
      help: "The project's web API key, used to validate callers",
      defaultsTo: '',
    )
    ..addFlag('help', abbr: 'h', negatable: false);

  /// Command-line arguments win, then environment variables, then the
  /// per-application defaults. Environment variables matter because that is
  /// how docker-compose and Cloud Run configure the five instances.
  ///
  /// The precedence has to be read off [ArgResults.wasParsed] rather than off
  /// a null value: every option here declares a `defaultsTo`, so `args[name]`
  /// is never null and testing it would make the environment unreachable.
  factory ServerConfig.from(ArgResults args, Map<String, String> env) {
    String? given(String option) =>
        args.wasParsed(option) ? args[option] as String? : null;

    final app = (given('app') ?? env['APP'] ?? 'EHR').toUpperCase();
    final fallback = defaults[app] ?? defaults['EHR']!;

    int intOf(String? value, int fallbackValue) =>
        value == null ? fallbackValue : (int.tryParse(value) ?? fallbackValue);

    return ServerConfig(
      app: app,
      port: intOf(given('port') ?? env['PORT'], fallback.port),
      host: given('host') ?? env['HOST'] ?? '0.0.0.0',
      databaseHost: given('db-host') ?? env['DB_HOST'] ?? 'localhost',
      databasePort: intOf(given('db-port') ?? env['DB_PORT'], 5432),
      databaseName: given('db-name') ?? env['DB_NAME'] ?? fallback.database,
      databaseUser: given('db-user') ?? env['DB_USER'] ?? 'hospital',
      databasePassword:
          given('db-password') ?? env['DB_PASSWORD'] ?? 'hospital',
      databaseSsl: given('db-ssl') ?? env['DB_SSL'] ?? 'disable',
      firebaseProject:
          given('firebase-project') ?? env['FIREBASE_PROJECT'] ?? '',
      firebaseApiKey:
          given('firebase-api-key') ?? env['FIREBASE_API_KEY'] ?? '',
      googleAccessToken: env['GOOGLE_ACCESS_TOKEN'] ?? '',
    );
  }

  /// A description safe to print: the password is never included.
  @override
  String toString() => usesUnixSocket
      ? '$app on $host:$port → $databaseUser@$databaseEndpointHost'
            '/$databaseName (unix socket)'
      : '$app on $host:$port → postgres://$databaseUser@$databaseHost:'
            '$databasePort/$databaseName (ssl: $databaseSsl)';
}

/// Prints usage and exits.
Never usage(ArgParser parser, [String? error]) {
  if (error != null) stderr.writeln('error: $error\n');
  stdout.writeln('Mini-Hospital 2026 API server\n');
  stdout.writeln('Usage: dart run bin/server.dart --app EHR\n');
  stdout.writeln(parser.usage);
  exit(error == null ? 0 : 64);
}

/// Maps the `--db-ssl` value onto the driver's enum.
SslMode sslModeFor(String value) => switch (value) {
  'require' => SslMode.require,
  'verifyFull' => SslMode.verifyFull,
  _ => SslMode.disable,
};
