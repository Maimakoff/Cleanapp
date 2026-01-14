import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cleanapp/core/domain/repositories/auth_repository.dart';
import 'package:cleanapp/core/services/supabase_service.dart';

/// Implementation of AuthRepository using Supabase.
class AuthRepositoryImpl implements AuthRepository {
  @override
  User? getCurrentUser() {
    return SupabaseService.currentUser;
  }

  @override
  Session? getCurrentSession() {
    return SupabaseService.currentSession;
  }

  @override
  Stream<AuthState> getAuthStateChanges() {
    return SupabaseService.authStateChanges;
  }

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return await SupabaseService.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await SupabaseService.signIn(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signOut() async {
    await SupabaseService.signOut();
  }

  @override
  Future<void> resetPassword(String email) async {
    await SupabaseService.resetPassword(email);
  }

  @override
  Future<void> updateUserProfile({
    String? avatarUrl,
    String? name,
    String? phone,
  }) async {
    await SupabaseService.updateUserProfile(
      avatarUrl: avatarUrl,
      name: name,
      phone: phone,
    );
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await SupabaseService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  @override
  Future<void> resendEmailConfirmation(String email) async {
    await SupabaseService.resendEmailConfirmation(email);
  }

  @override
  String? getUserRole() {
    return SupabaseService.getUserRole();
  }

  @override
  bool isAdmin() {
    return SupabaseService.isAdmin();
  }

  @override
  bool isCleaner() {
    return SupabaseService.isCleaner();
  }
}
