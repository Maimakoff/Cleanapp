import 'package:flutter/material.dart';

/// Нижняя панель навигации с фиксированной высотой и оптимизацией перерисовок
/// 
/// Использует RepaintBoundary для предотвращения лишних перерисовок
/// и фиксированную высоту для стабильного позиционирования
/// 
/// Создаётся ОДИН РАЗ и не пересоздаётся при навигации
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabTapped;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabTapped,
  });

  @override
  Widget build(BuildContext context) {
    // Используем RepaintBoundary для предотвращения лишних перерисовок
    return RepaintBoundary(
      child: Container(
        // Фиксированная высота контента панели (без SafeArea для стабильности)
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
                onTap: () => onTabTapped(0),
              ),
              _NavItem(
                icon: Icons.search,
                label: 'Поиск',
                isActive: currentIndex == 1,
                onTap: () => onTabTapped(1),
              ),
              _NavItem(
                icon: Icons.calendar_today,
                label: 'Календарь',
                isActive: currentIndex == 2,
                onTap: () => onTabTapped(2),
              ),
              _NavItem(
                icon: Icons.star,
                label: 'Тарифы',
                isActive: currentIndex == 3,
                onTap: () => onTabTapped(3),
              ),
              _NavItem(
                icon: Icons.person,
                label: 'Профиль',
                isActive: currentIndex == 4,
                onTap: () => onTabTapped(4),
              ),
          ],
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
                  // Фиксированная высота текста БЕЗ анимации для стабильности layout
                  SizedBox(
                    height: 14,
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                        color: isActive
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[600],
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

