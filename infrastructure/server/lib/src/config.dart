import 'dart:io';

import 'package:args/args.dart';

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

  static const Map<String, ({int port, String database})> defaults =
      <String, ({int port, String database})>{
    'EHR': (port: 8081, database: 'EHR_DB'),
    'ADT': (port: 8082, database: 'ADT_DB'),
    'PHARM': (port: 8083, database: 'PHARM_DB'),
    'EAI': (port: 8084, database: 'EAI_DB'),
    'DEV': (port: 8085, database: 'DEV_DB'),
  };

  static ArgParser parser() => ArgParser()
    ..addOption('app',
        abbr: 'a',
        help: 'Which application to serve',
        allowed: defaults.keys,
        defaultsTo: 'EHR')
    ..addOption('port', abbr: 'p', help: 'Port to listen on (default: per app)')
    ..addOption('host', defaultsTo: '0.0.0.0')
    ..addOption('db-host', defaultsTo: 'localhost')
    ..addOption('db-port', defaultsTo: '5432')
    ..addOption('db-name', help: 'Database name (default: per app)')
    ..addOption('db-user', defaultsTo: 'hospital')
    ..addOption('db-password', defaultsTo: 'hospital')
    ..addFlag('help', abbr: 'h', negatable: false);

  /// Command-line arguments win, then environment variables, then the
  /// per-application defaults. Environment variables matter because that is
  /// how docker-compose configures the five instances.
  factory ServerConfig.from(ArgResults args, Map<String, String> env) {
    final app = (args['app'] as String? ?? env['APP'] ?? 'EHR').toUpperCase();
    final fallback = defaults[app] ?? defaults['EHR']!;

    int intOf(String? value, int fallbackValue) =>
        value == null ? fallbackValue : (int.tryParse(value) ?? fallbackValue);

    return ServerConfig(
      app: app,
      port: intOf(args['port'] as String? ?? env['PORT'], fallback.port),
      host: args['host'] as String? ?? env['HOST'] ?? '0.0.0.0',
      databaseHost: args['db-host'] as String? ?? env['DB_HOST'] ?? 'localhost',
      databasePort: intOf(args['db-port'] as String? ?? env['DB_PORT'], 5432),
      databaseName:
          args['db-name'] as String? ?? env['DB_NAME'] ?? fallback.database,
      databaseUser: args['db-user'] as String? ?? env['DB_USER'] ?? 'hospital',
      databasePassword:
          args['db-password'] as String? ?? env['DB_PASSWORD'] ?? 'hospital',
    );
  }

  /// A description safe to print: the password is never included.
  @override
  String toString() =>
      '$app on $host:$port → postgres://$databaseUser@$databaseHost:'
      '$databasePort/$databaseName';
}

/// Prints usage and exits.
Never usage(ArgParser parser, [String? error]) {
  if (error != null) stderr.writeln('error: $error\n');
  stdout.writeln('Mini-Hospital 2026 API server\n');
  stdout.writeln('Usage: dart run bin/server.dart --app EHR\n');
  stdout.writeln(parser.usage);
  exit(error == null ? 0 : 64);
}
