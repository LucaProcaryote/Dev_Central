import '../models/hospital_user.dart';
import '../seed/seed_users.dart';
import 'auth_service.dart';

/// Sign-in without any backend.
///
/// The staff list comes from the seed dataset. Any password is accepted - this
/// is a teaching hospital with fictive patients, and making students memorise
/// credentials adds nothing. The login screen makes the mode obvious so nobody
/// mistakes it for real security.
class DemoAuthService extends AuthService {
  DemoAuthService({List<HospitalUser>? accounts})
      : _accounts = accounts ?? seedUsers;

  final List<HospitalUser> _accounts;

  HospitalUser? _currentUser;
  bool _isReady = false;

  @override
  HospitalUser? get currentUser => _currentUser;

  @override
  bool get isReady => _isReady;

  @override
  List<HospitalUser> get quickSignInAccounts => List.unmodifiable(_accounts);

  @override
  Future<void> initialize() async {
    _isReady = true;
    notifyListeners();
  }

  @override
  Future<HospitalUser> signIn({
    required String email,
    required String password,
  }) async {
    // A short delay keeps the loading states in the UI honest, so students see
    // the same spinner they would with a real network round trip.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final normalised = email.trim().toLowerCase();
    for (final account in _accounts) {
      if (account.email.toLowerCase() == normalised) {
        _currentUser = account;
        notifyListeners();
        return account;
      }
    }
    throw const AuthFailure('user-not-found');
  }

  @override
  Future<HospitalUser> signInAs(HospitalUser user) async {
    _currentUser = user;
    notifyListeners();
    return user;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    notifyListeners();
  }
}
