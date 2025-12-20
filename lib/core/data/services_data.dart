import 'package:cleanapp/core/models/service.dart';
import 'package:cleanapp/core/models/tariff.dart';

class ServicesData {
  static final List<ServiceCategory> categories = [
    ServiceCategory(id: 'all', name: 'Все'),
    ServiceCategory(id: 'cleaning', name: 'Уборка квартиры'),
    ServiceCategory(id: 'subscription', name: 'Подписки'),
    ServiceCategory(id: 'furniture', name: 'Чистка мебели'),
    ServiceCategory(id: 'renovation', name: 'После ремонта'),
  ];

  static final List<Service> services = [
    Service(
      id: '1',
      name: 'Start — Разовая уборка',
      category: 'cleaning',
      icon: '✨',
      orders: 1234,
      rating: 4.8,
      price: '400 ₸/м²',
      isTop: true,
      keywords: ['уборка', 'разовая', 'старт', 'start', 'квартира', 'дом', 'чистка', 'клининг'],
      tariffId: 'start',
    ),
    Service(
      id: '2',
      name: 'Comfort — 4 уборки в месяц',
      category: 'subscription',
      icon: '🏠',
      orders: 2103,
      rating: 4.9,
      price: '350 ₸/м²',
      discount: 12,
      isTop: true,
      keywords: ['комфорт', 'comfort', 'подписка', '4 уборки', 'месяц', 'регулярная', 'еженедельная'],
      tariffId: 'comfort',
    ),
    Service(
      id: '3',
      name: 'Premium — 8 уборок в месяц',
      category: 'subscription',
      icon: '💎',
      orders: 987,
      rating: 4.9,
      price: '350 ₸/м²',
      discount: 12,
      isTop: true,
      keywords: ['премиум', 'premium', 'подписка', '8 уборок', 'месяц', 'регулярная'],
      tariffId: 'premium',
    ),
    Service(
      id: '4',
      name: 'Lux — 12 уборок в месяц',
      category: 'subscription',
      icon: '👑',
      orders: 654,
      rating: 4.9,
      price: '350 ₸/м²',
      discount: 12,
      keywords: ['люкс', 'lux', 'vip', 'подписка', '12 уборок', 'месяц', 'максимум'],
      tariffId: 'lux',
    ),
    Service(
      id: '5',
      name: 'Уборка после ремонта',
      category: 'renovation',
      icon: '🔧',
      orders: 789,
      rating: 4.9,
      price: '600 ₸/м²',
      isTop: true,
      keywords: ['ремонт', 'уборка', 'строительная', 'пыль', 'генеральная', 'после ремонта'],
      tariffId: 'after-renovation',
    ),
    Service(
      id: '6',
      name: 'Химчистка дивана (2-3 места)',
      category: 'furniture',
      icon: '🛋️',
      orders: 645,
      rating: 4.8,
      price: '25 000 ₸',
      isTop: true,
      keywords: ['химчистка', 'диван', 'мебель', 'чистка', 'обивка', 'маленький'],
      tariffId: 'furniture',
    ),
    Service(
      id: '7',
      name: 'Химчистка дивана (угловой/большой)',
      category: 'furniture',
      icon: '🛋️',
      orders: 534,
      rating: 4.9,
      price: '30 000 ₸',
      keywords: ['химчистка', 'диван', 'угловой', 'большой', 'мебель', 'чистка'],
      tariffId: 'furniture',
    ),
    Service(
      id: '8',
      name: 'Химчистка кресла',
      category: 'furniture',
      icon: '🪑',
      orders: 423,
      rating: 4.7,
      price: '10 000 ₸',
      keywords: ['химчистка', 'кресло', 'мебель', 'чистка', 'стул'],
      tariffId: 'furniture',
    ),
    Service(
      id: '9',
      name: 'Химчистка матраса',
      category: 'furniture',
      icon: '🛏️',
      orders: 312,
      rating: 4.8,
      price: '25 000 ₸',
      keywords: ['матрас', 'химчистка', 'кровать', 'спальня', 'двуспальный'],
      tariffId: 'furniture',
    ),
  ];

