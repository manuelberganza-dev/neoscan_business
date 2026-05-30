class User {
  final int id;
  final String name;
  final String email;
  final String? role;
  final String? branch;
  final String? store;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    this.branch,
    this.store,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        name: (json['name'] ?? json['full_name'] ?? '') as String,
        email: json['email'] as String,
        role: json['role'] as String?,
        branch: json['branch'] is Map
            ? json['branch']['name'] as String?
            : json['branch'] as String?,
        store: json['store'] is Map
            ? json['store']['name'] as String?
            : json['store'] as String?,
      );
}
