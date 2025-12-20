class Tariff {
  final String id;
  final String name;
  final String subtitle;
  final String price;
  final String icon;
  final String gradient;
  final List<String> features;
  final String? description;
  final bool popular;
  final String? savings;

  Tariff({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.price,
    required this.icon,
    required this.gradient,
    required this.features,
    this.description,
    this.popular = false,
    this.savings,
  });

  factory Tariff.fromJson(Map<String, dynamic> json) {
    return Tariff(
      id: json['id'] as String,
      name: json['name'] as String,
      subtitle: json['subtitle'] as String,
      price: json['price'] as String,
      icon: json['icon'] as String,
      gradient: json['gradient'] as String,
      features: List<String>.from(json['features'] as List),
      description: json['description'] as String?,
      popular: json['popular'] as bool? ?? false,
      savings: json['savings'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subtitle': subtitle,
      'price': price,
      'icon': icon,
      'gradient': gradient,
      'features': features,
      'description': description,
      'popular': popular,
      'savings': savings,
    };
  }
}

