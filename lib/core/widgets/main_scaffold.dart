import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cleanapp/features/home/presentation/pages/home_page.dart';
import 'package:cleanapp/features/search/presentation/pages/search_page.dart';
import 'package:cleanapp/features/calendar/presentation/pages/calendar_page.dart';
import 'package:cleanapp/features/tariffs/presentation/pages/tariffs_page.dart';
import 'package:cleanapp/features/profile/presentation/pages/profile_page.dart';
import 'bottom_nav_bar.dart';

/// Корневой Scaffold с IndexedStack для стабильной навигации
/// 
/// Использует IndexedStack для сохранения состояния вкладок
/// и единый BottomNavBar, который не пересоздаётся при навигации
class MainScaffold extends StatefulWidget {
  final Widget child;

  const MainScaffold({
    super.key,
    required this.child,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  final List<Widget> _tabs = const [
    HomePage(),
    SearchPage(),
    CalendarPage(),
    TariffsPage(),
    ProfilePage(),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Определяем текущий индекс на основе маршрута
    final location = GoRouterState.of(context).uri.path;
    _updateCurrentIndex(location);
  }

  void _updateCurrentIndex(String location) {
    int newIndex;
    switch (location) {
      case '/':
        newIndex = 0;
        break;
      case '/search':
        newIndex = 1;
        break;
      case '/calendar':
        newIndex = 2;
        break;
      case '/tariffs':
        newIndex = 3;
        break;
      case '/profile':
        newIndex = 4;
        break;
      default:
        // Для других маршрутов определяем индекс по ближайшему родительскому маршруту
        if (location.startsWith('/profile')) {
          newIndex = 4;
        } else if (location.startsWith('/tariffs')) {
          newIndex = 3;
        } else if (location.startsWith('/calendar')) {
          newIndex = 2;
        } else if (location.startsWith('/search')) {
          newIndex = 1;
        } else {
          newIndex = 0;
        }
    }

    if (_currentIndex != newIndex) {
      setState(() {
        _currentIndex = newIndex;
      });
    }
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
    });

    // Навигация через GoRouter
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/search');
        break;
      case 2:
        context.go('/calendar');
        break;
      case 3:
        context.go('/tariffs');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  bool _shouldShowBottomNavBar() {
    final location = GoRouterState.of(context).uri.path;
    // Показываем BottomNavBar только для основных вкладок
    return location == '/' ||
        location == '/search' ||
        location == '/calendar' ||
        location == '/tariffs' ||
        location == '/profile' ||
        location.startsWith('/profile/') ||
        location.startsWith('/tariffs/') ||
        location.startsWith('/calendar/') ||
        location.startsWith('/search/');
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final showBottomNav = _shouldShowBottomNavBar();

    // Для основных вкладок используем IndexedStack
    // Страницы имеют Scaffold, но мы создаём единый Scaffold с IndexedStack
    // и BottomNavBar, который не пересоздаётся
    if (showBottomNav && _isMainTab(location)) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        body: IndexedStack(
          index: _currentIndex,
          children: _tabs,
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTabTapped: _onTabTapped,
        ),
      );
    }

    // Для других страниц (с подмаршрутами) показываем контент с BottomNavBar
    if (showBottomNav) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        body: widget.child,
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTabTapped: _onTabTapped,
        ),
      );
    }

    // Для страниц без BottomNavBar (booking, confirmation, etc.)
    return widget.child;
  }

  bool _isMainTab(String location) {
    return location == '/' ||
        location == '/search' ||
        location == '/calendar' ||
        location == '/tariffs' ||
        location == '/profile';
  }
}
