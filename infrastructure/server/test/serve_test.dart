import 'dart:io';

import 'package:hospital_server/src/admin/admin_api.dart';
import 'package:hospital_server/src/admin/identity_toolkit.dart';
import 'package:hospital_server/src/config.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:test/test.dart';

/// The server reached "listening" and then went quiet once on Cloud Run, which
/// from outside is indistinguishable from a hang on the database. These tests
/// cover the last few lines of `main` - the ones no other test touches.
void main() {
  ServerConfig configFor(Map<String, String> env) =>
      ServerConfig.from(ServerConfig.parser().parse(<String>[]), env);

  group('the address it binds', () {
    test('the wildcard is an address, never a name to be resolved', () {
      // A string sends Dart through getaddrinfo, and the runtime image is
      // FROM scratch: libc, but none of the NSS plugins glibc dlopens.
      expect(
        configFor(<String, String>{}).bindAddress,
        InternetAddress.anyIPv4,
      );
      expect(
        configFor(<String, String>{'HOST': '::'}).bindAddress,
        InternetAddress.anyIPv6,
      );
    });

    test('a real hostname is still passed through', () {
      expect(
        configFor(<String, String>{'HOST': 'localhost'}).bindAddress,
        'localhost',
      );
    });
  });

  test('a router with /admin mounted serves over that address', () async {
    final admin = AdminApi(
      identity: IdentityToolkit(
        project: 'my-hospital-2026',
        apiKey: 'test-key',
        accessTokens: const StaticAccessToken('token'),
        post: (_, __, ___) async =>
            const IdentityResponse(400, <String, dynamic>{}),
      ),
    );
    final router = Router()
      ..get('/health', (Request request) => Response.ok('ok'));
    router.mount('/admin/', admin.handler);

    // Port 0: the operating system picks a free one.
    final server = await io.serve(
      router.call,
      configFor(<String, String>{}).bindAddress,
      0,
    );
    addTearDown(() => server.close(force: true));

    final client = HttpClient();
    addTearDown(() => client.close(force: true));

    Future<HttpClientResponse> get(String path) async {
      final request = await client.get('127.0.0.1', server.port, path);
      return request.close();
    }

    expect((await get('/health')).statusCode, 200);
    // Mounted, reachable, and refusing an unauthenticated caller - which is
    // the whole contract of that route.
    expect((await get('/admin/users')).statusCode, 401);
  });
}
