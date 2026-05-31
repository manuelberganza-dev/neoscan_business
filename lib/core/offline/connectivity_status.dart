import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'offline_queue_repository.dart';

final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

final connectivityResultsProvider = StreamProvider<List<ConnectivityResult>>((
  ref,
) async* {
  final connectivity = ref.watch(connectivityProvider);
  yield await connectivity.checkConnectivity();
  yield* connectivity.onConnectivityChanged;
});

final isOfflineProvider = Provider<bool>((ref) {
  final results = ref.watch(connectivityResultsProvider).value;
  if (results == null || results.isEmpty) return false;
  return results.contains(ConnectivityResult.none);
});

final pendingOfflineCountProvider = StreamProvider<int>((ref) {
  return ref.watch(offlineQueueRepositoryProvider).watchPendingCount();
});

final offlineSyncBootstrapProvider = Provider<void>((ref) {
  var isSyncing = false;

  ref.listen(connectivityResultsProvider, (previous, next) async {
    final results = next.value;
    final isOnline =
        results != null && !results.contains(ConnectivityResult.none);

    if (!isOnline || isSyncing) return;

    isSyncing = true;
    try {
      await ref.read(offlineQueueRepositoryProvider).syncPending();
    } finally {
      isSyncing = false;
    }
  });
});
