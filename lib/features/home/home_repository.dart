import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import 'models/dashboard_stats.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(ref.watch(dioClientProvider));
});

class HomeRepository {
  const HomeRepository(this._dio);

  final Dio _dio;

  Future<DashboardStats> getDashboardStats() async {
    try {
      final responses = await Future.wait([
        _dio.get('/reports/daily_sales'),
        _dio.get('/reports/sales_by_hour'),
        _dio.get('/reports/payment_methods'),
        _dio.get('/reports/low_stock'),
      ]);

      return DashboardStats(
        dailySales: DailySalesSummary.fromJson(_asMap(responses[0].data)),
        salesByHour: _asList(responses[1].data, [
          'hours',
          'sales_by_hour',
        ]).map(HourlySales.fromJson).toList(),
        paymentMethods: _asList(responses[2].data, [
          'payment_methods',
          'methods',
        ]).map(PaymentMethodSummary.fromJson).toList(),
        lowStockProducts: _asList(responses[3].data, [
          'products',
          'low_stock',
          'items',
        ]).map(LowStockProduct.fromJson).toList(),
      );
    } on DioException catch (e) {
      throw dioErrorMessage(e);
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return const {};
  }

  List<Map<String, dynamic>> _asList(dynamic data, List<String> keys) {
    if (data is List) return List<Map<String, dynamic>>.from(data);
    final map = _asMap(data);
    for (final key in keys) {
      final value = map[key];
      if (value is List) return List<Map<String, dynamic>>.from(value);
    }
    return const [];
  }
}
