import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Нижняя панель навигации с фиксированной высотой и оптимизацией перерисовок
/// 
/// Использует RepaintBoundary для предотвращения лишних перерисовок
/// и фиксированную высоту для стабильного позиционирования
class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    // Используем RepaintBoundary для предотвращения лишних перерисовок
    return RepaintBoundary(
      child: SafeArea(
        top: false, // Отключаем SafeArea сверху, так как панель внизу
        child: Container(
          // Фиксированная высота контента панели
          height: 64,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home,
                label: 'Главная',
                isActive: currentIndex == 0,
                onTap: () => context.go('/'),
              ),
              _NavItem(
                icon: Icons.search,
                label: 'Поиск',
                isActive: currentIndex == 1,
                onTap: () => context.go('/search'),
              ),
              _NavItem(
                icon: Icons.calendar_today,
                label: 'Календарь',
                isActive: currentIndex == 2,
                onTap: () => context.go('/calendar'),
              ),
              _NavItem(
                icon: Icons.star,
                label: 'Тарифы',
                isActive: currentIndex == 3,
                onTap: () => context.go('/tariffs'),
              ),
              _NavItem(
                icon: Icons.person,
                label: 'Профиль',
                isActive: currentIndex == 4,
                onTap: () => context.go('/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Элемент навигации с плавной анимацией переключения состояния
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Используем RepaintBoundary для каждого элемента для оптимизации
    return RepaintBoundary(
      child: Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              // Фиксированная высота для стабильности layout
              height: 64,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Иконка с фиксированным размером
                  Icon(
                    icon,
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[600],
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  // Фиксированная высота текста для предотвращения изменения layout
                  SizedBox(
                    height: 14,
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                        color: isActive
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[600],
                      ),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

