import 'package:flutter/foundation.dart';

/// Centralized logger for the application.
/// Provides consistent error logging across the app.
class AppLogger {
  /// Log an error with context
  static void logError(
    Object error, {
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? additionalInfo,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('🚨 ERROR ${context != null ? '[$context]' : ''}');
    buffer.writeln('Error: $error');
    
    if (stackTrace != null) {
      buffer.writeln('Stack trace:');
      buffer.writeln(stackTrace);
    }
    
    if (additionalInfo != null && additionalInfo.isNotEmpty) {
      buffer.writeln('Additional info:');
      additionalInfo.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }
    
    if (kDebugMode) {
      debugPrint(buffer.toString());
    } else {
      // In production, send to crash reporting service
      // Example: Firebase Crashlytics, Sentry, etc.
    }
  }

  /// Log a warning
  static void logWarning(String message, {String? context}) {
    final logMessage = '⚠️ WARNING ${context != null ? '[$context]' : ''}: $message';
    if (kDebugMode) {
      debugPrint(logMessage);
    }
    // In production, warnings can be sent to crash reporting service if needed
  }

  /// Log informational message
  static void logInfo(String message, {String? context}) {
    final logMessage = 'ℹ️ INFO ${context != null ? '[$context]' : ''}: $message';
    if (kDebugMode) {
      debugPrint(logMessage);
    }
  }
}
