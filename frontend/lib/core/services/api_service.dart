import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://green-rewards-backend.onrender.com";

  // ================== LOGIN ==================
  static Future<Map<String, dynamic>?> login(
    String username,
    String password,
  ) async {
    final res = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return null;
  }

  // ================== REGISTER ==================
  static Future<String?> register({
    required String username,
    required String email,
    required String phone,
    required String password,
  }) async {
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
  }

  // ================== GET USERS ==================
  static Future<List<dynamic>> getUsers() async {
    final res = await http.get(
      Uri.parse("$baseUrl/users"),
      headers: {"Content-Type": "application/json"},
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is List) return data;
    }
    return [];
  }

  // ================== DELETE USER ==================
  static Future<bool> deleteUser(String userId) async {
    final res = await http.delete(
      Uri.parse("$baseUrl/users/$userId"),
      headers: {"Content-Type": "application/json"},
    );

    return res.statusCode == 200 || res.statusCode == 204;
  }

  // ================== RESET POINT ==================
  static Future<bool> resetPoint(String userId) async {
    final res = await http.put(
      Uri.parse("$baseUrl/users/$userId/reset-point"),
      headers: {"Content-Type": "application/json"},
    );

    return res.statusCode == 200;
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

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    final data = jsonDecode(res.body);
    throw data["error"] ?? "Add point failed";
  }

  // ================== GET USER BY USERNAME (FIX CHO HISTORY) ==================
  static Future<Map<String, dynamic>> getUserByUsername(String username) async {
    final res = await http.get(
      Uri.parse('$baseUrl/users/$username'),
      headers: {'Content-Type': 'application/json'},
    );

    if (res.statusCode != 200) {
      throw Exception('Không tìm thấy user');
    }

    final data = jsonDecode(res.body);

    // 🔥 FIX DUY NHẤT: đảm bảo history luôn là List
    if (data['history'] == null || data['history'] is! List) {
      data['history'] = [];
    }

    return data;
  }
}
