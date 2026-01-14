/// Domain entity for Booking.
/// This is a pure domain model without data source dependencies.
class Booking {
  final String id;
  final String userId;
  final String tariffId;
  final String tariffName;
  final String date;
  final String time;
  final String address;
  final String phone;
  final int? area;
  final int totalPrice;
  final int? discountPercentage;
  final String status;
  final Map<String, dynamic>? additionalOptions;
  final DateTime createdAt;
  final DateTime updatedAt;

  Booking({
    required this.id,
    required this.userId,
    required this.tariffId,
    required this.tariffName,
    required this.date,
    required this.time,
    required this.address,
    required this.phone,
    this.area,
    required this.totalPrice,
    this.discountPercentage,
    required this.status,
    this.additionalOptions,
    required this.createdAt,
    required this.updatedAt,
  });
}

/// Value object for selected booking date and time
class SelectedDate {
  final DateTime date;
  final String time;

  SelectedDate({
    required this.date,
    required this.time,
  });
}
