class Warehouse {
  final int id;
  final String name;
  final String? description;

  const Warehouse({required this.id, required this.name, this.description});

  factory Warehouse.fromJson(Map<String, dynamic> json) => Warehouse(
    id: json['id'] as int,
    name: json['name'] as String,
    description: json['description'] as String?,
  );

  @override
  bool operator ==(Object other) => other is Warehouse && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
