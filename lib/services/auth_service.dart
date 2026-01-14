import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cleanapp/core/services/supabase_service.dart';

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
    return await SupabaseService.signIn(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await SupabaseService.signOut();
  }

  static Future<void> resetPassword(String email) async {
    try {
    await SupabaseService.client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'cleanapp://reset-password',
    );
    } catch (e) {
      if (e.toString().contains('Supabase') || 
          e.toString().contains('not initialized') ||
          e.toString().contains('_isInitialized')) {
        throw Exception(
          'Supabase не настроен. Создайте файл .env с SUPABASE_URL и SUPABASE_ANON_KEY'
        );
      }
      rethrow;
    }
  }

  static Stream<AuthState> get authStateChanges =>
      SupabaseService.authStateChanges;
}

