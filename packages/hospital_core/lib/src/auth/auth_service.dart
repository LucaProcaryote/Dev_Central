import 'package:flutter/foundation.dart';

import '../models/hospital_user.dart';

/// Raised when a sign-in attempt fails, carrying a code the UI can localise.
class AuthFailure implements Exception {
  const AuthFailure(this.code, [this.details]);

  /// One of: `invalid-credentials`, `user-not-found`, `network`,
  /// `not-configured`, `unknown`.
  final String code;
  final String? details;

  @override
  String toString() => 'AuthFailure($code): ${details ?? ''}';
}

/// Authentication, independent of whether Firebase is actually wired up.
///
/// Screens depend on this type only, so the same login page works in the
/// classroom (demo accounts, no network) and against the real
/// `my-hospital-2026` Firebase project.
abstract class AuthService extends ChangeNotifier {
  HospitalUser? get currentUser;

  bool get isSignedIn => currentUser != null;

  /// True once the service has finished restoring any persisted session.
  bool get isReady;

  Future<void> initialize();

  Future<HospitalUser> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  /// Accounts offered on the login screen as one-click options. Empty when the
  /// backing service has no such concept (i.e. real Firebase).
  List<HospitalUser> get quickSignInAccounts => const <HospitalUser>[];

  /// Signs in directly as [user]. Only supported in demo mode.
  Future<HospitalUser> signInAs(HospitalUser user) =>
      throw const AuthFailure('not-supported');
}
