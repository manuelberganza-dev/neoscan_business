import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../security/token_storage.dart';

final dioClientProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: config.requestTimeout,
      receiveTimeout: config.requestTimeout,
      sendTimeout: config.requestTimeout,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_isBackendRequest(options, config.apiBaseUrl)) {
          final token = await tokenStorage.read();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },
      onError: (err, handler) async {
        final path = err.requestOptions.path;
        if (err.response?.statusCode == 401 &&
            _isBackendRequest(err.requestOptions, config.apiBaseUrl) &&
            !path.contains('login')) {
          await tokenStorage.delete();
        }
        handler.next(err);
      },
    ),
  );

  return dio;
});

String? extractToken(Response response) {
  final auth =
      response.headers.value('authorization') ??
      response.headers.value('Authorization');
  if (auth == null) return null;

  final trimmed = auth.trim();
  return trimmed.startsWith('Bearer ') ? trimmed.substring(7) : trimmed;
}

String dioErrorMessage(DioException e) {
  final statusCode = e.response?.statusCode;
  final data = e.response?.data;

  if (data is Map) {
    final statusObj = data['status'];
    if (statusObj is Map) {
      final msg = statusObj['message'];
      if (msg is String && msg.isNotEmpty) return msg;
    }

    final flat = data['error'] ?? data['message'];
    if (flat is Map) {
      final msg = flat['message'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    if (flat is String && flat.isNotEmpty) return flat;

    final errors = data['errors'];
    if (errors is List && errors.isNotEmpty) {
      return errors.map((error) => error.toString()).join('\n');
    }
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.entries.first;
      final msgs = first.value is List
          ? (first.value as List).join(', ')
          : first.value;
      return '${first.key}: $msgs';
    }
    if (errors is String && errors.isNotEmpty) return errors;
  }

  return switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout =>
      'Tiempo de espera agotado al conectar con ${_requestHost(e)}. '
          'Verifica que el backend esté corriendo y que API_BASE_URL apunte al servidor correcto.',
    DioExceptionType.connectionError => _connectionErrorMessage(e),
    _ when statusCode == 401 => 'Correo o contraseña incorrectos.',
    _ when statusCode == 422 =>
      'Datos inválidos. Verifica tu correo y contraseña.',
    _ when statusCode == 500 => 'Error interno del servidor.',
    _ => 'Error${statusCode != null ? ' $statusCode' : ''}: intenta de nuevo.',
  };
}

String _requestHost(DioException e) {
  final uri = e.requestOptions.uri;
  if (uri.hasAuthority) return uri.authority;
  return e.requestOptions.baseUrl;
}

String _connectionErrorMessage(DioException e) {
  final host = _requestHost(e);
  final uri = e.requestOptions.uri;
  final isAndroidLocalhost =
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      (uri.host == '127.0.0.1' || uri.host == 'localhost');

  if (isAndroidLocalhost) {
    return 'No se pudo conectar con $host. En Android físico ejecuta adb reverse tcp:3000 tcp:3000 y vuelve a intentar.';
  }

  return 'No se pudo conectar con $host. '
      'Verifica que el backend esté corriendo y que la URL sea accesible desde este dispositivo.';
}

bool _isBackendRequest(RequestOptions options, String apiBaseUrl) {
  final backendUri = Uri.parse(apiBaseUrl);
  final requestUri = options.uri;

  return requestUri.scheme == backendUri.scheme &&
      requestUri.host == backendUri.host &&
      requestUri.port == backendUri.port;
}
