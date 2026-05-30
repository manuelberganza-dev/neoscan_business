enum StockStatus { available, low, out }

class InventoryItem {
  final int id;
  final int productId;
  final String productName;
  final String sku;
  final String? imageUrl;
  final int warehouseId;
  final String warehouseName;
  final int quantity;
  final int minQuantity;

  const InventoryItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.sku,
    this.imageUrl,
    required this.warehouseId,
    required this.warehouseName,
    required this.quantity,
    required this.minQuantity,
  });

  StockStatus get status {
    if (quantity <= 0) return StockStatus.out;
    if (quantity <= minQuantity) return StockStatus.low;
    return StockStatus.available;
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    final warehouse = json['warehouse'] as Map<String, dynamic>?;
    return InventoryItem(
      id: json['id'] as int,
      productId: product?['id'] as int? ?? json['product_id'] as int,
      productName: product?['name'] as String? ?? json['product_name'] as String? ?? '',
      sku: product?['sku'] as String? ?? json['sku'] as String? ?? '',
      imageUrl: product?['image_url'] as String?,
      warehouseId: warehouse?['id'] as int? ?? json['warehouse_id'] as int,
      warehouseName: warehouse?['name'] as String? ?? json['warehouse_name'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      minQuantity: json['min_quantity'] as int? ?? json['minimum_quantity'] as int? ?? 0,
    );
  }
}
