import 'dart:async';
import 'dart:io';

import 'package:hospital_server/src/admin/admin_api.dart';
import 'package:hospital_server/src/admin/identity_toolkit.dart';
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

  // Nothing here waits for PostgreSQL, and that is the point. Three
  // deployments in a row failed to start for three different reasons, and
  // every one of them looked identical from outside: "the container failed to
  // listen on PORT". A server that holds its port hostage to a dependency
  // turns any problem with that dependency into an unexplained outage.
  //
  // So the port is opened first, unconditionally. If the database is
  // unreachable, /health says `degraded` and every other route answers with
  // the driver's own error - which is a diagnosis rather than a silence.
  final store = HospitalStore.open(
    host: config.databaseEndpointHost,
    port: config.databasePort,
    database: config.databaseName,
    username: config.databaseUser,
    password: config.databasePassword,
    isUnixSocket: config.usesUnixSocket,
    sslMode: sslModeFor(config.databaseSsl),
  );

  // Account management is only mounted when the server was told which
  // Firebase project it belongs to. No project, no /admin.
  AdminApi? admin;
  if (config.servesAdmin) {
    admin = AdminApi(
      identity: IdentityToolkit(
        project: config.firebaseProject,
        apiKey: config.firebaseApiKey,
        accessTokens: config.googleAccessToken.isNotEmpty
            ? StaticAccessToken(config.googleAccessToken)
            : MetadataAccessToken(),
      ),
    );
    stdout.writeln('  /admin serves ${config.firebaseProject}');
  }

  final api = HospitalApi(store: store, app: config.app, admin: admin);

  // Never fail silently here. A server that reaches this line and then says
  // nothing is indistinguishable, from outside, from one that hung on the
  // database - and on Cloud Run all you get is "the container failed to
  // listen on PORT", which names the symptom and not one cause.
  // Printed before the attempt, not after: if binding hangs rather than
  // throws, this line is the only thing that says where it stopped.
  stdout.writeln('Binding ${config.bindAddress} port ${config.port}...');
  final HttpServer server;
  try {
    server = await io.serve(api.handler, config.bindAddress, config.port);
  } catch (error) {
    stderr.writeln('Could not listen on ${config.host}:${config.port}: $error');
    exit(70);
  }
  stdout.writeln(
    'Listening on http://${server.address.address}:${server.port}',
  );

  // Close the database cleanly so a restart does not leave a connection behind.
  Future<void> shutdown(ProcessSignal signal) async {
    stdout.writeln('\nStopping (${signal.toString()})…');
    await server.close(force: true);
    await store.close();
    exit(0);
  }

  ProcessSignal.sigint.watch().listen(shutdown);
  if (!Platform.isWindows) {
    ProcessSignal.sigterm.watch().listen(shutdown);
  }

  // Now that the port is open, say whether the database is actually there.
  // In a compose stack PostgreSQL usually comes up a moment after the API, so
  // this retries rather than declaring failure on the first attempt.
  unawaited(reportDatabase(store, config.databaseName));
}

/// Logs whether the database answers, retrying for a couple of minutes.
///
/// Never exits the process. An API that is up and cannot reach its database
/// is worth far more to whoever is debugging than one that is not up at all.
Future<void> reportDatabase(HospitalStore store, String database) async {
  for (var attempt = 1; attempt <= 30; attempt++) {
    if (await store.isHealthy()) {
      stdout.writeln('$database is reachable');
      return;
    }
    if (attempt == 1) {
      stdout.writeln('$database did not answer yet; retrying');
    }
    await Future<void>.delayed(const Duration(seconds: 4));
  }
  stderr.writeln(
    '$database has not answered in two minutes. The API is still serving; '
    '/health reports degraded and every other route will return the '
    "driver's error.",
  );
}
