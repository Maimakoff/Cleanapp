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
      orders: json['orders'] as int,
      rating: (json['rating'] as num).toDouble(),
      price: json['price'] as String,
      discount: json['discount'] as int?,
      isTop: json['isTop'] ?? false,
      keywords: List<String>.from(json['keywords'] as List),
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

class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});
}

class ServiceData {
  static final categories = [
    Category(id: "all", name: "Все"),
    Category(id: "cleaning", name: "Уборка квартиры"),
    Category(id: "subscription", name: "Подписки"),
    Category(id: "furniture", name: "Чистка мебели"),
    Category(id: "renovation", name: "После ремонта"),
  ];

  static final services = [
    Service(
      id: "1",
      name: "Start — Разовая уборка",
      category: "cleaning",
      icon: "✨",
      orders: 1234,
      rating: 4.8,
      price: "400 ₸/м²",
      isTop: true,
      keywords: ["уборка", "разовая", "старт", "start", "квартира", "дом", "чистка", "клининг"],
      tariffId: "start",
    ),
    Service(
      id: "2",
      name: "Comfort — 4 уборки в месяц",
      category: "subscription",
      icon: "🏠",
      orders: 2103,
      rating: 4.9,
      price: "350 ₸/м²",
      discount: 12,
      isTop: true,
      keywords: ["комфорт", "comfort", "подписка", "4 уборки", "месяц", "регулярная", "еженедельная"],
      tariffId: "comfort",
    ),
    Service(
      id: "3",
      name: "Premium — 8 уборок в месяц",
      category: "subscription",
      icon: "💎",
      orders: 987,
      rating: 4.9,
      price: "350 ₸/м²",
      discount: 12,
      isTop: true,
      keywords: ["премиум", "premium", "подписка", "8 уборок", "месяц", "регулярная"],
      tariffId: "premium",
    ),
    Service(
      id: "4",
      name: "Lux — 12 уборок в месяц",
      category: "subscription",
      icon: "👑",
      orders: 654,
      rating: 4.9,
      price: "350 ₸/м²",
      discount: 12,
      keywords: ["люкс", "lux", "vip", "подписка", "12 уборок", "месяц", "максимум"],
      tariffId: "lux",
    ),
    Service(
      id: "5",
      name: "Уборка после ремонта",
      category: "renovation",
      icon: "🔧",
      orders: 789,
      rating: 4.9,
      price: "600 ₸/м²",
      isTop: true,
      keywords: ["ремонт", "уборка", "строительная", "пыль", "генеральная", "после ремонта"],
      tariffId: "after-renovation",
    ),
    Service(
      id: "6",
      name: "Химчистка дивана (2-3 места)",
      category: "furniture",
      icon: "🛋️",
      orders: 645,
      rating: 4.8,
      price: "25 000 ₸",
      isTop: true,
      keywords: ["химчистка", "диван", "мебель", "чистка", "обивка", "маленький"],
      tariffId: "furniture",
    ),
    Service(
      id: "7",
      name: "Химчистка дивана (угловой/большой)",
      category: "furniture",
      icon: "🛋️",
      orders: 534,
      rating: 4.9,
      price: "30 000 ₸",
      keywords: ["химчистка", "диван", "угловой", "большой", "мебель", "чистка"],
      tariffId: "furniture",
    ),
    Service(
      id: "8",
      name: "Химчистка кресла",
      category: "furniture",
      icon: "🪑",
      orders: 423,
      rating: 4.7,
      price: "10 000 ₸",
      keywords: ["химчистка", "кресло", "мебель", "чистка", "стул"],
      tariffId: "furniture",
    ),
    Service(
      id: "9",
      name: "Химчистка матраса",
      category: "furniture",
      icon: "🛏️",
      orders: 312,
      rating: 4.8,
      price: "25 000 ₸",
      keywords: ["матрас", "химчистка", "кровать", "спальня", "двуспальный"],
      tariffId: "furniture",
    ),
  ];
}

