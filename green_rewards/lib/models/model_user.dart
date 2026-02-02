class UserModel {
  final String id;
  final String username;
  final String email;
  final String phone;
  final bool isAdmin;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.phone,
    required this.isAdmin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'],
      username: json['username'],
      email: json['email'],
      phone: json['phone'],
      isAdmin: json['isAdmin'],
    );
  }
}
