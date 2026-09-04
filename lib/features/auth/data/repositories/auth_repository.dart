import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/network/api_client.dart';
import '../models/auth_models.dart';

class AuthRepository {
  AuthRepository({required ApiClient apiClient, FlutterSecureStorage? storage})
    : _apiClient = apiClient,
      _storage = storage ?? const FlutterSecureStorage();

  static const tokenKey = ApiClient.tokenKey;

  final ApiClient _apiClient;
  final FlutterSecureStorage _storage;

  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.request<Map<String, dynamic>>(
      '/api/auth/login',
      method: 'POST',
      data: {'email': email, 'password': password},
    );
    final result = LoginResult.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
    await _storage.write(key: tokenKey, value: result.token);
    return result;
  }

  Future<void> logout() async {
    try {
      await _apiClient.request<Map<String, dynamic>>(
        '/api/auth/logout',
        method: 'POST',
      );
    } finally {
      await _storage.delete(key: tokenKey);
    }
  }

  Future<AuthUser?> restoreSession() async {
    if (await _storage.read(key: tokenKey) == null) return null;

    try {
      final response = await _apiClient.request<Map<String, dynamic>>('/me');
      final user = TokenUser.fromJson(
        response.data!['user'] as Map<String, dynamic>,
      );
      return AuthUser.fromToken(user);
    } on ApiException catch (error) {
      if (error.type == ApiErrorType.unauthorized) {
        await _storage.delete(key: tokenKey);
        return null;
      }
      rethrow;
    }
  }
}
