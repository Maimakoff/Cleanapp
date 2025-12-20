class Service {
  final String id;
  final String name;
  final String category;
  final String icon;
  final int orders;
  final double rating;
  final String price;
  final int? discount;
  final bool isTop;
  final List<String> keywords;
  final String? tariffId;

  Service({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
    required this.orders,
    required this.rating,
    required this.price,
    this.discount,
    this.isTop = false,
    required this.keywords,
    this.tariffId,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      icon: json['icon'] as String,
      orders: json['orders'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      price: json['price'] as String,
      discount: json['discount'] as int?,
      isTop: json['isTop'] as bool? ?? false,
      keywords: List<String>.from(json['keywords'] as List? ?? []),
      tariffId: json['tariffId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'icon': icon,
      'orders': orders,
      'rating': rating,
      'price': price,
      'discount': discount,
      'isTop': isTop,
      'keywords': keywords,
      'tariffId': tariffId,
    };
  }
}

class ServiceCategory {
  final String id;
  final String name;

  ServiceCategory({
    required this.id,
    required this.name,
  });
}

