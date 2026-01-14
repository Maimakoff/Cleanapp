import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Helper class to provide access to ProviderContainer for static services.
/// This allows static services to read from Riverpod providers.
class ProviderContainerHelper {
  static ProviderContainer? _container;

  /// Initialize the container (should be called from main.dart or app initialization)
  static void initialize(ProviderContainer container) {
    _container = container;
  }

  /// Get the current container
  /// Returns a default container if not initialized (for backward compatibility)
  static ProviderContainer get container {
    return _container ?? ProviderContainer();
  }

  /// Dispose the container (for cleanup)
  static void dispose() {
    _container?.dispose();
    _container = null;
  }
}
