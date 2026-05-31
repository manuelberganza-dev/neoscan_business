import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});

class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.geminiApiKey,
    required this.geminiModel,
    this.requestTimeout = const Duration(seconds: 20),
  });

  static const _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');
  static const _geminiApiKeyOverride = String.fromEnvironment('GEMINI_API_KEY');
  static const _geminiModelOverride = String.fromEnvironment('GEMINI_MODEL');

  final String apiBaseUrl;
  final String geminiApiKey;
  final String geminiModel;
  final Duration requestTimeout;

  String get actionCableBaseUrl {
    final uri = Uri.parse(apiBaseUrl);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    final path = uri.path.replaceFirst(RegExp(r'/api/v1/?$'), '');
    return uri
        .replace(scheme: scheme, path: '$path/cable', queryParameters: null)
        .toString();
  }

  factory AppConfig.fromEnvironment() {
    final override = _apiBaseUrlOverride.trim();
    return AppConfig(
      apiBaseUrl: _normalizeBaseUrl(
        override.isNotEmpty ? override : _defaultApiBaseUrl(),
      ),
      geminiApiKey: _envValue(_geminiApiKeyOverride),
      geminiModel: _envValue(
        _geminiModelOverride,
        fallback: 'gemini-flash-latest',
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

  static String _envValue(String dartDefineValue, {String fallback = ''}) {
    final value = dartDefineValue.trim();
    if (value.isNotEmpty) return value;
    return fallback;
  }
}
