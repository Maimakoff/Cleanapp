import 'dart:async';
import 'package:cleanapp/core/utils/network_error_handler.dart';
import 'package:cleanapp/core/utils/network_retry.dart';

/// Default timeout duration for network calls
const Duration defaultTimeout = Duration(seconds: 30);

/// Network call wrapper with timeout and retry logic
class NetworkCallWrapper {
  /// Execute network call with timeout and retry
  static Future<T> execute<T>({
    required Future<T> Function() operation,
    Duration? timeout,
    RetryConfig? retryConfig,
    String? context,
  }) async {
    final timeoutDuration = timeout ?? defaultTimeout;

    return await NetworkRetry.executeWithRetry<T>(
      operation: () async {
        try {
          return await operation().timeout(
            timeoutDuration,
            onTimeout: () {
              throw TimeoutException(
                'Request timeout after ${timeoutDuration.inSeconds} seconds',
                timeoutDuration,
              );
            },
          );
        } catch (error, stackTrace) {
          // Classify and process error
          final userMessage = NetworkErrorHandler.processError(
            error,
            stackTrace: stackTrace,
            context: context,
          );

          // Re-throw with user-friendly message if it's a timeout or network error
          final errorType = NetworkErrorHandler.classifyError(error);
          if (errorType == NetworkErrorType.timeout ||
              errorType == NetworkErrorType.noInternet) {
            throw Exception(userMessage);
          }

          // For other errors, re-throw original but log it
          rethrow;
        }
      },
      config: retryConfig,
      context: context,
    );
  }
}
