import 'dart:async';
import 'package:cleanapp/core/utils/network_error_handler.dart';
import 'package:cleanapp/core/utils/logger.dart';

/// Retry configuration
class RetryConfig {
  final int maxAttempts;
  final Duration delayBetweenAttempts;
  final bool Function(Object error)? shouldRetry;

  const RetryConfig({
    this.maxAttempts = 2,
    this.delayBetweenAttempts = const Duration(seconds: 1),
    this.shouldRetry,
  });
}

/// Network retry utility
class NetworkRetry {
  /// Execute function with retry logic
  static Future<T> executeWithRetry<T>({
    required Future<T> Function() operation,
    RetryConfig? config,
    String? context,
  }) async {
    final retryConfig = config ?? const RetryConfig();
    int attempt = 0;
    Object? lastError;

    while (attempt < retryConfig.maxAttempts) {
      try {
        return await operation();
      } catch (error) {
        lastError = error;
        attempt++;

        // Check if error is retryable
        final errorType = NetworkErrorHandler.classifyError(error);
        final isRetryable = retryConfig.shouldRetry?.call(error) ??
            NetworkErrorHandler.isRetryable(errorType);

        if (!isRetryable || attempt >= retryConfig.maxAttempts) {
          // Not retryable or max attempts reached
          AppLogger.logInfo(
            'Retry failed after $attempt attempts',
            context: context ?? 'NetworkRetry',
          );
          rethrow;
        }

        // Log retry attempt
        AppLogger.logWarning(
          'Retry attempt $attempt/${retryConfig.maxAttempts} for: ${error.toString()}',
          context: context ?? 'NetworkRetry',
        );

        // Wait before retrying
        await Future.delayed(retryConfig.delayBetweenAttempts);
      }
    }

    // Should never reach here, but just in case
    throw lastError!;
  }
}
