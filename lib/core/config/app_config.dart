import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});

class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    this.requestTimeout = const Duration(seconds: 20),
  });

  static const _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

  final String apiBaseUrl;
  final Duration requestTimeout;

  factory AppConfig.fromEnvironment() {
    final override = _apiBaseUrlOverride.trim();
    return AppConfig(
      apiBaseUrl: _normalizeBaseUrl(
        override.isNotEmpty ? override : _defaultApiBaseUrl(),
      ),
    );
  }

  static String _defaultApiBaseUrl() {
    if (kIsWeb) return 'http://localhost:3000/api/v1';

    return switch (defaultTargetPlatform) {
      // Physical Android devices connected over USB can reach the laptop
      // through: adb reverse tcp:3000 tcp:3000
      TargetPlatform.android => 'http://127.0.0.1:3000/api/v1',
      TargetPlatform.iOS ||
      TargetPlatform.macOS ||
      TargetPlatform.linux ||
      TargetPlatform.windows => 'http://localhost:3000/api/v1',
      TargetPlatform.fuchsia => 'http://localhost:3000/api/v1',
    };
  }

  static String _normalizeBaseUrl(String value) {
    var url = value.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }
}
