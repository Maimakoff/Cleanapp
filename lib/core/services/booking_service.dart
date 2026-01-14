import 'package:cleanapp/core/models/booking.dart';
import 'package:cleanapp/core/services/supabase_service.dart';

class BookingService {
  // Create order directly in Supabase table
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
    String? paymentMethod,
    int? totalPrice,
  }) async {
    final user = SupabaseService.currentUser;
    if (user == null) {
      throw Exception('Not authenticated');
    }

    try {
      // Вычисляем процент скидки
      int? discountPercentage;
      if (promoCode != null && promoCode.isNotEmpty) {
        // Проверяем промокод (можно расширить логику)
        if (promoCode.toUpperCase() == 'WELCOME') {
          discountPercentage = 10;
        }
      }

      // Создаем записи для каждой даты
      final List<Map<String, dynamic>> createdBookings = [];
      
      for (final selectedDate in dates) {
        final bookingData = {
          'user_id': user.id,
          'tariff_id': tariffId,
          'tariff_name': tariffName,
          'date': selectedDate.date.toIso8601String().split('T')[0], // Формат YYYY-MM-DD
          'time': selectedDate.time,
          'address': address,
          'phone': phone,
          'area': area,
          'total_price': totalPrice?.toDouble() ?? 0.0,
          'discount_percentage': discountPercentage,
          'status': 'pending',
          'additional_options': additionalOptions != null && additionalOptions.isNotEmpty
              ? additionalOptions
              : null,
          'payment_method': paymentMethod,
        };

        final response = await SupabaseService.client
            .from('bookings')
            .insert(bookingData)
            .select()
            .single()
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                throw Exception('Превышено время ожидания. Проверьте интернет-соединение');
              },
            );

        createdBookings.add(Map<String, dynamic>.from(response));
      }

      return {
        'success': true,
        'bookings': createdBookings,
        'count': createdBookings.length,
      };
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      
      // Обработка ошибки "таблица не найдена"
      if (errorStr.contains('could not find the table') ||
          errorStr.contains('pgrst205') ||
          errorStr.contains('relation') && errorStr.contains('does not exist') ||
          errorStr.contains('table') && errorStr.contains('not found')) {
        throw Exception(
          'Таблица bookings не найдена в базе данных. '
          'Пожалуйста, выполните SQL скрипт из файла database_setup.sql в Supabase SQL Editor.'
        );
      }
      
      // Обработка ошибок аутентификации
      if (errorStr.contains('not authenticated') ||
          errorStr.contains('unauthorized') ||
          errorStr.contains('jwt') ||
          errorStr.contains('401')) {
        throw Exception('Сессия истекла. Пожалуйста, войдите в аккаунт снова');
      }
      
      // Обработка ошибок валидации данных
      if (errorStr.contains('violates') ||
          errorStr.contains('constraint') ||
          errorStr.contains('foreign key') ||
          errorStr.contains('not null') ||
          errorStr.contains('check constraint')) {
        throw Exception('Некорректные данные. Проверьте введенную информацию');
      }
      
      // Обработка ошибок RLS (Row Level Security)
      if (errorStr.contains('row-level security') ||
          errorStr.contains('policy') ||
          errorStr.contains('permission denied') ||
          errorStr.contains('new row violates')) {
        throw Exception('Недостаточно прав для создания заказа. Проверьте настройки безопасности в Supabase');
      }
      
      // Обработка сетевых ошибок
      if (errorStr.contains('socketexception') ||
          errorStr.contains('network') ||
          errorStr.contains('connection') ||
          errorStr.contains('failed host lookup') ||
          errorStr.contains('connection refused')) {
        throw Exception('Ошибка сети. Проверьте интернет-соединение и попробуйте снова');
      }
      
      // Обработка таймаутов
      if (errorStr.contains('timeout') ||
          errorStr.contains('timed out') ||
          errorStr.contains('превышено время ожидания')) {
        throw Exception('Превышено время ожидания. Проверьте интернет-соединение');
      }
      
      // Обработка ошибок Supabase
      if (errorStr.contains('supabase') && 
          (errorStr.contains('not initialized') ||
           errorStr.contains('_isinitialized'))) {
        throw Exception('Supabase не настроен. Проверьте конфигурацию приложения');
      }
      
      // Общая обработка ошибок
      final errorMessage = e.toString();
      if (errorMessage.contains('Exception: ')) {
        rethrow;
      }
      
      throw Exception('Ошибка при создании заказа: ${errorMessage.replaceAll('Exception: ', '')}');
    }
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

