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
  final double totalPrice;
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

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      tariffId: json['tariff_id'] as String,
      tariffName: json['tariff_name'] as String,
      date: json['date'] as String,
      time: json['time'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String,
      area: json['area'] as int?,
      totalPrice: (json['total_price'] as num).toDouble(),
      discountPercentage: json['discount_percentage'] as int?,
      status: json['status'] as String,
      additionalOptions: json['additional_options'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'tariff_id': tariffId,
      'tariff_name': tariffName,
      'date': date,
      'time': time,
      'address': address,
      'phone': phone,
      'area': area,
      'total_price': totalPrice,
      'discount_percentage': discountPercentage,
      'status': status,
      'additional_options': additionalOptions,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class SelectedDate {
  final DateTime date;
  final String time;

  SelectedDate({required this.date, required this.time});

  Map<String, dynamic> toJson() {
    return {
      'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'time': time,
    };
  }
}

