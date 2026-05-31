import '../../pos/models/product.dart';

class ScannedProduct {
  const ScannedProduct({required this.product, required this.stock});

  final Product product;
  final ScannedStock stock;

  factory ScannedProduct.fromJson(Map<String, dynamic> json) {
    final productJson = _asMap(json['product'] ?? json['data'] ?? json);
    final stockJson = _asMap(json['stock']);

    return ScannedProduct(
      product: Product.fromJson(productJson),
      stock: ScannedStock.fromJson(stockJson),
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }
}

class ScannedStock {
  const ScannedStock({
    required this.totalQuantity,
    this.selectedWarehouse,
    this.warehouses = const [],
  });

  final double totalQuantity;
  final ScannedWarehouseStock? selectedWarehouse;
  final List<ScannedWarehouseStock> warehouses;

  factory ScannedStock.fromJson(Map<String, dynamic> json) {
    final warehouses = json['warehouses'] is List
        ? (json['warehouses'] as List)
              .whereType<Map>()
              .map(
                (item) => ScannedWarehouseStock.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
        : <ScannedWarehouseStock>[];

    return ScannedStock(
      totalQuantity: _parseDouble(json['total_quantity']),
      selectedWarehouse: json['warehouse'] is Map
          ? ScannedWarehouseStock.fromJson(
              Map<String, dynamic>.from(json['warehouse'] as Map),
            )
          : warehouses.firstOrNull,
      warehouses: warehouses,
    );
  }
}

class ScannedWarehouseStock {
  const ScannedWarehouseStock({
    required this.warehouseId,
    required this.warehouseName,
    required this.branchId,
    required this.branchName,
    required this.quantity,
    required this.minStock,
    required this.lowStock,
    this.warehouseCode,
  });

  final int warehouseId;
  final String? warehouseCode;
  final String warehouseName;
  final int branchId;
  final String branchName;
  final double quantity;
  final double minStock;
  final bool lowStock;

  factory ScannedWarehouseStock.fromJson(Map<String, dynamic> json) {
    return ScannedWarehouseStock(
      warehouseId: _parseInt(json['warehouse_id']),
      warehouseCode: json['warehouse_code'] as String?,
      warehouseName: (json['warehouse_name'] ?? '') as String,
      branchId: _parseInt(json['branch_id']),
      branchName: (json['branch_name'] ?? '') as String,
      quantity: _parseDouble(json['quantity']),
      minStock: _parseDouble(json['min_stock']),
      lowStock: json['low_stock'] == true,
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
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
