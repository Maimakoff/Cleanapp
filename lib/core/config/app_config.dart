import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Supabase Configuration
  // Note: Supabase is initialized in main.dart from .env file
  // These are fallback values if .env is not available
  static String get supabaseUrl => 
      dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => 
      dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  
  // App Configuration
  static const String appName = 'Cleanapp';
  static const String appTagline = 'Чистота в один клик';
  
  // API Configuration
  static String get apiBaseUrl => 
      supabaseUrl.isNotEmpty 
          ? '$supabaseUrl/functions/v1'
          : '';
  
  // Time Slots
  static const List<String> timeSlots = [
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
    '19:00',
    '20:00',
  ];
  
  // Promo Code
  static const String welcomePromoCode = 'WELCOME';
  static const int welcomePromoDiscount = 10;
  
  // Friday Discount
  static const int fridayDiscountPercent = 10;
}

