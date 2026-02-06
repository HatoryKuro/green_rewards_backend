class UserModel {
  final String id;
  final String username;
  final String email;
  final String phone;
  final String role; // "admin", "manager", "user"
  final bool isAdmin;
  final bool isManager;
  final int point;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.phone,
    required this.role,
    required this.isAdmin,
    required this.isManager,
    required this.point,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'],
      username: json['username'],
      email: json['email'],
      phone: json['phone'],
      role: json['role'] ?? 'user',
      isAdmin: json['isAdmin'] ?? false,
      isManager:
          json['isManager'] ??
          (json['role'] == 'manager' || json['role'] == 'admin'),
      point: json['point'] ?? 0,
    );
  }
}
