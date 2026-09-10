class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role; 
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}
