import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// User-friendly error fallback widget.
/// Replaces the red error screen with a friendly message.
class ErrorFallbackWidget extends StatelessWidget {
  final FlutterErrorDetails? errorDetails;
  final String? customMessage;

  const ErrorFallbackWidget({
    super.key,
    this.errorDetails,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 24),
                Text(
                  'Что-то пошло не так',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  customMessage ??
                      'Произошла непредвиденная ошибка. Пожалуйста, попробуйте перезапустить приложение.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    // Try to navigate to home, or restart the app
                    try {
                      if (context.mounted) {
                        context.go('/');
                      }
                    } catch (e) {
                      // If navigation fails, the app will need a restart
                    }
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('На главную'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (kDebugMode && errorDetails != null)
                  ExpansionTile(
                    title: const Text(
                      'Детали ошибки (только для разработки)',
                      style: TextStyle(fontSize: 12),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SelectableText(
                          '${errorDetails!.exception}\n\n${errorDetails!.stack}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
