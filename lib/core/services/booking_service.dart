import 'package:cleanapp/core/models/booking.dart';
import 'package:cleanapp/core/domain/repositories/booking_repository.dart';
import 'package:cleanapp/core/providers/repository_providers.dart';
import 'package:cleanapp/core/providers/provider_container_helper.dart';
import 'package:cleanapp/core/domain/entities/booking.dart' as domain;

/// Service layer for booking operations.
/// Uses BookingRepository interface to abstract data source.
/// Maintains static API for backward compatibility.
class BookingService {
  // Get repository from Riverpod provider
  static BookingRepository get _repository =>
      ProviderContainerHelper.container.read(bookingRepositoryProvider);

  // Create order using BookingRepository
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
    try {
      // Convert data model SelectedDate to domain SelectedDate
      final domainDates = dates.map((d) => domain.SelectedDate(
        date: d.date,
        time: d.time,
      )).toList();

      // Create bookings for each date using repository
      final List<Map<String, dynamic>> createdBookings = [];
      
      for (final selectedDate in domainDates) {
        final booking = await _repository.createBooking(
          tariffId: tariffId,
          tariffName: tariffName,
          dates: [selectedDate], // Create one booking per date
          address: address,
          phone: phone,
          area: area,
          additionalOptions: additionalOptions,
          promoCode: promoCode,
          useReferralBonus: useReferralBonus,
          paymentMethod: paymentMethod,
          totalPrice: totalPrice,
        );

        // Convert domain entity back to data model format for response
        createdBookings.add({
          'id': booking.id,
          'user_id': booking.userId,
          'tariff_id': booking.tariffId,
          'tariff_name': booking.tariffName,
          'date': booking.date,
          'time': booking.time,
          'address': booking.address,
          'phone': booking.phone,
          'area': booking.area,
          'total_price': booking.totalPrice,
          'discount_percentage': booking.discountPercentage,
          'status': booking.status,
          'additional_options': booking.additionalOptions,
          'created_at': booking.createdAt.toIso8601String(),
          'updated_at': booking.updatedAt.toIso8601String(),
        });
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

