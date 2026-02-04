import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://green-rewards-backend.onrender.com";

  // ================== LOGIN ==================
  static Future<Map<String, dynamic>?> login(
    String username,
    String password,
  ) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ================== REGISTER ==================
  static Future<String?> register({
    required String username,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "email": email,
          "phone": phone,
          "password": password,
        }),
      );

      if (res.statusCode == 200) return null;

      final data = jsonDecode(res.body);
      return data["error"] ?? "Register failed";
    } catch (e) {
      return "Lỗi kết nối Server";
    }
  }

  // ================== GET USERS (Dùng cho Management) ==================
  static Future<List<dynamic>> getUsers() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/users"),
        headers: {"Content-Type": "application/json"},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) return data;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ================== DELETE USER ==================
  static Future<bool> deleteUser(String userId) async {
    try {
      final res = await http.delete(
        Uri.parse("$baseUrl/users/$userId"),
        headers: {"Content-Type": "application/json"},
      );

      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  // ================== RESET POINT ==================
  static Future<bool> resetPoint(String userId) async {
    try {
      final res = await http.put(
        Uri.parse("$baseUrl/users/$userId/reset-point"),
        headers: {"Content-Type": "application/json"},
      );

      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ================== ADD POINT BY QR ==================
  static Future<Map<String, dynamic>> addPointByQR({
    required String username,
    required String partner,
    required String billCode,
    required int point,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/scan/add-point"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "partner": partner,
        "billCode": billCode,
        "point": point,
      }),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 200) {
      return data;
    }

    // Nếu lỗi (ví dụ: bill already used), quăng lỗi ra để Flutter nhận diện
    throw data["error"] ?? "Cộng điểm thất bại";
  }

  // ================== GET USER BY USERNAME (Dùng cho History) ==================
  static Future<Map<String, dynamic>> getUserByUsername(String username) async {
    // Lưu ý: Route này phải khớp với @app.route("/users/<username>") bên Backend
    final res = await http.get(
      Uri.parse('$baseUrl/users/$username'),
      headers: {'Content-Type': 'application/json'},
    );

    if (res.statusCode == 404) {
      throw Exception('Không tìm thấy thông tin user này');
    }

    if (res.statusCode != 200) {
      throw Exception('Lỗi hệ thống: ${res.statusCode}');
    }

    final data = jsonDecode(res.body);

    // Đảm bảo history luôn có kiểu dữ liệu chuẩn List để không bị crash giao diện
    if (data['history'] == null || data['history'] is! List) {
      data['history'] = [];
    }

    return data;
  }
}
