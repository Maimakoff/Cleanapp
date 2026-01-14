import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cleanapp/core/domain/repositories/auth_repository.dart';
import 'package:cleanapp/core/providers/repository_providers.dart';
import 'package:cleanapp/core/providers/provider_container_helper.dart';

/// Service layer for authentication operations.
/// Uses AuthRepository interface to abstract data source.
/// Maintains static API for backward compatibility.
class AuthService {
  // Get repository from Riverpod provider
  static AuthRepository get _repository =>
      ProviderContainerHelper.container.read(authRepositoryProvider);

  static User? get currentUser => _repository.getCurrentUser();
  static Session? get currentSession => _repository.getCurrentSession();

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? name,
    String? phone,
    String? referralCode,
  }) async {
    return await _repository.signUp(
      email: email,
      password: password,
      data: {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (referralCode != null) 'referral_code': referralCode.toUpperCase(),
      },
    );
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _repository.signIn(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await _repository.signOut();
  }

  static Future<void> resetPassword(String email) async {
    await _repository.resetPassword(email);
  }

  static Stream<AuthState> get authStateChanges =>
      _repository.getAuthStateChanges();
}
