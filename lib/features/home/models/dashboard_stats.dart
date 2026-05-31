class DashboardStats {
  const DashboardStats({
    required this.dailySales,
    required this.salesByHour,
    required this.paymentMethods,
    required this.lowStockProducts,
  });

  final DailySalesSummary dailySales;
  final List<HourlySales> salesByHour;
  final List<PaymentMethodSummary> paymentMethods;
  final List<LowStockProduct> lowStockProducts;
}

class DailySalesSummary {
  const DailySalesSummary({
    required this.salesCount,
    required this.subtotal,
    required this.tax,
    required this.total,
  });

  final int salesCount;
  final double subtotal;
  final double tax;
  final double total;

  factory DailySalesSummary.fromJson(Map<String, dynamic> json) {
    return DailySalesSummary(
      salesCount: _parseInt(json['sales_count'] ?? json['count']),
      subtotal: _parseDouble(json['subtotal']),
      tax: _parseDouble(json['tax']),
      total: _parseDouble(json['total']),
    );
  }
}

class HourlySales {
  const HourlySales({
    required this.label,
    required this.salesCount,
    required this.total,
  });

  final String label;
  final int salesCount;
  final double total;

  factory HourlySales.fromJson(Map<String, dynamic> json) {
    return HourlySales(
      label: _hourLabel(json['hour']),
      salesCount: _parseInt(json['sales_count'] ?? json['count']),
      total: _parseDouble(json['total']),
    );
  }
}

class PaymentMethodSummary {
  const PaymentMethodSummary({
    required this.method,
    required this.amount,
    required this.paymentsCount,
  });

  final String method;
  final double amount;
  final int paymentsCount;

  factory PaymentMethodSummary.fromJson(Map<String, dynamic> json) {
    return PaymentMethodSummary(
      method: (json['method'] ?? 'SIN METODO').toString(),
      amount: _parseDouble(json['amount']),
      paymentsCount: _parseInt(json['payments_count'] ?? json['count']),
    );
  }
}

class LowStockProduct {
  const LowStockProduct({
    required this.productName,
    required this.quantity,
    required this.minStock,
    this.warehouseName,
  });

  final String productName;
  final double quantity;
  final double minStock;
  final String? warehouseName;

  factory LowStockProduct.fromJson(Map<String, dynamic> json) {
    return LowStockProduct(
      productName: (json['product_name'] ?? json['name'] ?? '').toString(),
      quantity: _parseDouble(json['quantity'] ?? json['stock']),
      minStock: _parseDouble(json['min_stock']),
      warehouseName: (json['warehouse_name'] ?? json['warehouse'])?.toString(),
    );
  }
}

double _parseDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _hourLabel(dynamic value) {
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  if (parsed == null) return value?.toString() ?? '';
  final hour = parsed.hour.toString().padLeft(2, '0');
  return '$hour:00';
}
