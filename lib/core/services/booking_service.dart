import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cleanapp/core/config/app_config.dart';
import 'package:cleanapp/core/models/booking.dart';
import 'package:cleanapp/core/services/supabase_service.dart';

class BookingService {
  // Create order via edge function
  static Future<Map<String, dynamic>> createOrder({
    required String tariffId,
    required String tariffName,
    required List<SelectedDate> dates,
    required String address,
    required String phone,
    int? area,
    List<String>? additionalOptions,
    String? promoCode,
    bool useReferralBonus = false,
  }) async {
    final session = SupabaseService.currentSession;
    if (session == null) {
      throw Exception('Not authenticated');
    }

    final url = Uri.parse('${AppConfig.apiBaseUrl}/create-order');
    
    final body = jsonEncode({
      'tariff_id': tariffId,
      'tariff_name': tariffName,
      'dates': dates.map((d) => d.toJson()).toList(),
      'address': address,
      'phone': phone,
      'area': area,
      'additional_options': additionalOptions,
      'promo_code': promoCode,
      'use_referral_bonus': useReferralBonus,
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${session.accessToken}',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to create order');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // Calculate price with discounts
  static int calculatePrice({
    required int basePrice,
    required List<SelectedDate> dates,
    int? promoDiscount,
    int? referralDiscount,
  }) {
    // Friday discount (10% on Fridays)
    final fridayDates = dates.where((d) => d.date.weekday == 5).length;
    final fridayDiscount = (basePrice / dates.length * 0.1 * fridayDates).round();

    // Global discount (promo or referral)
    final globalDiscountPercent = (promoDiscount ?? 0) > (referralDiscount ?? 0)
        ? promoDiscount ?? 0
        : referralDiscount ?? 0;
    
    final globalDiscount = (basePrice * globalDiscountPercent / 100).round();

    // Apply the better discount
    if (globalDiscountPercent > 10) {
      return basePrice - globalDiscount;
    } else if (globalDiscountPercent == 10 && fridayDates > 0) {
      final fridaySavings = (basePrice / dates.length * 0.1 * fridayDates).round();
      return globalDiscount >= fridaySavings
          ? basePrice - globalDiscount
          : basePrice - fridaySavings;
    } else if (fridayDates > 0) {
      return basePrice - fridayDiscount;
    } else if (globalDiscountPercent > 0) {
      return basePrice - globalDiscount;
    }

    return basePrice;
  }
}

