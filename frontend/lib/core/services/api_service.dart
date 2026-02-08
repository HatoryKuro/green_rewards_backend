import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "https://green-rewards-backend.onrender.com";

  // ================== HEALTH CHECK ==================
  static Future<Map<String, dynamic>> healthCheck() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/health"),
        headers: {"Content-Type": "application/json"},
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception("Server health check failed");
      }
    } catch (e) {
      throw Exception("Lỗi kết nối đến server: ${e.toString()}");
    }
  }

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
      } else if (res.statusCode == 503) {
        throw Exception("Database không khả dụng. Vui lòng thử lại sau.");
      }
      return null;
    } catch (e) {
      throw Exception("Lỗi kết nối: ${e.toString()}");
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
      } else if (res.statusCode == 503) {
        throw Exception("Database không khả dụng. Vui lòng thử lại sau.");
      }
      return [];
    } catch (e) {
      throw Exception("Lỗi kết nối: ${e.toString()}");
    }
  }

  // ================== GET USER BY USERNAME (Dùng cho UserHome & History) ==================
  static Future<Map<String, dynamic>?> getUserByUsername(
    String username,
  ) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/users/$username'),
        headers: {'Content-Type': 'application/json'},
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else if (res.statusCode == 404) {
        return null; // User không tồn tại
      } else if (res.statusCode == 503) {
        throw Exception("Database không khả dụng. Vui lòng thử lại sau.");
      }
      return null;
    } catch (e) {
      print('Lỗi khi lấy user by username: $e');
      return null;
    }
  }

  // ================== GET CURRENT USER INFO ==================
  static Future<Map<String, dynamic>?> getCurrentUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username') ?? '';

      if (username.isEmpty) {
        return null;
      }

      return await getUserByUsername(username);
    } catch (e) {
      print('Lỗi khi lấy current user info: $e');
      return null;
    }
  }

  // ================== DELETE USER ==================
  static Future<bool> deleteUser(String userId) async {
    try {
      final res = await http.delete(
        Uri.parse("$baseUrl/users/$userId"),
        headers: {"Content-Type": "application/json"},
      );

      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ================== RESET POINT ==================
  static Future<bool> resetPoint(
    String userId, {
    String? resetBy,
    String? reason,
  }) async {
    try {
      // Lấy thông tin người reset nếu không được cung cấp
      String resetByValue = resetBy ?? '';
      if (resetByValue.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        resetByValue = prefs.getString('username') ?? 'system';
      }

      // Lý do mặc định
      String reasonValue = reason ?? 'Hệ thống lỗi nên điểm trả về 0';

      final res = await http.put(
        Uri.parse("$baseUrl/users/$userId/reset-point"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"reset_by": resetByValue, "reason": reasonValue}),
      );

      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ================== UPDATE USER ROLE ==================
  static Future<Map<String, dynamic>> updateUserRole({
    required String userId,
    required String newRole,
  }) async {
    try {
      final res = await http.put(
        Uri.parse("$baseUrl/users/$userId/role"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"role": newRole}),
      );

      if (res.statusCode == 200) {
        return {"success": true, ...jsonDecode(res.body)};
      } else if (res.statusCode == 503) {
        throw Exception("Database không khả dụng. Vui lòng thử lại sau.");
      } else {
        final data = jsonDecode(res.body);
        throw Exception(data["error"] ?? "Cập nhật role thất bại");
      }
    } catch (e) {
      throw Exception("Lỗi kết nối: ${e.toString()}");
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
    } else if (res.statusCode == 503) {
      throw Exception("Database không khả dụng. Vui lòng thử lại sau.");
    }

    // Nếu lỗi (ví dụ: bill already used), quăng lỗi ra để Flutter nhận diện
    throw Exception(data["error"] ?? "Cộng điểm thất bại");
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
      // Tạo body request, không có billCode
      Map<String, dynamic> requestBody = {
        "partner": partner,
        "point": point,
        "maxPerUser": maxPerUser,
        "expired": expired,
      };

      final res = await http.post(
        Uri.parse("$baseUrl/admin/vouchers"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      if (res.statusCode == 201) {
        return jsonDecode(res.body);
      } else if (res.statusCode == 503) {
        throw Exception("Database không khả dụng. Vui lòng thử lại sau.");
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
      } else if (res.statusCode == 503) {
        throw Exception("Database không khả dụng. Vui lòng thử lại sau.");
      }
      return [];
    } catch (e) {
      throw Exception("Lỗi kết nối: ${e.toString()}");
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
      } else if (res.statusCode == 503) {
        throw Exception("Database không khả dụng. Vui lòng thử lại sau.");
      } else {
        throw Exception(data['error'] ?? "Đổi voucher thất bại");
      }
    } catch (e) {
      throw Exception("Lỗi kết nối: ${e.toString()}");
    }
  }

  // 4. Lấy voucher của user (usable và expired/used)
  static Future<List<dynamic>> getUserVouchers(String username) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/users/$username/vouchers"),
        headers: {"Content-Type": "application/json"},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data.containsKey('vouchers')) {
          return data['vouchers'];
        }
        return [];
      } else if (res.statusCode == 503) {
        throw Exception("Database không khả dụng. Vui lòng thử lại sau.");
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
      } else if (res.statusCode == 503) {
        throw Exception("Database không khả dụng. Vui lòng thử lại sau.");
      }
      return [];
    } catch (e) {
      throw Exception("Lỗi kết nối: ${e.toString()}");
    }
  }

  // 7. Lấy chi tiết voucher
  static Future<Map<String, dynamic>> getVoucherDetail(String voucherId) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/voucher/$voucherId"),
        headers: {"Content-Type": "application/json"},
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else if (res.statusCode == 503) {
        throw Exception("Database không khả dụng. Vui lòng thử lại sau.");
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
      } else if (res.statusCode == 503) {
        throw Exception("Database không khả dụng. Vui lòng thử lại sau.");
      }
      return {};
    } catch (e) {
      throw Exception("Lỗi kết nối: ${e.toString()}");
    }
  }

  // 9. Admin: Xóa voucher
  static Future<bool> deleteVoucher(String voucherId) async {
    try {
      final res = await http.delete(
        Uri.parse("$baseUrl/admin/vouchers/$voucherId"),
        headers: {"Content-Type": "application/json"},
      );

      if (res.statusCode == 200) {
        return true;
      } else if (res.statusCode == 503) {
        throw Exception("Database không khả dụng. Vui lòng thử lại sau.");
      } else {
        final error = jsonDecode(res.body);
        throw Exception(error['error'] ?? "Xóa voucher thất bại");
      }
    } catch (e) {
      throw Exception("Lỗi kết nối: ${e.toString()}");
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
      } else if (res.statusCode == 503) {
        throw Exception("Database không khả dụng. Vui lòng thử lại sau.");
      }
      return [];
    } catch (e) {
      throw Exception("Lỗi kết nối: ${e.toString()}");
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
      } else if (res.statusCode == 503) {
        throw Exception("Database không khả dụng. Vui lòng thử lại sau.");
      }
      return [];
    } catch (e) {
      throw Exception("Lỗi kết nối: ${e.toString()}");
    }
  }

  // 3. Tạo partner mới (Admin)
  static Future<Map<String, dynamic>> createPartner({
    required String name,
    required String type,
    required String description,
    String? imageId,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/admin/partners"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "type": type,
          "description": description,
          "image_id": imageId,
        }),
      );

      if (res.statusCode == 201) {
        return jsonDecode(res.body);
      } else if (res.statusCode == 503) {
        throw Exception("Database không khả dụng. Vui lòng thử lại sau.");
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
    required String description,
    String? imageId,
  }) async {
    try {
      final res = await http.put(
        Uri.parse("$baseUrl/admin/partners/$partnerId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "type": type,
          "description": description,
          "image_id": imageId,
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
      } else if (res.statusCode == 503) {
        throw Exception("Database không khả dụng. Vui lòng thử lại sau.");
      } else {
        final error = jsonDecode(res.body);
        throw Exception(error['error'] ?? "Không tìm thấy partner");
      }
    } catch (e) {
      throw Exception("Lỗi kết nối: ${e.toString()}");
    }
  }

  // ================== IMAGE API (GridFS) ==================

  // 1. Upload ảnh cho partner
  static Future<Map<String, dynamic>> uploadPartnerImage({
    required String partnerId,
    required String imagePath,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/admin/upload-partner-image'),
      );

      request.fields['partner_id'] = partnerId;

      var file = await http.MultipartFile.fromPath(
        'image',
        imagePath,
        filename: 'partner_$partnerId.jpg',
      );
      request.files.add(file);

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var data = jsonDecode(responseData);

      if (response.statusCode == 200) {
        return data;
      } else if (response.statusCode == 503) {
        throw Exception("Database không khả dụng. Vui lòng thử lại sau.");
      } else {
        throw Exception(data['error'] ?? "Upload ảnh thất bại");
      }
    } catch (e) {
      throw Exception("Lỗi upload: ${e.toString()}");
    }
  }

  // 2. Upload ảnh từ File object
  static Future<Map<String, dynamic>> uploadPartnerImageFile({
    required String partnerId,
    required File imageFile,
  }) async {
    return await uploadPartnerImage(
      partnerId: partnerId,
      imagePath: imageFile.path,
    );
  }

  // 3. Lấy ảnh URL từ image_id
  static String getImageUrl(String? imageId) {
    if (imageId == null || imageId.isEmpty || imageId == 'null') {
      return '';
    }
    return '$baseUrl/image/$imageId';
  }

  // 4. Xóa ảnh
  static Future<bool> deleteImage(String imageId) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/admin/image/$imageId'),
        headers: {"Content-Type": "application/json"},
      );

      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ================== ERROR HANDLER ==================
  static String cleanErrorMessage(String error) {
    // Loại bỏ phần "Exception: Lỗi kết nối:" để hiển thị gọn hơn
    return error
        .replaceAll('Exception: Lỗi kết nối: ', '')
        .replaceAll('Exception: ', '')
        .trim();
  }

  // ================== COMMON ERROR HANDLING ==================
  static void handleApiError(http.Response response) {
    if (response.statusCode == 503) {
      throw Exception("Database không khả dụng. Vui lòng thử lại sau.");
    }

    final data = jsonDecode(response.body);
    throw Exception(
      data['error'] ?? "API request failed with status ${response.statusCode}",
    );
  }

  // ================== CHECK USER PERMISSIONS ==================
  static Future<Map<String, dynamic>> checkUserPermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username') ?? '';

      if (username.isEmpty) {
        return {'isAdmin': false, 'isManager': false, 'role': 'user'};
      }

      final userInfo = await getUserByUsername(username);
      if (userInfo == null) {
        return {'isAdmin': false, 'isManager': false, 'role': 'user'};
      }

      return {
        'isAdmin': userInfo['isAdmin'] ?? false,
        'isManager': userInfo['isManager'] ?? false,
        'role': userInfo['role'] ?? 'user',
      };
    } catch (e) {
      return {'isAdmin': false, 'isManager': false, 'role': 'user'};
    }
  }
}
