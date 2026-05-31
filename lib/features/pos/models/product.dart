class Product {
  final int id;
  final String name;
  final String sku;
  final double price;
  final String? imageUrl;
  final String? category;
  final int? stock;

  const Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.price,
    this.imageUrl,
    this.category,
    this.stock,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as int,
    name: json['name'] as String,
    sku: (json['sku'] ?? json['barcode'] ?? '') as String,
    price: _parseDouble(json['price'] ?? json['sale_price'] ?? 0),
    imageUrl: json['image_url'] as String?,
    category: json['category'] is Map
        ? json['category']['name'] as String?
        : json['category'] as String?,
    stock: json['stock'] as int?,
  );

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}
