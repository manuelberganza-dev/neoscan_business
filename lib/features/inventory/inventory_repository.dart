import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../../core/offline/connectivity_status.dart';
import '../../core/offline/offline_queue_repository.dart';
import 'models/inventory_item.dart';
import 'models/stock_movement.dart';
import 'models/warehouse.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>(
  (ref) => InventoryRepository(
    ref.watch(dioClientProvider),
    ref.watch(offlineQueueRepositoryProvider),
    ref.watch(isOfflineProvider),
  ),
);

class InventoryRepository {
  final Dio _dio;
  final OfflineQueueRepository _offlineQueue;
  final bool _isOffline;

  const InventoryRepository(this._dio, this._offlineQueue, this._isOffline);

  // ── Warehouses ────────────────────────────────────────────────────────────

  Future<List<Warehouse>> getWarehouses() async {
    try {
      final response = await _dio.get('/warehouses');
      final list = _unwrapList(response.data);
      return list.map((j) => Warehouse.fromJson(j)).toList();
    } on DioException catch (e) {
      throw dioErrorMessage(e);
    }
  }

  // ── Inventory items ───────────────────────────────────────────────────────

  Future<List<InventoryItem>> getInventory({int? warehouseId}) async {
    try {
      final response = await _dio.get(
        '/inventory',
        queryParameters: {'warehouse_id': warehouseId},
      );
      final list = _unwrapList(response.data);
      return list.map((j) => InventoryItem.fromJson(j)).toList();
    } on DioException catch (e) {
      throw dioErrorMessage(e);
    }
  }

  // ── Stock adjustments ─────────────────────────────────────────────────────

  Future<void> createAdjustment(AdjustmentRequest request) async {
    if (_isOffline) {
      await _queueAdjustment(request);
      return;
    }

    try {
      await _dio.post('/stock_movements', data: request.toJson());
    } on DioException catch (e) {
      if (_canQueue(e)) {
        await _queueAdjustment(request);
        return;
      }
      throw dioErrorMessage(e);
    }
  }

  // ── Transfers ─────────────────────────────────────────────────────────────

  Future<void> createTransfer(TransferRequest request) async {
    if (_isOffline) {
      await _queueTransfer(request);
      return;
    }

    try {
      await _dio.post('/stock_movements/transfer', data: request.toJson());
    } on DioException catch (e) {
      if (_canQueue(e)) {
        await _queueTransfer(request);
        return;
      }
      throw dioErrorMessage(e);
    }
  }

  Future<void> _queueAdjustment(AdjustmentRequest request) {
    return _offlineQueue.enqueue(
      method: 'POST',
      endpoint: '/stock_movements',
      payload: request.toJson(),
      operationType: 'stock_adjustment',
    );
  }

  Future<void> _queueTransfer(TransferRequest request) {
    return _offlineQueue.enqueue(
      method: 'POST',
      endpoint: '/stock_movements/transfer',
      payload: request.toJson(),
      operationType: 'stock_transfer',
    );
  }

  bool _canQueue(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => true,
      _ => false,
    };
  }

  List<Map<String, dynamic>> _unwrapList(dynamic data) {
    if (data is Map && data['data'] is List) {
      return List<Map<String, dynamic>>.from(data['data'] as List);
    }
    if (data is List) return List<Map<String, dynamic>>.from(data);
    return [];
  }
}
