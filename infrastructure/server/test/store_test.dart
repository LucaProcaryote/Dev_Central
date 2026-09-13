import 'dart:io';

import 'package:hospital_server/src/store.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

/// The failure these guard against, in the words of the machine that found it:
///
///     curl: (28) Operation timed out after 60003 milliseconds
///           with 0 bytes received
///
/// The server was listening. The database socket had quietly died while the
/// Cloud Run instance was frozen, and the driver's default query timeout is
/// five minutes - so the request neither answered nor failed. Silence is the
/// worst failure mode there is: from outside it is indistinguishable from a
/// hang anywhere else in the stack.
///
/// The other half of the lesson is that opening the store must never be able
/// to fail, so that the port is never held hostage to the database.
void main() {
  /// A socket that accepts the connection and then says nothing at all -
  /// which is exactly what a dead PostgreSQL connection looks like.
  Future<ServerSocket> blackHole() async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((Socket socket) {
      // Deliberately no reply, and no close either.
    });
    return server;
  }

  void disposeLater(HospitalStore store) {
    addTearDown(() async {
      try {
        await store.close();
      } catch (_) {
        // Closing a pool that never connected is not interesting.
      }
    });
  }

  test('opening the store never touches the database', () {
    // Port 1: nothing is listening, and nothing ever will be. Building the
    // store must still succeed, because the process has to open its port
    // before it can afford to care.
    final store = HospitalStore.open(
      host: '127.0.0.1',
      port: 1,
      database: 'EHR_DB',
      username: 'hospital',
      password: 'hospital',
    );
    disposeLater(store);

    expect(store, isNotNull);
  });

  test(
    'a database that accepts and never answers is reported, not awaited',
    () async {
      final server = await blackHole();
      addTearDown(() => server.close());

      final store = HospitalStore.open(
        host: '127.0.0.1',
        port: server.port,
        database: 'EHR_DB',
        username: 'hospital',
        password: 'hospital',
        connectTimeout: const Duration(seconds: 2),
        queryTimeout: const Duration(seconds: 2),
      );
      disposeLater(store);

      final stopwatch = Stopwatch()..start();
      expect(await store.isHealthy(), isFalse);
      // The number that matters is not two seconds; it is "less than forever".
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 20)));
    },
  );

  test('the health check answers even when the database will not', () async {
    // The endpoint that matters most is the one that has to keep working when
    // everything else has stopped. Given a pool that can never complete a
    // query, isHealthy must still come back - and say no.
    final server = await blackHole();
    addTearDown(() => server.close());

    final store = HospitalStore(
      Pool<void>.withEndpoints(
        <Endpoint>[
          Endpoint(
            host: '127.0.0.1',
            port: server.port,
            database: 'EHR_DB',
            username: 'hospital',
            password: 'hospital',
          ),
        ],
        settings: const PoolSettings(
          sslMode: SslMode.disable,
          connectTimeout: Duration(seconds: 12),
          queryTimeout: Duration(minutes: 5),
        ),
      ),
    );
    disposeLater(store);

    final stopwatch = Stopwatch()..start();

    // Note the settings above: a twelve-second connect and the driver's own
    // five-minute query default. isHealthy has to impose its own deadline,
    // because it cannot rely on anyone else's - so it must come back well
    // before either of them.
    expect(await store.isHealthy(), isFalse);
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 10)));
  });
}
