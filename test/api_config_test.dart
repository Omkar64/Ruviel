import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:ruviel/config/api_config.dart';

/// Test utility to verify API configuration
void testApiConfig() {
  print('=== API Configuration Test ===');
  print('Platform: ${kIsWeb ? "Web" : "Mobile/Desktop"}');
  print('Base URL: ${ApiConfig.baseUrl}');
  
  // Test environment variable override
  const testOverride = String.fromEnvironment('API_BASE_URL');
  if (testOverride.isNotEmpty) {
    print('Environment Override: $testOverride');
  } else {
    print('No environment override detected');
  }
  
  // Verify platform-specific URLs
  if (kIsWeb) {
    assert(ApiConfig.baseUrl == 'http://localhost:3001/api', 
           'Web should use localhost:3001');
    print('✅ Web configuration correct');
  } else {
    assert(ApiConfig.baseUrl == 'http://10.0.2.2:3001/api', 
           'Android should use 10.0.2.2:3001');
    print('✅ Android configuration correct');
  }
  
  print('=== Test Complete ===');
}