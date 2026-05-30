import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../security/token_storage.dart';

final dioClientProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.read(tokenStorageProvider);

  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await tokenStorage.read();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (err, handler) async {
      // Only clear token on 401 for non-login endpoints so we don't clear
      // it mid-login before we have a chance to save a new one.
      final path = err.requestOptions.path;
      if (err.response?.statusCode == 401 && !path.contains('login')) {
        await tokenStorage.delete();
      }
      handler.next(err);
    },
  ));

  return dio;
});

/// Extracts the Bearer JWT from the Authorization *response* header.
/// Devise JWT always sends it there after sign-in.
String? extractToken(Response response) {
  // Dio lowercases header names on Android
  final auth = response.headers.value('authorization') ??
      response.headers.value('Authorization');
  if (auth == null) return null;
  final trimmed = auth.trim();
  return trimmed.startsWith('Bearer ') ? trimmed.substring(7) : trimmed;
}

/// Converts a [DioException] into a human-readable Spanish error message.
/// Handles the Devise JWT nested-status format and Rails standard formats.
String dioErrorMessage(DioException e) {
  final statusCode = e.response?.statusCode;
  final data = e.response?.data;

  if (data is Map) {
    // Devise JWT: {"status": {"code": 401, "message": "Invalid Email or password."}}
    final statusObj = data['status'];
    if (statusObj is Map) {
      final msg = statusObj['message'];
      if (msg is String && msg.isNotEmpty) return msg;
    }

    // Rails standard: {"error": "..."} or {"message": "..."}
    final flat = data['error'] ?? data['message'];
    if (flat is String && flat.isNotEmpty) return flat;

    // Devise: {"errors": ["..."]} or {"errors": {"email": [...]}}
    final errors = data['errors'];
    if (errors is List && errors.isNotEmpty) {
      return errors.map((e) => e.toString()).join('\n');
    }
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.entries.first;
      final msgs = first.value is List ? (first.value as List).join(', ') : first.value;
      return '${first.key}: $msgs';
    }
    if (errors is String && errors.isNotEmpty) return errors;
  }

  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Tiempo de espera agotado. Verifica tu conexión.';
    case DioExceptionType.connectionError:
      return 'No se pudo conectar al servidor.\nVerifica que el backend esté corriendo.';
    default:
      if (statusCode == 401) return 'Correo o contraseña incorrectos.';
      if (statusCode == 422) return 'Datos inválidos. Verifica tu correo y contraseña.';
      if (statusCode == 500) return 'Error interno del servidor.';
      return 'Error${statusCode != null ? ' $statusCode' : ''}: intenta de nuevo.';
  }
}
