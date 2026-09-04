import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/models/auth_models.dart';
import '../../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(apiClient: ref.watch(apiClientProvider)),
);

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthUser?>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<AuthUser?> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  Future<AuthUser?> build() => _repository.restoreSession();

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await _repository.login(email: email, password: password);
      if (result.account.role != 'cashier') {
        await _repository.logout();
        throw const AuthException('Only cashier accounts can use this app.');
      }
      return AuthUser.fromAccount(result.account);
    });
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.logout();
      return null;
    });
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
