import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_core/hospital_core.dart';

FirebaseConfig configure({
  String apiKey = '',
  String appId = '',
  String messagingSenderId = '',
  String projectId = 'my-hospital-2026',
  String authDomain = '',
  String storageBucket = '',
}) => FirebaseConfig(
  apiKey: apiKey,
  appId: appId,
  messagingSenderId: messagingSenderId,
  projectId: projectId,
  authDomain: authDomain.isEmpty ? '$projectId.firebaseapp.com' : authDomain,
  storageBucket: storageBucket.isEmpty
      ? '$projectId.firebasestorage.app'
      : storageBucket,
);

void main() {
  group('completeness', () {
    test('an unconfigured build is not complete, and says what is missing', () {
      final config = configure();

      expect(config.isComplete, isFalse);
      expect(
        config.missing,
        containsAll(<String>[
          'FIREBASE_API_KEY',
          'FIREBASE_APP_ID',
          'FIREBASE_MESSAGING_SENDER_ID',
        ]),
      );
    });

    test('the four required values are enough', () {
      final config = configure(
        apiKey: 'AIza-not-a-secret',
        appId: '1:1234:web:abcd',
        messagingSenderId: '1234',
      );

      expect(config.isComplete, isTrue);
      expect(config.missing, isEmpty);
    });

    test('a partially filled project is still incomplete', () {
      // The failure mode this guards against is a half-populated set of CI
      // variables silently producing a build that crashes at sign-in.
      final config = configure(apiKey: 'AIza-not-a-secret');

      expect(config.isComplete, isFalse);
      expect(config.missing, contains('FIREBASE_APP_ID'));
      expect(config.missing, isNot(contains('FIREBASE_API_KEY')));
    });
  });

  group('defaults derived from the project id', () {
    test('the auth domain and bucket follow the project when not given', () {
      final config = FirebaseConfig.fromEnvironment();

      expect(config.projectId, 'my-hospital-2026');
      expect(config.authDomain, 'my-hospital-2026.firebaseapp.com');
      expect(config.storageBucket, 'my-hospital-2026.firebasestorage.app');
    });
  });

  group('options', () {
    test('carry every value through to Firebase', () {
      final options = configure(
        apiKey: 'AIza-not-a-secret',
        appId: '1:1234:web:abcd',
        messagingSenderId: '1234',
      ).toOptions();

      expect(options.apiKey, 'AIza-not-a-secret');
      expect(options.appId, '1:1234:web:abcd');
      expect(options.messagingSenderId, '1234');
      expect(options.projectId, 'my-hospital-2026');
      expect(options.authDomain, 'my-hospital-2026.firebaseapp.com');
    });
  });

  group('the printable description', () {
    test('names the project and whether it is usable', () {
      expect(configure().toString(), contains('missing'));
      expect(
        configure(apiKey: 'k', appId: 'a', messagingSenderId: 's').toString(),
        contains('complete'),
      );
    });
  });
}
