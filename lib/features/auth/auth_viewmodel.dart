import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/security/token_storage.dart';
import 'auth_repository.dart';
import 'models/user.dart';

final authViewModelProvider = AsyncNotifierProvider<AuthViewModel, AuthSession>(
  AuthViewModel.new,
);

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authViewModelProvider).value?.user;
});

class AuthSession {
  const AuthSession._({this.user});

  const AuthSession.unauthenticated() : this._();
  const AuthSession.authenticated(User user) : this._(user: user);

  final User? user;

  bool get isAuthenticated => user != null;
}

class AuthViewModel extends AsyncNotifier<AuthSession> {
  @override
  Future<AuthSession> build() async {
    final tokenStorage = ref.read(tokenStorageProvider);
    final token = await tokenStorage.read();

    if (token == null || token.isEmpty) {
      return const AuthSession.unauthenticated();
    }

    try {
      final user = await ref.read(authRepositoryProvider).getCurrentUser();
      return AuthSession.authenticated(user);
    } catch (_) {
      await tokenStorage.delete();
      return const AuthSession.unauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = await ref
          .read(authRepositoryProvider)
          .login(email, password);
      return AuthSession.authenticated(user);
    });
  }

  Future<void> logout() async {
    state = const AsyncData(AuthSession.unauthenticated());
    await ref.read(authRepositoryProvider).logout();
  }
}
