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
      if (err.response?.statusCode == 401) {
        await tokenStorage.delete();
      }
      handler.next(err);
    },
  ));

  return dio;
});

// Extracts the Bearer token from the Authorization response header (Devise JWT).
String? extractToken(Response response) {
  final auth = response.headers.value('authorization');
  if (auth == null) return null;
  return auth.startsWith('Bearer ') ? auth.substring(7) : auth;
}

// Converts a DioException to a readable message.
String dioErrorMessage(DioException e) {
  final data = e.response?.data;
  if (data is Map) {
    final msg = data['error'] ?? data['message'] ?? data['errors'];
    if (msg is String) return msg;
    if (msg is List) return msg.join(', ');
  }
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Tiempo de espera agotado. Verifica tu conexión.';
    case DioExceptionType.connectionError:
      return 'No se pudo conectar al servidor.';
    default:
      return 'Error inesperado. Intenta de nuevo.';
  }
}
