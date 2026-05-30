import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../../core/security/token_storage.dart';
import 'models/user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(
      ref.read(dioClientProvider),
      ref.read(tokenStorageProvider),
    ));

class AuthRepository {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  const AuthRepository(this._dio, this._tokenStorage);

  Future<User> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'user': {'email': email, 'password': password},
      });

      // ── Token extraction ─────────────────────────────────────────────────
      // 1. Devise JWT puts token in the Authorization response header
      String? token = extractToken(response);

      // 2. Some custom backends return it in the body
      if (token == null && response.data is Map) {
        final body = response.data as Map;
        token = body['token'] as String? ??
            body['jwt'] as String? ??
            body['access_token'] as String?;
      }

      if (token != null && token.isNotEmpty) {
        await _tokenStorage.save(token);
      }

      // ── User data extraction ─────────────────────────────────────────────
      // Handles: {"data": {...}}, {"user": {...}}, or flat {...}
      final body = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      final userData = (body['data'] ?? body['user'] ?? body) as Map<String, dynamic>;
      return User.fromJson(userData);
    } on DioException catch (e) {
      throw dioErrorMessage(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.delete('/auth/logout');
    } catch (_) {}
    await _tokenStorage.delete();
  }

  Future<User> getCurrentUser() async {
    try {
      final response = await _dio.get('/me');
      final body = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final userData = (body['data'] ?? body['user'] ?? body) as Map<String, dynamic>;
      return User.fromJson(userData);
    } on DioException catch (e) {
      throw dioErrorMessage(e);
    }
  }
}
