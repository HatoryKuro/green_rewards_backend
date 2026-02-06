import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "https://green-rewards-backend.onrender.com";

  // ================== GET HEADERS WITH TOKEN ==================
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final headers = {"Content-Type": "application/json"};

    if (token.isNotEmpty) {
      headers["Authorization"] = "Bearer $token";
    }

    return headers;
  }

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
  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        // Lưu thông tin user và token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', data['username']);
        await prefs.setString('token', data['token'] ?? '');
        await prefs.setString('userId', data['_id'] ?? '');
        await prefs.setString('role', data['role'] ?? 'user');
        await prefs.setBool('isAdmin', data['isAdmin'] ?? false);
        await prefs.setBool('isManager', data['isManager'] ?? false);

        return data;
      } else if (res.statusCode == 503) {
        throw Exception("Database không khả dụng. Vui lòng thử lại sau.");
      } else {
        throw Exception(data["error"] ?? "Đăng nhập thất bại");
      }
    } catch (e) {
      throw Exception("Lỗi kết nối: ${e.toString()}");
    }
  }

  // ================== REGISTER ==================
  static Future<Map<String, dynamic>> register({
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

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        return {"success": true, "message": "Đăng ký thành công"};
      } else {
        throw Exception(data["error"] ?? "Đăng ký thất bại");
      }
    } catch (e) {
      throw Exception("Lỗi kết nối Server: ${e.toString()}");
    }
  }

  // ================== GET USERS (Dùng cho Management) ==================
  static Future<List<dynamic>> getUsers() async {
    try {
      final headers = await _getHeaders();
      final res = await http.get(Uri.parse("$baseUrl/users"), headers: headers);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) return data;
        return [];
      } else if (res.statusCode == 503) {
        throw Exception("Database không khả dụng. Vui lòng thử lại sau.");
      } else {
        final errorData = jsonDecode(res.body);
        throw Exception(
          errorData["error"] ?? "Không thể lấy danh sách người dùng",
        );
      }
    } catch (e) {
      throw Exception("Lỗi kết nối: ${e.toString()}");
    }
  }

  // ================== DELETE USER ==================
  static Future<bool> deleteUser(String userId) async {
    try {
      final headers = await _getHeaders();
      final res = await http.delete(
        Uri.parse("$baseUrl/users/$userId"),
        headers: headers,
      );

      final data = jsonDecode(res.body);
      return data["success"] == true;
    } catch (e) {
      return false;
    }
  }

  // ================== RESET POINT ==================
  static Future<bool> resetPoint(
    String userId, {
    String message = "Điểm đã được reset bởi quản trị viên",
  }) async {
    try {
      final headers = await _getHeaders();
      final res = await http.post(
        Uri.parse("$baseUrl/users/$userId/reset-point"),
        headers: headers,
        body: jsonEncode({"message": message}),
      );

      final data = jsonDecode(res.body);
      return data["success"] == true;
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
      final headers = await _getHeaders();
      final res = await http.put(
        Uri.parse("$baseUrl/users/$userId/role"),
        headers: headers,
        body: jsonEncode({"role": newRole}),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data["success"] == true) {
        return data;
      } else if (res.statusCode == 503) {
        throw Exception("Database không khả dụng. Vui lòng thử lại sau.");
      } else {
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
    try {
      final headers = await _getHeaders();
      final res = await http.post(
        Uri.parse("$baseUrl/scan/add-point"),
        headers: headers,
        body: jsonEncode({
          "username": username,
          "partner": partner,
          "billCode": billCode,
          "point": point,
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data["success"] == true) {
        return data;
      } else if (res.statusCode == 503) {
        throw Exception("Database không khả dụng. Vui lòng thử lại sau.");
      } else {
        throw Exception(data["error"] ?? "Cộng điểm thất bại");
      }
    } catch (e) {
      throw Exception("Lỗi kết nối: ${e.toString()}");
    }
  }

  // ================== GET USER BY USERNAME ==================
  static Future<Map<String, dynamic>> getUserByUsername(String username) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/users/$username'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        return data;
      } else if (res.statusCode == 404) {
        throw Exception('Không tìm thấy thông tin user này');
      } else if (res.statusCode == 503) {
        throw Exception("Database không khả dụng. Vui lòng thử lại sau.");
      } else {
        throw Exception(data["error"] ?? 'Lỗi hệ thống: ${res.statusCode}');
      }
    } catch (e) {
      throw Exception("Lỗi kết nối: ${e.toString()}");
    }
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
      final headers = await _getHeaders();
      final res = await http.post(
        Uri.parse("$baseUrl/admin/vouchers"),
        headers: headers,
        body: jsonEncode({
          "partner": partner,
          "point": point,
          "maxPerUser": maxPerUser,
          "expired": expired,
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 201 && data["success"] == true) {
        return data;
      } else if (res.statusCode == 503) {
        throw Exception("Database không khả dụng. Vui lòng thử lại sau.");
      } else {
        throw Exception(data['error'] ?? "Tạo voucher thất bại");
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
      final headers = await _getHeaders();
      final res = await http.post(
        Uri.parse("$baseUrl/users/$username/exchange-voucher"),
        headers: headers,
        body: jsonEncode({"voucher_id": voucherId}),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data["success"] == true) {
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

  // 4. Lấy voucher của user
  static Future<Map<String, dynamic>> getUserVouchers(String username) async {
    try {
      final headers = await _getHeaders();
      final res = await http.get(
        Uri.parse("$baseUrl/users/$username/vouchers"),
        headers: headers,
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
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
      final headers = await _getHeaders();
      final res = await http.put(
        Uri.parse("$baseUrl/vouchers/$voucherId/use"),
        headers: headers,
      );

      final data = jsonDecode(res.body);
      return data["success"] == true;
    } catch (e) {
      return false;
    }
  }

  // 6. Admin: Lấy tất cả voucher
  static Future<List<dynamic>> getAllVouchers() async {
    try {
      final headers = await _getHeaders();
      final res = await http.get(
        Uri.parse("$baseUrl/admin/vouchers"),
        headers: headers,
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
      final headers = await _getHeaders();
      final res = await http.get(
        Uri.parse("$baseUrl/admin/vouchers/stats"),
        headers: headers,
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

  // 2. Lấy danh sách tên partners
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
      final headers = await _getHeaders();
      final res = await http.post(
        Uri.parse("$baseUrl/admin/partners"),
        headers: headers,
        body: jsonEncode({
          "name": name,
          "type": type,
          "description": description,
          "image_id": imageId,
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 201 && data["success"] == true) {
        return data;
      } else if (res.statusCode == 503) {
        throw Exception("Database không khả dụng. Vui lòng thử lại sau.");
      } else {
        throw Exception(data['error'] ?? "Tạo partner thất bại");
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
      final headers = await _getHeaders();
      final res = await http.put(
        Uri.parse("$baseUrl/admin/partners/$partnerId"),
        headers: headers,
        body: jsonEncode({
          "name": name,
          "type": type,
          "description": description,
          "image_id": imageId,
        }),
      );

      final data = jsonDecode(res.body);
      return data["success"] == true;
    } catch (e) {
      return false;
    }
  }

  // 5. Xóa partner (Admin)
  static Future<bool> deletePartner(String partnerId) async {
    try {
      final headers = await _getHeaders();
      final res = await http.delete(
        Uri.parse("$baseUrl/admin/partners/$partnerId"),
        headers: headers,
      );

      final data = jsonDecode(res.body);
      return data["success"] == true;
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

  // ================== IMAGE API ==================

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

      final headers = await _getHeaders();
      request.headers.addAll(headers);

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

      if (response.statusCode == 200 && data["success"] == true) {
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

  // 2. Upload ảnh từ File object - FIXED: Thêm đúng parameters
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
      final headers = await _getHeaders();
      final res = await http.delete(
        Uri.parse('$baseUrl/admin/image/$imageId'),
        headers: headers,
      );

      final data = jsonDecode(res.body);
      return data["success"] == true;
    } catch (e) {
      return false;
    }
  }

  // ================== CLEAN ERROR MESSAGE ==================
  static String cleanErrorMessage(String error) {
    // Loại bỏ phần "Exception: Lỗi kết nối:" để hiển thị gọn hơn
    return error
        .replaceAll('Exception: Lỗi kết nối: ', '')
        .replaceAll('Exception: ', '')
        .trim();
  }

  // ================== GET CURRENT USER INFO ==================
  static Future<Map<String, dynamic>> getCurrentUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username') ?? '';

      if (username.isEmpty) {
        throw Exception("Chưa đăng nhập");
      }

      return await getUserByUsername(username);
    } catch (e) {
      throw Exception("Không thể lấy thông tin user: ${e.toString()}");
    }
  }

  // ================== CLEAR TOKEN (LOGOUT) ==================
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('username');
    await prefs.remove('userId');
    await prefs.remove('role');
    await prefs.remove('isAdmin');
    await prefs.remove('isManager');
  }

  // ================== GET USER PREFERENCES ==================
  static Future<Map<String, dynamic>> getUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'username': prefs.getString('username') ?? '',
      'token': prefs.getString('token') ?? '',
      'userId': prefs.getString('userId') ?? '',
      'role': prefs.getString('role') ?? 'user',
      'isAdmin': prefs.getBool('isAdmin') ?? false,
      'isManager': prefs.getBool('isManager') ?? false,
    };
  }

  // ================== CHECK IF USER IS LOGGED IN ==================
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null && token.isNotEmpty;
  }
}
