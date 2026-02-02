import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://green-rewards-backend.onrender.com";

  // ---------- LOGIN ----------
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

  // ---------- REGISTER (THÊM EMAIL, KHÔNG ĐỔI FLOW) ----------
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

    if (res.statusCode == 200) {
      return null;
    } else {
      final data = jsonDecode(res.body);
      return data["error"] ?? "Register failed";
    }
  }

  // ---------- GET USERS ----------
  static Future<List<dynamic>> getUsers() async {
    final res = await http.get(Uri.parse("$baseUrl/users"));
    return jsonDecode(res.body);
  }
}