  static final List<Tariff> tariffs = [
    Tariff(
      id: 'start',
      name: 'Start',
      subtitle: 'Разовая уборка',
      price: '400 ₸/м²',
      icon: '✨',
      gradient: 'from-primary/20 to-primary/5',
      features: [
        '1 уборка',
        'Санузел: раковина, унитаз, ванна/душ',
        'Кухня: столешница, варочная панель, раковина',
        'Общее: пыль, полы, зеркала, мусор',
      ],
      description: 'Разовая уборка для первого знакомства с сервисом',
    ),
    Tariff(
      id: 'comfort',
      name: 'Comfort',
      subtitle: '4 уборки в месяц',
      price: '350 ₸/м²',
      icon: '🏠',
      gradient: 'from-success/20 to-success/5',
      popular: true,
      features: [
        '4 уборки в месяц',
        'Выберите любые 4 даты',
        'Расходники компании',
        'Постоянный слот',
      ],
      description: 'Подходит: занятые люди, небольшие квартиры',
      savings: 'Экономия 50 ₸/м²',
    ),
    Tariff(
      id: 'premium',
      name: 'Premium',
      subtitle: '8 уборок в месяц',
      price: '350 ₸/м²',
      icon: '💎',
      gradient: 'from-primary/20 to-primary/5',
      features: [
        '8 уборок в месяц',
        'Выберите любые 8 дат',
        'Приоритетное бронирование',
        'Расходники компании',
      ],
      description: 'Подходит: семьи, пары, квартиры под аренду',
      savings: 'Экономия 50 ₸/м²',
    ),
    Tariff(
      id: 'lux',
      name: 'Lux',
      subtitle: '12 уборок в месяц',
      price: '350 ₸/м²',
      icon: '👑',
      gradient: 'from-accent/20 to-accent/5',
      features: [
        '12 уборок в месяц',
        'Выберите любые 12 дат',
        'VIP обслуживание',
        'Приоритетное бронирование',
      ],
      description: 'Максимальная чистота каждый день',
      savings: 'Экономия 50 ₸/м²',
    ),
    Tariff(
      id: 'after-renovation',
      name: 'После ремонта',
      subtitle: 'Генеральная уборка',
      price: '600 ₸/м²',
      icon: '🔧',
      gradient: 'from-destructive/20 to-destructive/5',
      features: [
        'Уборка строительной пыли',
        'Мытье всех поверхностей',
        'Удаление следов краски и клея',
        'Вынос мусора после ремонта',
      ],
      description: 'Полная очистка квартиры после строительных работ',
    ),
    Tariff(
      id: 'furniture',
      name: 'Чистка мебели',
      subtitle: 'Профессиональная химчистка',
      price: 'от 5 000 ₸',
      icon: '🛋️',
      gradient: 'from-muted/50 to-muted/20',
      features: [
        'Диван 2–3 места — 25 000 ₸',
        'Диван угловой/большой — 30 000 ₸',
        'Кресло — 10 000 ₸',
        'Матрас двуспальный — 25 000 ₸',
      ],
      description: 'Обученный мастер, профессиональное оборудование',
    ),
  ];

  // Search services
  static List<Service> searchServices({
    String query = '',
    String categoryFilter = 'all',
    String quickFilter = 'all',
  }) {
    var filtered = List<Service>.from(services);

    // Apply category filter
    if (categoryFilter != 'all') {
      filtered = filtered.where((s) => s.category == categoryFilter).toList();
    }

    // Apply quick filter
    if (quickFilter == 'top') {
      filtered = filtered.where((s) => s.isTop).toList();
    } else if (quickFilter == 'popular') {
      filtered = filtered.where((s) => s.orders > 500).toList();
    } else if (quickFilter == 'discount') {
      filtered = filtered.where((s) => s.discount != null && s.discount! > 0).toList();
    }

    if (query.trim().isEmpty) {
      return filtered;
    }

    final queryLower = query.toLowerCase().trim();
    final queryWords = queryLower.split(RegExp(r'\s+'));

    final results = filtered.map((service) {
      int relevance = 0;
      final nameLower = service.name.toLowerCase();
      final keywordsLower = service.keywords.map((k) => k.toLowerCase()).toList();

      for (final word in queryWords) {
        // Exact match in name
        if (nameLower.contains(word)) {
          relevance += 100;
        }

        // Exact match in keywords
        if (keywordsLower.any((k) => k.contains(word))) {
          relevance += 50;
        }

        // Fuzzy match (simple contains check)
        final nameWords = nameLower.split(RegExp(r'\s+'));
        for (final nameWord in nameWords) {
          if (nameWord.contains(word) || word.contains(nameWord)) {
            relevance += 30;
          }
        }
      }

      // Bonus for popularity
      relevance += (service.orders / 100).round();

      // Bonus for top services
      if (service.isTop) relevance += 10;

      return {'service': service, 'relevance': relevance};
    }).toList();

    results.removeWhere((r) => r['relevance'] == 0);
    results.sort((a, b) => (b['relevance'] as int).compareTo(a['relevance'] as int));

    return results.map((r) => r['service'] as Service).toList();
  }
}

