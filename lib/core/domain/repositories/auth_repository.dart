import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository interface for authentication operations.
/// This abstracts the data source (Supabase) from the domain layer.
abstract class AuthRepository {
  /// Get the current authenticated user
  User? getCurrentUser();

  /// Get the current session
  Session? getCurrentSession();

  /// Stream of authentication state changes
  Stream<AuthState> getAuthStateChanges();

  /// Sign up a new user
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  });

  /// Sign in an existing user
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  });

  /// Sign out the current user
  Future<void> signOut();

  /// Reset password for a user
  Future<void> resetPassword(String email);

  /// Update user profile
  Future<void> updateUserProfile({
    String? avatarUrl,
    String? name,
    String? phone,
  });

  /// Change user password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Resend email confirmation
  Future<void> resendEmailConfirmation(String email);

  /// Get user role
  String? getUserRole();

  /// Check if user is admin
  bool isAdmin();

  /// Check if user is cleaner
  bool isCleaner();
}
