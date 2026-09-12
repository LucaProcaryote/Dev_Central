import 'dart:io';

import 'package:hospital_server/src/api.dart';
import 'package:hospital_server/src/config.dart';
import 'package:hospital_server/src/store.dart';
import 'package:shelf/shelf_io.dart' as io;

/// Starts one application's API.
///
///     dart run bin/server.dart --app EHR
///     APP=PHARM DB_HOST=postgres dart run bin/server.dart
Future<void> main(List<String> arguments) async {
  final parser = ServerConfig.parser();
  final args = parser.parse(arguments);
  if (args['help'] as bool) usage(parser);

  final config = ServerConfig.from(args, Platform.environment);
  stdout.writeln('Mini-Hospital 2026 API — $config');

  // The database usually comes up a moment after the API in a compose stack,
  // so retry rather than crash-looping the container.
  HospitalStore? store;
  for (var attempt = 1; attempt <= 30; attempt++) {
    try {
      store = await HospitalStore.connect(
        host: config.databaseEndpointHost,
        port: config.databasePort,
        database: config.databaseName,
        username: config.databaseUser,
        password: config.databasePassword,
        isUnixSocket: config.usesUnixSocket,
        sslMode: sslModeFor(config.databaseSsl),
      );
      break;
    } catch (error) {
      stdout.writeln('  waiting for the database ($attempt/30): $error');
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }
  if (store == null) {
    stderr.writeln('Could not reach ${config.databaseName}. Is it running?');
    stderr.writeln('  cd infrastructure && docker compose up -d postgres');
    exit(69);
  }

  final api = HospitalApi(store: store, app: config.app);
  final server = await io.serve(api.handler, config.host, config.port);
  stdout.writeln('Listening on http://${server.address.host}:${server.port}');

  // Close the database cleanly so a restart does not leave a connection behind.
  Future<void> shutdown(ProcessSignal signal) async {
    stdout.writeln('\nStopping (${signal.toString()})…');
    await server.close(force: true);
    await store!.close();
    exit(0);
  }

  ProcessSignal.sigint.watch().listen(shutdown);
  if (!Platform.isWindows) {
    ProcessSignal.sigterm.watch().listen(shutdown);
  }
}
