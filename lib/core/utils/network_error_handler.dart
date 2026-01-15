import 'dart:io';
import 'package:cleanapp/core/utils/logger.dart';

/// Network error types
enum NetworkErrorType {
  noInternet,
  timeout,
  serverError,
  authenticationError,
  notFound,
  validationError,
  unknown,
}

/// Network error classification and user-friendly message mapping
class NetworkErrorHandler {
  /// Classify error and return error type
  static NetworkErrorType classifyError(Object error) {
    final errorStr = error.toString().toLowerCase();
    final errorMessage = error is Exception ? error.toString() : error.toString();

    // No internet connection
    if (error is SocketException ||
        errorStr.contains('socketexception') ||
        errorStr.contains('failed host lookup') ||
        errorStr.contains('network is unreachable') ||
        errorStr.contains('connection refused') ||
        errorStr.contains('no internet') ||
        errorStr.contains('networkerror')) {
      return NetworkErrorType.noInternet;
    }

    // Timeout errors
    if (errorStr.contains('timeout') ||
        errorStr.contains('timed out') ||
        errorStr.contains('deadline exceeded') ||
        errorMessage.contains('TimeoutException')) {
      return NetworkErrorType.timeout;
    }

    // Server errors (5xx)
    if (errorStr.contains('500') ||
        errorStr.contains('502') ||
        errorStr.contains('503') ||
        errorStr.contains('504') ||
        errorStr.contains('internal server error') ||
        errorStr.contains('bad gateway') ||
        errorStr.contains('service unavailable')) {
      return NetworkErrorType.serverError;
    }

    // Authentication errors (401, 403)
    if (errorStr.contains('401') ||
        errorStr.contains('403') ||
        errorStr.contains('unauthorized') ||
        errorStr.contains('forbidden') ||
        errorStr.contains('not authenticated') ||
        errorStr.contains('jwt') ||
        errorStr.contains('token')) {
      return NetworkErrorType.authenticationError;
    }

    // Not found (404)
    if (errorStr.contains('404') ||
        errorStr.contains('not found') ||
        errorStr.contains('does not exist')) {
      return NetworkErrorType.notFound;
    }

    // Validation errors (400, 422)
    if (errorStr.contains('400') ||
        errorStr.contains('422') ||
        errorStr.contains('bad request') ||
        errorStr.contains('validation') ||
        errorStr.contains('invalid') ||
        errorStr.contains('constraint')) {
      return NetworkErrorType.validationError;
    }

    return NetworkErrorType.unknown;
  }

  /// Get user-friendly error message based on error type
  static String getUserFriendlyMessage(NetworkErrorType errorType) {
    switch (errorType) {
      case NetworkErrorType.noInternet:
        return 'Нет подключения к интернету. Проверьте соединение и попробуйте снова.';
      case NetworkErrorType.timeout:
        return 'Превышено время ожидания. Проверьте интернет-соединение и попробуйте снова.';
      case NetworkErrorType.serverError:
        return 'Сервер временно недоступен. Пожалуйста, попробуйте позже.';
      case NetworkErrorType.authenticationError:
        return 'Сессия истекла. Пожалуйста, войдите в аккаунт снова.';
      case NetworkErrorType.notFound:
        return 'Запрашиваемые данные не найдены.';
      case NetworkErrorType.validationError:
        return 'Некорректные данные. Проверьте введенную информацию.';
      case NetworkErrorType.unknown:
        return 'Произошла ошибка при выполнении запроса. Попробуйте снова.';
    }
  }

  /// Process error: classify, log, and return user-friendly message
  static String processError(
    Object error, {
    StackTrace? stackTrace,
    String? context,
  }) {
    final errorType = classifyError(error);
    final userMessage = getUserFriendlyMessage(errorType);

    // Log error with classification
    AppLogger.logError(
      error,
      stackTrace: stackTrace,
      context: context ?? 'Network',
      additionalInfo: {
        'error_type': errorType.name,
        'user_message': userMessage,
      },
    );

    return userMessage;
  }

  /// Check if error is retryable
  static bool isRetryable(NetworkErrorType errorType) {
    return errorType == NetworkErrorType.noInternet ||
        errorType == NetworkErrorType.timeout ||
        errorType == NetworkErrorType.serverError;
  }
}
