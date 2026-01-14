import 'package:cleanapp/core/domain/repositories/booking_repository.dart';
import 'package:cleanapp/core/domain/entities/booking.dart';
import 'package:cleanapp/core/services/supabase_service.dart';
import 'package:cleanapp/core/models/booking.dart' as data_model;

/// Implementation of BookingRepository using Supabase.
/// Maps between domain entities and data models.
class BookingRepositoryImpl implements BookingRepository {
  @override
  Future<List<Booking>> getBookings() async {
    final dataBookings = await SupabaseService.getBookings();
    return dataBookings.map(_toDomainEntity).toList();
  }

  @override
  Future<List<Booking>> getUserBookings(String userId) async {
    final dataBookings = await SupabaseService.getUserBookings(userId);
    return dataBookings.map(_toDomainEntity).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getBookedDates() async {
    return await SupabaseService.getBookedDates();
  }

  @override
  Future<List<Map<String, dynamic>>> getBookedSlots() async {
    return await SupabaseService.getBookedSlots();
  }

  @override
  Future<Booking> createBooking({
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

    // Calculate discount percentage
    int? discountPercentage;
    if (promoCode != null && promoCode.isNotEmpty) {
      if (promoCode.toUpperCase() == 'WELCOME') {
        discountPercentage = 10;
      }
    }

    // Create bookings for each date
    final List<data_model.Booking> createdBookings = [];
    
    for (final selectedDate in dates) {
      final bookingData = {
        'user_id': user.id,
        'tariff_id': tariffId,
        'tariff_name': tariffName,
        'date': selectedDate.date.toIso8601String().split('T')[0], // Format YYYY-MM-DD
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

      createdBookings.add(data_model.Booking.fromJson(Map<String, dynamic>.from(response)));
    }

    // Return the first created booking
    if (createdBookings.isNotEmpty) {
      return _toDomainEntity(createdBookings.first);
    }

    throw Exception('Failed to create booking');
  }

  @override
  Future<void> updateBookingStatus(String bookingId, String status) async {
    await SupabaseService.updateBookingStatus(bookingId, status);
  }

  @override
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    return await SupabaseService.getUserStats();
  }

  /// Maps data model to domain entity
  Booking _toDomainEntity(data_model.Booking dataBooking) {
    return Booking(
      id: dataBooking.id,
      userId: dataBooking.userId,
      tariffId: dataBooking.tariffId,
      tariffName: dataBooking.tariffName,
      date: dataBooking.date,
      time: dataBooking.time,
      address: dataBooking.address,
      phone: dataBooking.phone,
      area: dataBooking.area,
      totalPrice: dataBooking.totalPrice,
      discountPercentage: dataBooking.discountPercentage,
      status: dataBooking.status,
      additionalOptions: dataBooking.additionalOptions,
      createdAt: dataBooking.createdAt,
      updatedAt: dataBooking.updatedAt,
    );
  }
}
