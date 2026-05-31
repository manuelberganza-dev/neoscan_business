class Product {
  final int id;
  final String name;
  final String sku;
  final String? barcode;
  final double price;
  final String? imageUrl;
  final String? category;
  final String? brand;
  final String? unitCode;
  final double taxRate;
  final int? stock;

  const Product({
    required this.id,
    required this.name,
    required this.sku,
    this.barcode,
    required this.price,
    this.imageUrl,
    this.category,
    this.brand,
    this.unitCode,
    this.taxRate = 0,
    this.stock,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as int,
    name: json['name'] as String,
    sku: (json['sku'] ?? json['barcode'] ?? '') as String,
    barcode: json['barcode'] as String?,
    price: _parseDouble(json['price'] ?? json['sale_price'] ?? 0),
    imageUrl: json['image_url'] as String?,
    category:
        (json['category_name'] ??
                (json['category'] is Map ? json['category']['name'] : null) ??
                json['category'])
            as String?,
    brand:
        (json['brand_name'] ??
                (json['brand'] is Map ? json['brand']['name'] : null) ??
                json['brand'])
            as String?,
    unitCode: json['unit_code'] as String?,
    taxRate: _parseDouble(json['tax_rate']),
    stock: _parseInt(json['stock'] ?? json['total_quantity']),
  );

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value.toString());
  }
}
