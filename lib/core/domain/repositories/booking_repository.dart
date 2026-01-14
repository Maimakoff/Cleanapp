import '../entities/booking.dart';

/// Repository interface for booking operations.
/// This abstracts the data source from the domain layer.
abstract class BookingRepository {
  /// Get all bookings
  Future<List<Booking>> getBookings();

  /// Get bookings for a specific user
  Future<List<Booking>> getUserBookings(String userId);

  /// Get booked dates (for calendar display)
  Future<List<Map<String, dynamic>>> getBookedDates();

  /// Get booked time slots
  Future<List<Map<String, dynamic>>> getBookedSlots();

  /// Create a new booking
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
  });

  /// Update booking status
  Future<void> updateBookingStatus(String bookingId, String status);

  /// Get user statistics (level, points, etc.)
  Future<Map<String, dynamic>> getUserStats(String userId);
}
