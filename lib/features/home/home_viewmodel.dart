import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_repository.dart';
import 'models/dashboard_stats.dart';

final dashboardStatsProvider =
    AsyncNotifierProvider<DashboardStatsViewModel, DashboardStats>(
      DashboardStatsViewModel.new,
    );

class DashboardStatsViewModel extends AsyncNotifier<DashboardStats> {
  @override
  Future<DashboardStats> build() {
    return ref.read(homeRepositoryProvider).getDashboardStats();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(homeRepositoryProvider).getDashboardStats(),
    );
  }
}
