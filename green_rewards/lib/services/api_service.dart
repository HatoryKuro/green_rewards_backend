import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://green-rewards-backend.onrender.com";

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

  static Future<List<dynamic>> getUsers() async {
    final res = await http.get(Uri.parse("$baseUrl/users"));
    return jsonDecode(res.body);
  }
}
