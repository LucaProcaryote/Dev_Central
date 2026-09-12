import 'package:hospital_server/src/config.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

ServerConfig configure(
  List<String> args, [
  Map<String, String> env = const {},
]) => ServerConfig.from(ServerConfig.parser().parse(args), env);

void main() {
  group('database endpoint', () {
    test('a hostname is a TCP connection, used unchanged', () {
      final config = configure(<String>['--db-host', 'postgres']);

      expect(config.usesUnixSocket, isFalse);
      expect(config.databaseEndpointHost, 'postgres');
    });

    test('a path is a unix socket, and the driver wants the socket file', () {
      // This is the shape Cloud Run mounts for Cloud SQL. The driver passes
      // the host straight to InternetAddress, so it has to be the socket
      // itself and not the directory holding it.
      final config = configure(<String>[
        '--db-host',
        '/cloudsql/my-hospital-2026:europe-west1:mini-hospital-2026-sql',
      ]);

      expect(config.usesUnixSocket, isTrue);
      expect(
        config.databaseEndpointHost,
        '/cloudsql/my-hospital-2026:europe-west1:mini-hospital-2026-sql'
        '/.s.PGSQL.5432',
      );
    });

    test('the socket file is named after the port', () {
      final config = configure(<String>[
        '--db-host',
        '/var/run/postgresql',
        '--db-port',
        '5433',
      ]);

      expect(config.databaseEndpointHost, '/var/run/postgresql/.s.PGSQL.5433');
    });

    test('the password never appears in the printable description', () {
      final config = configure(<String>[
        '--db-password',
        'hunter2-should-not-be-logged',
      ]);

      expect(config.toString(), isNot(contains('hunter2')));
    });
  });

  group('ssl', () {
    test('defaults to disable, which is what docker-compose needs', () {
      expect(sslModeFor(configure(<String>[]).databaseSsl), SslMode.disable);
    });

    test('can be required for a connection crossing a network', () {
      final config = configure(<String>['--db-ssl', 'require']);

      expect(sslModeFor(config.databaseSsl), SslMode.require);
    });

    test('an unknown value falls back to disable rather than throwing', () {
      expect(sslModeFor('nonsense'), SslMode.disable);
    });
  });

  group('precedence', () {
    test('arguments beat the environment', () {
      final config = configure(
        <String>['--db-host', 'from-args'],
        <String, String>{'DB_HOST': 'from-env'},
      );

      expect(config.databaseHost, 'from-args');
    });

    test('the environment beats the per-application default', () {
      // docker-compose and Cloud Run both configure the five instances this
      // way, so this path matters as much as the command line.
      final config = configure(<String>[], <String, String>{
        'APP': 'PHARM',
        'DB_HOST': '/cloudsql/instance',
        'DB_SSL': 'require',
      });

      expect(config.app, 'PHARM');
      expect(config.databaseName, 'PHARM_DB');
      expect(config.usesUnixSocket, isTrue);
      expect(config.databaseSsl, 'require');
    });

    test('each application gets its own database and port', () {
      for (final entry in ServerConfig.defaults.entries) {
        final config = configure(<String>['--app', entry.key]);

        expect(config.databaseName, entry.value.database);
        expect(config.port, entry.value.port);
      }
    });

    test('Cloud Run sets PORT, and it must win over the per-app default', () {
      final config = configure(<String>[], <String, String>{'PORT': '8080'});

      expect(config.port, 8080);
    });
  });
}
