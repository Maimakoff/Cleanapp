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
import 'package:cleanapp/core/services/supabase_service.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = SupabaseService.currentUser != null;
      final isAuthRoute = state.matchedLocation == '/auth';

      // Redirect to auth if not authenticated and trying to access protected routes
      if (!isAuthenticated && !isAuthRoute && _isProtectedRoute(state.matchedLocation)) {
        return '/auth';
      }

      // Redirect to home if authenticated and on auth page
      if (isAuthenticated && isAuthRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthPage(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchPage(),
      ),
      GoRoute(
        path: '/calendar',
        builder: (context, state) => const CalendarPage(),
      ),
      GoRoute(
        path: '/tariffs',
        builder: (context, state) => const TariffsPage(),
      ),
      GoRoute(
        path: '/tariff/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TariffDetailPage(tariffId: id);
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
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );

  static bool _isProtectedRoute(String location) {
    const protectedRoutes = [
      '/booking',
      '/confirmation',
      '/profile',
      '/settings',
    ];
    return protectedRoutes.any((route) => location.startsWith(route));
  }
}

