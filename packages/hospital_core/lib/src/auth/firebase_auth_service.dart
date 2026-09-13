import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';

import '../config/firebase_config.dart';
import '../models/hospital_user.dart';
import 'auth_service.dart';

/// Real Firebase Authentication against the `my-hospital-2026` project.
///
/// Firebase owns identity - email, password, session persistence. It does not
/// own *role*: [UserRole] is resolved by [roleResolver], which by default reads
/// the custom claims set on the account. A hospital would drive those claims
/// from its HR directory; in the course they are set with the Admin SDK script
/// in `tools/set_user_roles.dart`.
class FirebaseAuthService extends AuthService {
  FirebaseAuthService({
    fb.FirebaseAuth? firebaseAuth,
    FirebaseConfig? config,
    this.roleResolver = defaultRoleResolver,
  }) : _injected = firebaseAuth,
       _config = config;

  /// Supplied by a test. When absent the instance is resolved in
  /// [initialize], *after* Firebase has been started - reading
  /// `FirebaseAuth.instance` in the constructor would throw before there is an
  /// app for it to attach to.
  final fb.FirebaseAuth? _injected;
  final FirebaseConfig? _config;

  late final fb.FirebaseAuth _auth;

  /// Maps a signed-in Firebase account onto a hospital role.
  final Future<UserRole> Function(fb.User user) roleResolver;

  HospitalUser? _currentUser;
  bool _isReady = false;
  StreamSubscription<fb.User?>? _subscription;

  @override
  HospitalUser? get currentUser => _currentUser;

  @override
  bool get isReady => _isReady;

  @override
  Future<void> initialize() async {
    if (_injected != null) {
      _auth = _injected;
    } else {
      final config = _config ?? FirebaseConfig.fromEnvironment();
      if (!config.isComplete) {
        throw StateError(
          'Firebase sign-in was requested but the project is not configured. '
          'Missing: ${config.missing.join(", ")}. Pass them at build time, '
          'for example --dart-define=FIREBASE_API_KEY=… ; the values are in '
          'the Firebase console under Project settings > Your apps. See '
          'FIREBASE.md.',
        );
      }
      // Safe to call more than once for the same options, which matters
      // because the startup screen offers a retry.
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: config.toOptions());
      }
      _auth = fb.FirebaseAuth.instance;
    }

    _subscription = _auth.authStateChanges().listen((user) async {
      _currentUser = user == null ? null : await _toHospitalUser(user);
      _isReady = true;
      notifyListeners();
    });
    // authStateChanges emits the restored session (or null) on subscribe, but
    // do not leave the UI stuck behind a splash if that is slow.
    unawaited(
      Future<void>.delayed(const Duration(seconds: 3), () {
        if (!_isReady) {
          _isReady = true;
          notifyListeners();
        }
      }),
    );
  }

  @override
  Future<HospitalUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) throw const AuthFailure('unknown');
      final hospitalUser = await _toHospitalUser(user);
      _currentUser = hospitalUser;
      notifyListeners();
      return hospitalUser;
    } on fb.FirebaseAuthException catch (error) {
      throw AuthFailure(_mapCode(error.code), error.message);
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<HospitalUser> _toHospitalUser(fb.User user) async {
    final role = await roleResolver(user);
    return HospitalUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName?.isNotEmpty == true
          ? user.displayName!
          : (user.email?.split('@').first ?? 'User'),
      role: role,
      photoUrl: user.photoURL,
    );
  }

  static String _mapCode(String firebaseCode) => switch (firebaseCode) {
    'invalid-email' ||
    'wrong-password' ||
    'invalid-credential' => 'invalid-credentials',
    'user-not-found' => 'user-not-found',
    'network-request-failed' => 'network',
    'operation-not-allowed' || 'configuration-not-found' => 'not-configured',
    _ => 'unknown',
  };

  /// Reads the `role` custom claim, defaulting to [UserRole.student].
  static Future<UserRole> defaultRoleResolver(fb.User user) async {
    try {
      final token = await user.getIdTokenResult();
      final claim = token.claims?['role']?.toString();
      if (claim != null) return UserRole.fromName(claim);
    } catch (_) {
      // A missing or unreadable token should not block sign-in; the student
      // role is the safe default in a teaching environment.
    }
    return UserRole.student;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
