import 'package:flutter/foundation.dart' show kIsWeb;

/// Platform-aware API configuration
class ApiConfig {
  ApiConfig._();

  /// Get the base URL for the current platform
  static String get baseUrl {
    // Check for environment variable override first
    final overridden = const String.fromEnvironment('API_BASE_URL');
    if (overridden.isNotEmpty) return overridden;

    // Platform-specific URLs
    if (kIsWeb) {
      return 'http://localhost:3001/api';
    } else {
      // Android Emulator uses 10.0.2.2 to reach host localhost
      return 'http://10.0.2.2:3001/api';
    }
  }
}