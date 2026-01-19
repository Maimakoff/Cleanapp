import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:cleanapp/features/auth/presentation/pages/auth_page.dart';
import 'package:cleanapp/features/home/presentation/pages/home_page.dart';
import 'package:cleanapp/features/search/presentation/pages/search_page.dart';
import 'package:cleanapp/features/calendar/presentation/pages/calendar_page.dart';
import 'package:cleanapp/features/tariffs/presentation/pages/tariffs_page.dart';
import 'package:cleanapp/features/tariffs/presentation/pages/tariff_detail_page.dart';
import 'package:cleanapp/features/booking/presentation/pages/booking_page.dart';
import 'package:cleanapp/features/booking/presentation/pages/confirmation_page.dart';
import 'package:cleanapp/features/profile/presentation/pages/profile_page.dart';
import 'package:cleanapp/features/profile/presentation/pages/settings_page.dart';
import 'package:cleanapp/features/profile/presentation/pages/orders_history_page.dart';
import 'package:cleanapp/features/profile/presentation/pages/order_detail_page.dart';
import 'package:cleanapp/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:cleanapp/features/cleaner/presentation/pages/cleaner_dashboard_page.dart';
import 'package:cleanapp/features/home/presentation/pages/not_found_page.dart';
import 'package:cleanapp/core/services/supabase_service.dart';
import 'package:cleanapp/core/widgets/main_scaffold.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = SupabaseService.currentUser != null;
      final isAuthRoute = state.matchedLocation == '/auth';
      final location = state.matchedLocation;

      // Redirect to auth if not authenticated and trying to access protected routes
      if (!isAuthenticated && !isAuthRoute && _isProtectedRoute(location)) {
        return '/auth';
      }

      // Redirect to home if authenticated and on auth page
      if (isAuthenticated && isAuthRoute) {
        return '/';
      }

      // Check admin access
      if (location == '/admin' && !SupabaseService.isAdmin()) {
        return '/profile';
      }

      // Check cleaner access
      if (location == '/cleaner' && !SupabaseService.isCleaner()) {
        return '/profile';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const MainScaffold(child: HomePage()),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthPage(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const MainScaffold(child: SearchPage()),
      ),
      GoRoute(
        path: '/calendar',
        builder: (context, state) => const MainScaffold(child: CalendarPage()),
      ),
      GoRoute(
        path: '/tariffs',
        builder: (context, state) => const MainScaffold(child: TariffsPage()),
      ),
      GoRoute(
        path: '/tariff/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          // Проверяем, что ID существует в данных
          try {
            return TariffDetailPage(tariffId: id);
          } catch (e) {
            return const NotFoundPage();
          }
        },
      ),
      GoRoute(
        path: '/booking',
        builder: (context, state) => const BookingPage(),
      ),
      GoRoute(
        path: '/confirmation',
        builder: (context, state) => const ConfirmationPage(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const MainScaffold(child: ProfilePage()),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/orders-history',
        builder: (context, state) => const OrdersHistoryPage(),
      ),
      GoRoute(
        path: '/order/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          // Валидация UUID перед созданием страницы
          if (id.isEmpty || !_isValidUUID(id)) {
            return const NotFoundPage();
          }
          try {
            return OrderDetailPage(bookingId: id);
          } catch (e) {
            return const NotFoundPage();
          }
        },
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardPage(),
      ),
      GoRoute(
        path: '/cleaner',
        builder: (context, state) => const CleanerDashboardPage(),
      ),
    ],
    errorBuilder: (context, state) {
      // Логируем ошибку для отладки
      debugPrint('Route error: ${state.error}');
      debugPrint('Location: ${state.uri}');
      return const NotFoundPage();
    },
  );

  static bool _isProtectedRoute(String location) {
    const protectedRoutes = [
      '/booking',
      '/confirmation',
      '/profile',
      '/settings',
      '/orders-history',
      '/order',
      '/admin',
      '/cleaner',
    ];
    return protectedRoutes.any((route) => location.startsWith(route));
  }

  // Validate UUID format
  static bool _isValidUUID(String value) {
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegex.hasMatch(value);
  }
}

