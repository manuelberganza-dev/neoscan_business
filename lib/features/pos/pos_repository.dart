import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import 'models/cash_session.dart';
import 'models/product.dart';
import 'models/sale.dart';

final posRepositoryProvider = Provider<PosRepository>(
  (ref) => PosRepository(ref.read(dioClientProvider)),
);

class PosRepository {
  final Dio _dio;
  const PosRepository(this._dio);

  // ── Cash session ──────────────────────────────────────────────────────────

  Future<CashSession?> getActiveSession() async {
    try {
      final response = await _dio.get('/cash_sessions/active');
      final data = _unwrap(response.data);
      return CashSession.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw dioErrorMessage(e);
    }
  }

  Future<CashSession> openSession({
    required double initialAmount,
    String? notes,
  }) async {
    try {
      final response = await _dio.post(
        '/cash_sessions',
        data: {
          'cash_session': {
            'initial_amount': initialAmount,
            if (notes != null && notes.isNotEmpty) 'notes': notes,
          },
        },
      );
      return CashSession.fromJson(_unwrap(response.data));
    } on DioException catch (e) {
      throw dioErrorMessage(e);
    }
  }

  Future<CashSession> closeSession(int sessionId, {String? notes}) async {
    try {
      final response = await _dio.patch(
        '/cash_sessions/$sessionId/close',
        data: {
          'cash_session': {
            if (notes != null && notes.isNotEmpty) 'notes': notes,
          },
        },
      );
      return CashSession.fromJson(_unwrap(response.data));
    } on DioException catch (e) {
      throw dioErrorMessage(e);
    }
  }

  // ── Product scan ──────────────────────────────────────────────────────────

  Future<Product> scanProduct(String barcode) async {
    try {
      final response = await _dio.get(
        '/mobile/scan_product',
        queryParameters: {'barcode': barcode},
      );
      return Product.fromJson(_unwrap(response.data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) throw 'Producto no encontrado';
      throw dioErrorMessage(e);
    }
  }

  // ── Sales ─────────────────────────────────────────────────────────────────

  Future<void> processSale(SaleRequest request) async {
    try {
      await _dio.post('/sales', data: request.toJson());
    } on DioException catch (e) {
      throw dioErrorMessage(e);
    }
  }

  Map<String, dynamic> _unwrap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return (data['data'] ?? data) as Map<String, dynamic>;
    }
    return data as Map<String, dynamic>;
  }
}
