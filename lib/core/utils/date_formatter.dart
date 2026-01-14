import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Безопасное форматирование дат с поддержкой русской локали
class DateFormatter {
  static bool _isInitialized = false;
  static bool _initializationInProgress = false;

  /// Установить флаг инициализации (вызывается из main.dart после успешной инициализации)
  static void setInitialized(bool value) {
    _isInitialized = value;
  }

  /// Инициализация локализации (вызывается автоматически при первом использовании, если не инициализировано в main.dart)
  static Future<void> _ensureInitialized() async {
    if (_isInitialized || _initializationInProgress) return;
    
    _initializationInProgress = true;
    try {
      await initializeDateFormatting('ru', null);
      _isInitialized = true;
    } catch (e) {
      // Если не удалось инициализировать, продолжаем без локализации
      if (kDebugMode) {
        print('Warning: Failed to initialize date formatting: $e');
      }
    } finally {
      _initializationInProgress = false;
    }
  }

  /// Форматирование даты в формате "d MMMM yyyy" (например: "15 января 2024")
  static Future<String> formatDateLong(DateTime date) async {
    await _ensureInitialized();
    try {
      return DateFormat('d MMMM yyyy', 'ru').format(date);
    } catch (e) {
      // Fallback на формат без локализации
      return DateFormat('d MMMM yyyy').format(date);
    }
  }

  /// Синхронная версия (использует уже инициализированную локаль)
  static String formatDateLongSync(DateTime date) {
    try {
      if (_isInitialized) {
        return DateFormat('d MMMM yyyy', 'ru').format(date);
      } else {
        // Если локаль не инициализирована, используем формат без локализации
        return DateFormat('d MMMM yyyy').format(date);
      }
    } catch (e) {
      // Fallback на простой формат
      return DateFormat('dd.MM.yyyy').format(date);
    }
  }

  /// Форматирование даты в формате "d MMM" (например: "15 янв")
  static String formatDateShort(DateTime date) {
    try {
      if (_isInitialized) {
        return DateFormat('d MMM', 'ru').format(date);
      } else {
        return DateFormat('d MMM').format(date);
      }
    } catch (e) {
      return DateFormat('dd.MM').format(date);
    }
  }

  /// Форматирование даты в формате "d MMMM" (например: "15 января")
  static String formatDateMonth(DateTime date) {
    try {
      if (_isInitialized) {
        return DateFormat('d MMMM', 'ru').format(date);
      } else {
        return DateFormat('d MMMM').format(date);
      }
    } catch (e) {
      return DateFormat('dd.MM').format(date);
    }
  }

  /// Форматирование даты в формате "yyyy-MM-dd" (для API)
  static String formatDateApi(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Принудительная инициализация (можно вызвать в main.dart)
  static Future<void> initialize() async {
    await _ensureInitialized();
  }
}

