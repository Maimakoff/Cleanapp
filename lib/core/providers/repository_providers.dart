import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/booking_repository.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/booking_repository_impl.dart';

/// Provider for AuthRepository.
/// Returns AuthRepositoryImpl instance.
/// This provider enables dependency injection for authentication operations.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

/// Provider for BookingRepository.
/// Returns BookingRepositoryImpl instance.
/// This provider enables dependency injection for booking operations.
final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepositoryImpl();
});
