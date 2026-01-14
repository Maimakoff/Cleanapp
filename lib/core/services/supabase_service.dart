import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cleanapp/core/models/booking.dart';

class SupabaseService {
  static SupabaseClient? _client;

  static SupabaseClient get client {
    if (_client == null) {
      try {
        // Проверяем, инициализирован ли Supabase
        if (!Supabase.instance.isInitialized) {
          throw Exception(
            'Supabase не инициализирован. Убедитесь, что:\n'
            '1. Файл .env существует в корне проекта\n'
            '2. Файл .env содержит SUPABASE_URL и SUPABASE_ANON_KEY\n'
            '3. Перезапустите приложение после создания/изменения .env файла'
          );
        }
        _client = Supabase.instance.client;
      } catch (e) {
        // Если это наша ошибка, пробрасываем её
        if (e.toString().contains('Supabase не инициализирован')) {
          rethrow;
        }
        // Проверяем, это ли ошибка инициализации
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('_isinitialized') || 
            errorStr.contains('not initialized') ||
            errorStr.contains('must initialize')) {
          throw Exception(
            'Supabase не инициализирован. Убедитесь, что:\n'
            '1. Файл .env существует в корне проекта\n'
            '2. Файл .env содержит SUPABASE_URL и SUPABASE_ANON_KEY\n'
            '3. Перезапустите приложение после создания/изменения .env файла'
          );
        }
        // Иначе это другая ошибка от Supabase.instance
        throw Exception(
          'Ошибка доступа к Supabase: ${e.toString()}'
        );
      }
    }
    return _client!;
  }

  // Auth methods
  static User? get currentUser {
    try {
      return client.auth.currentUser;
    } catch (e) {
      return null;
    }
  }
  
  static Session? get currentSession {
    try {
      return client.auth.currentSession;
    } catch (e) {
      return null;
    }
  }

  // Auth state stream
  static Stream<AuthState> get authStateChanges {
    try {
      return client.auth.onAuthStateChange;
    } catch (e) {
      return const Stream.empty();
    }
  }

  // Sign up
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Проверяем инициализацию перед запросом
      if (!Supabase.instance.isInitialized) {
        throw Exception(
          'Supabase не инициализирован. Проверьте файл .env и перезапустите приложение'
        );
      }
      
      return await client.auth.signUp(
        email: email,
        password: password,
        data: data,
        emailRedirectTo: 'cleanapp://auth-callback',
      );
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      
      // Check if Supabase is not initialized
      if (errorStr.contains('supabase') && 
          (errorStr.contains('not initialized') ||
           errorStr.contains('_isinitialized') ||
           errorStr.contains('must initialize'))) {
        throw Exception(
          'Supabase не настроен. Проверьте файл .env с SUPABASE_URL и SUPABASE_ANON_KEY и перезапустите приложение'
        );
      }
      
      // Обработка сетевых ошибок
      if (errorStr.contains('socketexception') ||
          errorStr.contains('network') ||
          errorStr.contains('connection') ||
          errorStr.contains('failed host lookup')) {
        throw Exception(
          'Ошибка сети. Проверьте интернет-соединение и попробуйте снова'
        );
      }
      
      // Обработка таймаутов
      if (errorStr.contains('timeout') ||
          errorStr.contains('timed out')) {
        throw Exception(
          'Превышено время ожидания. Проверьте интернет-соединение'
        );
      }
      
      // Пробрасываем оригинальную ошибку, если это известная ошибка Supabase
      rethrow;
    }
  }

  // Sign in
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Проверяем инициализацию перед запросом
      if (!Supabase.instance.isInitialized) {
        throw Exception(
          'Supabase не инициализирован. Проверьте файл .env и перезапустите приложение'
        );
      }
      
      return await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      
      // Check if Supabase is not initialized
      if (errorStr.contains('supabase') && 
          (errorStr.contains('not initialized') ||
           errorStr.contains('_isinitialized') ||
           errorStr.contains('must initialize'))) {
        throw Exception(
          'Supabase не настроен. Проверьте файл .env с SUPABASE_URL и SUPABASE_ANON_KEY и перезапустите приложение'
        );
      }
      
      // Обработка ошибок аутентификации Supabase
      if (e is AuthException) {
        final message = e.message.toLowerCase();
        
        // Неверные учетные данные (может быть неверный email или пароль)
        if (message.contains('invalid login credentials') ||
            message.contains('invalid credentials') ||
            message.contains('invalid email or password')) {
          // Проверяем, существует ли пользователь (попытка определить причину)
          // Но Supabase не различает неверный email и неверный пароль для безопасности
          throw Exception('Invalid login credentials');
        }
        
        // Email не подтвержден
        if (message.contains('email not confirmed') ||
            message.contains('email not verified')) {
          throw Exception('Email not confirmed');
        }
        
        // Слишком много попыток
        if (message.contains('too many requests') ||
            message.contains('rate limit')) {
          throw Exception('Too many requests');
        }
        
        // Пробрасываем оригинальное сообщение AuthException
        throw Exception(e.message);
      }
      
      // Обработка сетевых ошибок
      if (errorStr.contains('socketexception') ||
          errorStr.contains('network') ||
          errorStr.contains('connection') ||
          errorStr.contains('failed host lookup')) {
        throw Exception(
          'Ошибка сети. Проверьте интернет-соединение и попробуйте снова'
        );
      }
      
      // Обработка таймаутов
      if (errorStr.contains('timeout') ||
          errorStr.contains('timed out')) {
        throw Exception(
          'Превышено время ожидания. Проверьте интернет-соединение'
        );
      }
      
      rethrow;
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      // Ignore if Supabase is not initialized
    }
  }

  // Reset password
  static Future<void> resetPassword(String email) async {
    try {
      await client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'cleanapp://reset-password',
      );
    } catch (e) {
      if (e.toString().contains('Supabase') || 
          e.toString().contains('not initialized') ||
          e.toString().contains('_isInitialized')) {
        throw Exception(
          'Supabase не настроен. Создайте файл .env с SUPABASE_URL и SUPABASE_ANON_KEY'
        );
      }
      rethrow;
    }
  }

  // Get bookings
  static Future<List<Booking>> getBookings() async {
    try {
      final response = await client
          .from('bookings')
          .select()
          .order('created_at', ascending: false)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Превышено время ожидания');
            },
          );

      if (response.isEmpty) return [];

      return (response as List)
          .map((json) => Booking.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Возвращаем пустой список при ошибке, чтобы не блокировать UI
      return [];
    }
  }

  // Get user bookings
  static Future<List<Booking>> getUserBookings(String userId) async {
    try {
      final response = await client
          .from('bookings')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Превышено время ожидания');
            },
          );

      if (response.isEmpty) return [];

      return (response as List)
          .map((json) {
            try {
              return Booking.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              // Логируем ошибку парсинга, но продолжаем обработку других записей
              if (kDebugMode) {
                print('Ошибка парсинга заказа: $e, данные: $json');
              }
              return null;
            }
          })
          .whereType<Booking>()
          .toList();
    } catch (e) {
      // Логируем ошибку для отладки
      if (kDebugMode) {
        print('Ошибка загрузки заказов: $e');
      }
      // Возвращаем пустой список при ошибке, чтобы не блокировать UI
      return [];
    }
  }

  // Get booked dates (for calendar)
  static Future<List<Map<String, dynamic>>> getBookedDates() async {
    try {
      final response = await client
          .from('bookings')
          .select('date, time')
          .eq('status', 'confirmed')
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              throw Exception('Превышено время ожидания');
            },
          );

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      // Возвращаем пустой список при ошибке, чтобы календарь работал
      return [];
    }
  }

  // Get available dates/times
  static Future<List<Map<String, dynamic>>> getBookedSlots() async {
    try {
      final response = await client
          .from('bookings')
          .select('date, time')
          .eq('status', 'new')
          .or('status.eq.accepted')
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              throw Exception('Превышено время ожидания');
            },
          );

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      // Возвращаем пустой список при ошибке
      return [];
    }
  }

  // Update booking status (with access control)
  static Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('Необходима авторизация');
      }

      // Проверяем права доступа: только админ или владелец заказа могут изменять статус
      final booking = await client
          .from('bookings')
          .select('user_id')
          .eq('id', bookingId)
          .single()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Превышено время ожидания');
            },
          );

      final bookingUserId = booking['user_id'] as String?;
      final isAdmin = getUserRole() == 'admin';
      final isOwner = bookingUserId == user.id;

      if (!isAdmin && !isOwner) {
        throw Exception('Недостаточно прав для изменения статуса заказа');
      }

      // Валидация статуса
      const validStatuses = ['pending', 'confirmed', 'completed', 'cancelled'];
      if (!validStatuses.contains(status.toLowerCase())) {
        throw Exception('Недопустимый статус');
      }

      await client
          .from('bookings')
          .update({
            'status': status.toLowerCase(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', bookingId)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Превышено время ожидания');
            },
          );
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('недостаточно прав') || 
          errorStr.contains('необходима авторизация') ||
          errorStr.contains('недопустимый статус')) {
        rethrow;
      }
      throw Exception('Ошибка обновления статуса. Попробуйте позже');
    }
  }

  // Get user role
  static String? getUserRole() {
    try {
      final user = currentUser;
      if (user == null) return null;
      // Получаем роль из user_metadata или из отдельной таблицы
      return user.userMetadata?['role'] as String?;
    } catch (e) {
      return null;
    }
  }

  // Check if user is admin
  static bool isAdmin() {
    return getUserRole() == 'admin';
  }

  // Check if user is cleaner
  static bool isCleaner() {
    return getUserRole() == 'cleaner';
  }

  // Upload avatar to Supabase Storage
  static Future<String> uploadAvatar(String userId, List<int> imageBytes, String fileName) async {
    try {
      if (!Supabase.instance.isInitialized) {
        throw Exception('Supabase не инициализирован');
      }
      
      final path = '$userId/$fileName';
      
      // Конвертируем List<int> в Uint8List
      final uint8List = Uint8List.fromList(imageBytes);
      
      await client.storage
          .from('avatars')
          .uploadBinary(
            path,
            uint8List,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );
      
      final url = client.storage.from('avatars').getPublicUrl(path);
      return url;
    } catch (e) {
      throw Exception('Ошибка загрузки аватара: ${e.toString()}');
    }
  }

  // Get avatar URL
  static String? getAvatarUrl(String? avatarPath) {
    if (avatarPath == null || avatarPath.isEmpty) return null;
    try {
      return client.storage.from('avatars').getPublicUrl(avatarPath);
    } catch (e) {
      return null;
    }
  }

  // Update user profile
  static Future<void> updateUserProfile({
    String? avatarUrl,
    String? name,
    String? phone,
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');
      
      final updates = <String, dynamic>{};
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      
      if (updates.isNotEmpty) {
        await client.auth.updateUser(
          UserAttributes(data: updates),
        );
      }
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('unauthorized') || errorStr.contains('not authenticated')) {
        throw Exception('Необходима авторизация');
      }
      // Не раскрываем детали ошибки для безопасности
      throw Exception('Ошибка обновления профиля. Попробуйте позже');
    }
  }

  // Get user level and points (геймификация)
  static Future<Map<String, dynamic>> getUserStats() async {
    try {
      final user = currentUser;
      if (user == null) return {'level': 1, 'points': 0, 'nextLevelPoints': 100};
      
      // Получаем количество заказов
      final bookings = await getUserBookings(user.id);
      final completedBookings = bookings.where((b) => b.status == 'completed').length;
      
      // Система уровней: 1 заказ = 10 баллов
      final points = completedBookings * 10;
      
      // Уровни: каждые 100 баллов = новый уровень
      final level = (points ~/ 100) + 1;
      final nextLevelPoints = level * 100;
      final currentLevelPoints = points % 100;
      
      return {
        'level': level,
        'points': points,
        'currentLevelPoints': currentLevelPoints,
        'nextLevelPoints': nextLevelPoints,
        'completedBookings': completedBookings,
      };
    } catch (e) {
      return {'level': 1, 'points': 0, 'nextLevelPoints': 100};
    }
  }

  // Change password
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      if (!Supabase.instance.isInitialized) {
        throw Exception('Supabase не инициализирован');
      }
      
      final user = currentUser;
      if (user?.email == null) {
        throw Exception('Пользователь не авторизован');
      }
      
      // Проверяем текущий пароль
      await client.auth.signInWithPassword(
        email: user!.email!,
        password: currentPassword,
      );
      
      // Обновляем пароль
      await client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('invalid') || errorStr.contains('password')) {
        throw Exception('Неверный текущий пароль');
      }
      rethrow;
    }
  }

  // Resend email confirmation
  static Future<void> resendEmailConfirmation(String email) async {
    try {
      if (!Supabase.instance.isInitialized) {
        throw Exception(
          'Supabase не инициализирован. Проверьте файл .env и перезапустите приложение'
        );
      }
      
      await client.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: 'cleanapp://auth-callback',
      );
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      
      if (errorStr.contains('supabase') && 
          (errorStr.contains('not initialized') ||
           errorStr.contains('_isinitialized') ||
           errorStr.contains('must initialize'))) {
        throw Exception(
          'Supabase не настроен. Проверьте файл .env с SUPABASE_URL и SUPABASE_ANON_KEY и перезапустите приложение'
        );
      }
      
      rethrow;
    }
  }

  // Get referral bonuses
  static Future<List<Map<String, dynamic>>> getReferralBonuses(String userId) async {
    try {
      final response = await client
          .from('referral_bonuses')
          .select()
          .eq('user_id', userId)
          .eq('is_used', false)
          .gte('expires_at', DateTime.now().toIso8601String())
          .order('discount_percentage', ascending: false)
          .limit(1);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }
}

