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

    // Đảm bảo history luôn có
    if (data['history'] == null || data['history'] is! List) {
      data['history'] = [];
    }

    return data;
  }

  // ================== VOUCHER API ==================

  // 1. Admin: Tạo voucher mới
  static Future<Map<String, dynamic>> createVoucher({
    required String partner,
    required int point,
    required int maxPerUser,
    required String expired,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/admin/vouchers"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "partner": partner,
          "point": point,
          "maxPerUser": maxPerUser,
          "expired": expired,
        }),
      );

      if (res.statusCode == 201) {
        return jsonDecode(res.body);
      } else {
        final error = jsonDecode(res.body);
        throw Exception(error['error'] ?? "Tạo voucher thất bại");
      }
    } catch (e) {
      throw Exception("Lỗi kết nối: ${e.toString()}");
    }
  }

  // 2. Lấy danh sách voucher có sẵn để đổi
  static Future<List<dynamic>> getAvailableVouchers() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/vouchers"),
        headers: {"Content-Type": "application/json"},
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return [];
    } catch (e) {
      print('Error getting available vouchers: $e');
      return [];
    }
  }

  // 3. User đổi voucher bằng điểm
  static Future<Map<String, dynamic>> exchangeVoucher({
    required String username,
    required String voucherId,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/users/$username/exchange-voucher"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"voucher_id": voucherId}),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['error'] ?? "Đổi voucher thất bại");
      }
    } catch (e) {
      throw Exception("Lỗi kết nối: ${e.toString()}");
    }
  }

  // 4. Lấy voucher của user (usable và expired/used)
  static Future<Map<String, dynamic>> getUserVouchers(String username) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/users/$username/vouchers"),
        headers: {"Content-Type": "application/json"},
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        final error = jsonDecode(res.body);
        throw Exception(error['error'] ?? "Không thể lấy voucher");
      }
    } catch (e) {
      throw Exception("Lỗi kết nối: ${e.toString()}");
    }
  }

  // 5. Đánh dấu voucher đã sử dụng
  static Future<bool> markVoucherUsed(String voucherId) async {
    try {
      final res = await http.put(
        Uri.parse("$baseUrl/vouchers/$voucherId/use"),
        headers: {"Content-Type": "application/json"},
      );

      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 6. Admin: Lấy tất cả voucher (quản lý)
  static Future<List<dynamic>> getAllVouchers() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/admin/vouchers"),
        headers: {"Content-Type": "application/json"},
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return [];
    } catch (e) {
      print('Error getting all vouchers: $e');
      return [];
    }
  }

  // 7. Lấy chi tiết voucher
  static Future<Map<String, dynamic>> getVoucherDetail(String voucherId) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/vouchers/$voucherId"),
        headers: {"Content-Type": "application/json"},
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        final error = jsonDecode(res.body);
        throw Exception(error['error'] ?? "Không tìm thấy voucher");
      }
    } catch (e) {
      throw Exception("Lỗi kết nối: ${e.toString()}");
    }
  }

  // 8. Admin: Thống kê voucher
  static Future<Map<String, dynamic>> getVoucherStats() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/admin/vouchers/stats"),
        headers: {"Content-Type": "application/json"},
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return {};
    } catch (e) {
      print('Error getting voucher stats: $e');
      return {};
    }
  }

  // ================== PARTNER API ==================

  // 1. Lấy danh sách tất cả partners
  static Future<List<dynamic>> getPartners() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/partners"),
        headers: {"Content-Type": "application/json"},
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return [];
    } catch (e) {
      print('Error getting partners: $e');
      return [];
    }
  }

  // 2. Lấy danh sách tên partners (cho dropdown)
  static Future<List<dynamic>> getPartnerNames() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/partners/names"),
        headers: {"Content-Type": "application/json"},
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return [];
    } catch (e) {
      print('Error getting partner names: $e');
      return [];
    }
  }

  // 3. Tạo partner mới (Admin)
  static Future<Map<String, dynamic>> createPartner({
    required String name,
    required String type,
    required String priceRange,
    required String segment,
    required String description,
    String imageUrl = '',
  }) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/admin/partners"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "type": type,
          "price_range": priceRange,
          "segment": segment,
          "description": description,
          "image_url": imageUrl,
        }),
      );

      if (res.statusCode == 201) {
        return jsonDecode(res.body);
      } else {
        final error = jsonDecode(res.body);
        throw Exception(error['error'] ?? "Tạo partner thất bại");
      }
    } catch (e) {
      throw Exception("Lỗi kết nối: ${e.toString()}");
    }
  }

  // 4. Cập nhật partner (Admin)
  static Future<bool> updatePartner({
    required String partnerId,
    required String name,
    required String type,
    required String priceRange,
    required String segment,
    required String description,
    String imageUrl = '',
  }) async {
    try {
      final res = await http.put(
        Uri.parse("$baseUrl/admin/partners/$partnerId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "type": type,
          "price_range": priceRange,
          "segment": segment,
          "description": description,
          "image_url": imageUrl,
        }),
      );

      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 5. Xóa partner (Admin)
  static Future<bool> deletePartner(String partnerId) async {
    try {
      final res = await http.delete(
        Uri.parse("$baseUrl/admin/partners/$partnerId"),
        headers: {"Content-Type": "application/json"},
      );

      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 6. Lấy chi tiết partner
  static Future<Map<String, dynamic>> getPartner(String partnerId) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/partners/$partnerId"),
        headers: {"Content-Type": "application/json"},
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        final error = jsonDecode(res.body);
        throw Exception(error['error'] ?? "Không tìm thấy partner");
      }
    } catch (e) {
      throw Exception("Lỗi kết nối: ${e.toString()}");
    }
  }
}
