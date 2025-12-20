import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  static SupabaseClient get client => _client;

  // Auth methods
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: metadata,
    );
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  static User? get currentUser => _client.auth.currentUser;
  static Session? get currentSession => _client.auth.currentSession;

  static Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Booking methods
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

  static Future<List<Map<String, dynamic>>> getBookedDates() async {
    final response = await _client
        .from('bookings')
        .select('date, time')
        .eq('status', 'confirmed');

    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Booking> createBooking({
    required String tariffId,
    required String tariffName,
    required List<Map<String, dynamic>> dates,
    required String address,
    required String phone,
    int? area,
    List<String>? additionalOptions,
    String? promoCode,
    bool useReferralBonus = false,
  }) async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw Exception('User not authenticated');
    }

    // Call edge function for secure order creation
    final response = await _client.functions.invoke(
      'create-order',
      body: {
        'tariff_id': tariffId,
        'tariff_name': tariffName,
        'dates': dates,
        'address': address,
        'phone': phone,
        'area': area,
        'additional_options': additionalOptions,
        'promo_code': promoCode,
        'use_referral_bonus': useReferralBonus,
      },
    );

    if (response.status != 200) {
      throw Exception(response.data['error'] ?? 'Failed to create booking');
    }

    return Booking.fromJson(response.data as Map<String, dynamic>);
  }

  // Referral bonuses
  static Future<List<Map<String, dynamic>>> getReferralBonuses() async {
    final user = currentUser;
    if (user == null) return [];

    final response = await _client
        .from('referral_bonuses')
        .select()
        .eq('user_id', user.id)
        .eq('is_used', false)
        .gte('expires_at', DateTime.now().toIso8601String())
        .order('discount_percentage', ascending: false)
        .limit(1);

    return List<Map<String, dynamic>>.from(response);
  }
}

