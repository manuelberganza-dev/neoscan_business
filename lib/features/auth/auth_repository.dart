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
      // Devise JWT sends token in Authorization response header
      final token = extractToken(response);
      if (token != null) await _tokenStorage.save(token);

      final data = response.data is Map
          ? (response.data['data'] ?? response.data)
          : response.data;
      return User.fromJson(data as Map<String, dynamic>);
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
      final data = response.data is Map
          ? (response.data['data'] ?? response.data)
          : response.data;
      return User.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioErrorMessage(e);
    }
  }
}
