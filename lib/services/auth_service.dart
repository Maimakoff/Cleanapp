import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AuthService {
  static User? get currentUser => SupabaseService.currentUser;
  static Session? get currentSession => SupabaseService.currentSession;

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? name,
    String? phone,
    String? referralCode,
  }) async {
    return await SupabaseService.signUp(
      email: email,
      password: password,
      metadata: {
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
    return await SupabaseService.signIn(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await SupabaseService.signOut();
  }

  static Future<void> resetPassword(String email) async {
    await SupabaseService.client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'cleanapp://reset-password',
    );
  }

  static Stream<AuthState> get authStateChanges =>
      SupabaseService.authStateChanges;
}

