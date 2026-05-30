import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/security/token_storage.dart';
import 'auth_repository.dart';
import 'models/user.dart';

final authViewModelProvider =
    AsyncNotifierProvider<AuthViewModel, User?>(AuthViewModel.new);

class AuthViewModel extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    final token = await ref.read(tokenStorageProvider).read();
    if (token == null) return null;
    try {
      return await ref.read(authRepositoryProvider).getCurrentUser();
    } catch (_) {
      await ref.read(tokenStorageProvider).delete();
      return null;
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).login(email, password),
    );
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}
