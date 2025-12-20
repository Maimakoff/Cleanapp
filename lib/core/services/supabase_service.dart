import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cleanapp/core/models/booking.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  static SupabaseClient get client => _client;

  // Auth methods
  static User? get currentUser => _client.auth.currentUser;
  static Session? get currentSession => _client.auth.currentSession;

  // Auth state stream
  static Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Sign up
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    try {
      return await _client.auth.signUp(
        email: email,
        password: password,
        data: data,
      );
    } catch (e) {
      // Check if Supabase is not initialized
      if (e.toString().contains('Supabase') || 
          e.toString().contains('not initialized')) {
        throw Exception(
          'Supabase не настроен. Создайте файл .env с SUPABASE_URL и SUPABASE_ANON_KEY'
        );
      }
      rethrow;
    }
  }

  // Sign in
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      // Check if Supabase is not initialized
      if (e.toString().contains('Supabase') || 
          e.toString().contains('not initialized')) {
        throw Exception(
          'Supabase не настроен. Создайте файл .env с SUPABASE_URL и SUPABASE_ANON_KEY'
        );
      }
      rethrow;
    }
  }

  // Sign out
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Reset password
  static Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  // Get bookings
  static Future<List<Booking>> getBookings() async {
    final response = await _client
        .from('bookings')
        .select()
        .order('created_at', ascending: false);

    if (response.isEmpty) return [];

    return (response as List)
        .map((json) => Booking.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Get user bookings
  static Future<List<Booking>> getUserBookings(String userId) async {
    final response = await _client
        .from('bookings')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    if (response.isEmpty) return [];

    return (response as List)
        .map((json) => Booking.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Get available dates/times
  static Future<List<Map<String, dynamic>>> getBookedSlots() async {
    final response = await _client
        .from('bookings')
        .select('date, time')
        .eq('status', 'new')
        .or('status.eq.accepted');

    return (response as List).cast<Map<String, dynamic>>();
  }

  // Get referral bonuses
  static Future<List<Map<String, dynamic>>> getReferralBonuses(String userId) async {
    final response = await _client
        .from('referral_bonuses')
        .select()
        .eq('user_id', userId)
        .eq('is_used', false)
        .gte('expires_at', DateTime.now().toIso8601String())
        .order('discount_percentage', ascending: false)
        .limit(1);

    return (response as List).cast<Map<String, dynamic>>();
  }
}

