import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_client.dart';
import 'offline_database.dart';

final offlineDatabaseProvider = Provider<OfflineDatabase>((ref) {
  final database = OfflineDatabase();
  ref.onDispose(database.close);
  return database;
});

final offlineQueueRepositoryProvider = Provider<OfflineQueueRepository>((ref) {
  return OfflineQueueRepository(
    ref.watch(offlineDatabaseProvider),
    ref.watch(dioClientProvider),
  );
});

class OfflineQueueRepository {
  const OfflineQueueRepository(this._database, this._dio);

  final OfflineDatabase _database;
  final Dio _dio;

  Stream<int> watchPendingCount() {
    final count = _database.offlineQueueItems.id.count();
    final query = _database.selectOnly(_database.offlineQueueItems)
      ..addColumns([count]);
    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }

  Future<int> pendingCount() {
    final count = _database.offlineQueueItems.id.count();
    final query = _database.selectOnly(_database.offlineQueueItems)
      ..addColumns([count]);
    return query.map((row) => row.read(count) ?? 0).getSingle();
  }

  Future<void> enqueue({
    required String method,
    required String endpoint,
    required Map<String, dynamic> payload,
    required String operationType,
  }) {
    return _database
        .into(_database.offlineQueueItems)
        .insert(
          OfflineQueueItemsCompanion.insert(
            method: method,
            endpoint: endpoint,
            payload: jsonEncode(payload),
            operationType: operationType,
            createdAt: DateTime.now(),
          ),
        );
  }

  Future<void> syncPending() async {
    final items = await (_database.select(
      _database.offlineQueueItems,
    )..orderBy([(row) => OrderingTerm.asc(row.createdAt)])).get();

    for (final item in items) {
      try {
        await _dio.request<void>(
          item.endpoint,
          data: jsonDecode(item.payload),
          options: Options(method: item.method),
        );
        await (_database.delete(
          _database.offlineQueueItems,
        )..where((row) => row.id.equals(item.id))).go();
      } on DioException catch (e) {
        await _markFailed(item, dioErrorMessage(e));
        if (_shouldStopSync(e)) return;
      } catch (e) {
        await _markFailed(item, e.toString());
        return;
      }
    }
  }

  Future<void> _markFailed(OfflineQueueItem item, String error) {
    return (_database.update(
      _database.offlineQueueItems,
    )..where((row) => row.id.equals(item.id))).write(
      OfflineQueueItemsCompanion(
        retryCount: Value(item.retryCount + 1),
        lastAttemptAt: Value(DateTime.now()),
        lastError: Value(error),
      ),
    );
  }

  bool _shouldStopSync(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => true,
      _ => false,
    };
  }
}
