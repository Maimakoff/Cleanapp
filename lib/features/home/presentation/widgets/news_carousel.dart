import 'package:flutter/material.dart';
import 'dart:async';

class NewsCarousel extends StatefulWidget {
  const NewsCarousel({super.key});

  @override
  State<NewsCarousel> createState() => _NewsCarouselState();
}

class _NewsCarouselState extends State<NewsCarousel> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  Timer? _timer;

  final List<Map<String, dynamic>> _newsItems = [
    {
      'id': 1,
      'title': 'Скидка 10% по пятницам!',
      'description': 'Закажите уборку на пятницу и получите скидку',
      'gradient': [0xFFD1FAE5, 0xFFA7F3D0], // Зеленые градиенты
      'image': 'assets/promo/banner_friday.png',
    },
    {
      'id': 2,
      'title': 'Экспресс-уборка за 2 часа',
      'description': 'Быстрая и качественная уборка в любое время',
      'gradient': [0xFFD1FAE5, 0xFFA7F3D0], // Зеленые градиенты
      'image': 'assets/promo/banner_express.png',
    },
    {
      'id': 3,
      'title': 'Приведи друга — получи скидку!',
      'description': 'Вы и ваш друг получите бонусы до 15%',
      'gradient': [0xFFFEF3C7, 0xFFFDE68A], // Желто-зеленый для акции
      'image': 'assets/promo/banner_friend.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentIndex < _newsItems.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: _newsItems.length,
            itemBuilder: (context, index) {
              final item = _newsItems[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(item['gradient'][0]),
                      Color(item['gradient'][1]),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Фоновое изображение
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        item['image'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Если изображение не найдено, показываем градиент
                          return Container();
                        },
                      ),
                    ),
                    // Градиентный оверлей для лучшей читаемости текста
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.0),
                            Colors.black.withValues(alpha: 0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    // Текст поверх изображения
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item['title'],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: Offset(1, 1),
                                  blurRadius: 3,
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['description'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.95),
                              shadows: const [
                                Shadow(
                                  offset: Offset(1, 1),
                                  blurRadius: 2,
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _newsItems.length,
            (index) => Container(
              width: _currentIndex == index ? 32 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: _currentIndex == index
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

