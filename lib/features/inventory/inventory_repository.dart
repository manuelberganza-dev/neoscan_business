import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import 'models/inventory_item.dart';
import 'models/stock_movement.dart';
import 'models/warehouse.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>(
  (ref) => InventoryRepository(ref.read(dioClientProvider)),
);

class InventoryRepository {
  final Dio _dio;
  const InventoryRepository(this._dio);

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
    try {
      await _dio.post('/stock_movements', data: request.toJson());
    } on DioException catch (e) {
      throw dioErrorMessage(e);
    }
  }

  // ── Transfers ─────────────────────────────────────────────────────────────

  Future<void> createTransfer(TransferRequest request) async {
    try {
      await _dio.post('/stock_movements/transfer', data: request.toJson());
    } on DioException catch (e) {
      throw dioErrorMessage(e);
    }
  }

  List<Map<String, dynamic>> _unwrapList(dynamic data) {
    if (data is Map && data['data'] is List) {
      return List<Map<String, dynamic>>.from(data['data'] as List);
    }
    if (data is List) return List<Map<String, dynamic>>.from(data);
    return [];
  }
}
