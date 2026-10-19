import 'package:flutter/foundation.dart';

String get apiBaseUrl {
  const configuredUrl = String.fromEnvironment('API_BASE_URL');
  if (configuredUrl.isNotEmpty) {
    return configuredUrl;
  }

  if (kIsWeb) {
    return 'http://localhost:5000/api';
  }
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:5000/api';
  }
  return 'http://localhost:5000/api';
}
