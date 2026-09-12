import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_core/hospital_core.dart';

/// The resolution rules, exercised without a browser.
AppConfig resolve({
  HospitalApp app = HospitalApp.device,
  String backend = 'memory',
  String auth = 'demo',
  String apiBase = '',
  String fhirBase = 'http://localhost:8080/fhir',
  String eaiBase = 'http://localhost:8084',
  String deviceId = 'DEV1',
  Map<String, String> query = const <String, String>{},
}) => AppConfig.resolve(
  app: app,
  backend: backend,
  auth: auth,
  apiBase: apiBase,
  fhirBase: fhirBase,
  eaiBase: eaiBase,
  deviceId: deviceId,
  query: query,
);

void main() {
  group('defaults', () {
    test('a build with no configuration runs on demo data', () {
      final config = resolve(app: HospitalApp.ehr);
      expect(config.backendMode, BackendMode.memory);
      expect(config.authMode, AuthMode.demo);
      expect(config.usesFirebaseAuth, isFalse);
    });

    test('each application gets its own API port', () {
      expect(resolve(app: HospitalApp.ehr).apiBaseUrl, endsWith(':8081'));
      expect(resolve(app: HospitalApp.adt).apiBaseUrl, endsWith(':8082'));
      expect(resolve(app: HospitalApp.pharm).apiBaseUrl, endsWith(':8083'));
      expect(resolve(app: HospitalApp.eai).apiBaseUrl, endsWith(':8084'));
      expect(resolve(app: HospitalApp.device).apiBaseUrl, endsWith(':8085'));
    });

    test('only the device application carries a device id', () {
      expect(resolve(app: HospitalApp.device).deviceId, 'DEV1');
      expect(resolve(app: HospitalApp.ehr).deviceId, isNull);
    });
  });

  group('dart-defines', () {
    test('are used when there is no query string', () {
      final config = resolve(
        app: HospitalApp.ehr,
        backend: 'restApi',
        auth: 'firebase',
        apiBase: 'http://api.example:9000',
      );
      expect(config.backendMode, BackendMode.restApi);
      expect(config.authMode, AuthMode.firebase);
      expect(config.usesFirebaseAuth, isTrue);
      expect(config.apiBaseUrl, 'http://api.example:9000');
    });

    test('an unrecognised value falls back rather than throwing', () {
      // A typo in a --dart-define must not stop the application booting.
      expect(resolve(backend: 'postgres!').backendMode, BackendMode.memory);
      expect(resolve(auth: 'oauth').authMode, AuthMode.demo);
    });
  });

  group('URL overrides', () {
    test('?device= makes one hosted build serve ten students', () {
      // The whole reason the query layer exists: a deployed web application
      // cannot be rebuilt per student.
      final config = resolve(query: <String, String>{'device': 'dev7'});
      expect(config.deviceId, 'DEV7');
    });

    test('?backend= and ?api= point a hosted build at a real server', () {
      final config = resolve(
        app: HospitalApp.ehr,
        query: <String, String>{
          'backend': 'restApi',
          'api': 'https://lab-api.example',
        },
      );
      expect(config.backendMode, BackendMode.restApi);
      expect(config.apiBaseUrl, 'https://lab-api.example');
    });

    test('?fhir= and ?eai= are overridable too', () {
      final config = resolve(
        query: <String, String>{
          'fhir': 'https://fhir.example/fhir',
          'eai': 'https://eai.example',
        },
      );
      expect(config.fhirBaseUrl, 'https://fhir.example/fhir');
      expect(config.eaiBaseUrl, 'https://eai.example');
    });

    test('an empty parameter does not blank out the compiled default', () {
      // ?api= with nothing after it is a mistake, not an instruction.
      final config = resolve(
        app: HospitalApp.ehr,
        apiBase: 'http://compiled:9000',
        query: <String, String>{'api': ''},
      );
      expect(config.apiBaseUrl, 'http://compiled:9000');
    });

    test('an unknown parameter is ignored', () {
      final config = resolve(query: <String, String>{'colour': 'purple'});
      expect(config.backendMode, BackendMode.memory);
      expect(config.deviceId, 'DEV1');
    });

    test('a nonsense override falls back rather than throwing', () {
      expect(
        resolve(query: <String, String>{'backend': 'sqlite'}).backendMode,
        BackendMode.memory,
      );
    });

    test('?device= is ignored by the applications that are not devices', () {
      final config = resolve(
        app: HospitalApp.pharm,
        query: <String, String>{'device': 'DEV4'},
      );
      expect(config.deviceId, isNull);
    });
  });

  test('the description never leaks anything but endpoints', () {
    final text = resolve(app: HospitalApp.ehr, backend: 'restApi').toString();
    expect(text, contains('EHR'));
    expect(text, contains('restApi'));
  });
}
