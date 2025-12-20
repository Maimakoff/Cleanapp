import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  Session? _session;
  bool _loading = true;

  User? get user => _user;
  Session? get session => _session;
  bool get loading => _loading;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _init();
  }

  void _init() {
    try {
      _user = AuthService.currentUser;
      _session = AuthService.currentSession;
      _loading = false;
      notifyListeners();

      AuthService.authStateChanges.listen((AuthState state) {
        _user = state.session?.user;
        _session = state.session;
        _loading = false;
        notifyListeners();
      });
    } catch (e) {
      // If Supabase is not initialized, continue without auth
      _loading = false;
      _user = null;
      _session = null;
      notifyListeners();
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? name,
    String? phone,
    String? referralCode,
  }) async {
    try {
      final response = await AuthService.signUp(
        email: email,
        password: password,
        name: name,
        phone: phone,
        referralCode: referralCode,
      );
      _user = response.user;
      _session = response.session;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await AuthService.signIn(
        email: email,
        password: password,
      );
      _user = response.user;
      _session = response.session;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await AuthService.signOut();
    _user = null;
    _session = null;
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    await AuthService.resetPassword(email);
  }
}

