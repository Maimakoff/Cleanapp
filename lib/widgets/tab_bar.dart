import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomTabBar extends StatelessWidget {
  const CustomTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;

    return Container(
      height: 64, // Фиксированная высота
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false, // Отключаем SafeArea сверху, чтобы высота была фиксированной
        child: Container(
          height: 64, // Дополнительная фиксация высоты
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
            _TabItem(
              icon: Icons.home,
              label: 'Главная',
              path: '/',
              isActive: currentPath == '/',
            ),
            _TabItem(
              icon: Icons.search,
              label: 'Поиск',
              path: '/search',
              isActive: currentPath == '/search',
            ),
            _TabItem(
              icon: Icons.calendar_today,
              label: 'Календарь',
              path: '/calendar',
              isActive: currentPath == '/calendar',
            ),
            _TabItem(
              icon: Icons.star,
              label: 'Тарифы',
              path: '/tariffs',
              isActive: currentPath == '/tariffs',
            ),
            _TabItem(
              icon: Icons.person,
              label: 'Профиль',
              path: '/profile',
              isActive: currentPath == '/profile',
            ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String path;
  final bool isActive;

  const _TabItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () => context.go(path),
        splashColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        highlightColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[600],
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

