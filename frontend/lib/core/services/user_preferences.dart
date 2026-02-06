import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  // 🔥 GETTER METHODS
  static Future<String> getUserId() async {
    final prefs = await _prefs;
    return prefs.getString('user_id') ?? '';
  }

  static Future<String> getUsername() async {
    final prefs = await _prefs;
    return prefs.getString('username') ?? '';
  }

  static Future<String> getEmail() async {
    final prefs = await _prefs;
    return prefs.getString('email') ?? '';
  }

  static Future<String> getPhone() async {
    final prefs = await _prefs;
    return prefs.getString('phone') ?? '';
  }

  static Future<String> getRole() async {
    final prefs = await _prefs;
    return prefs.getString('role') ?? 'user';
  }

  static Future<bool> isAdmin() async {
    final prefs = await _prefs;
    return prefs.getBool('is_admin') ?? false;
  }

  static Future<int> getPoints() async {
    final prefs = await _prefs;
    return prefs.getInt('point') ?? 0;
  }

  // 🔥 Kiểm tra nhanh
  static Future<bool> isLoggedIn() async {
    final prefs = await _prefs;
    return prefs.getString('username') != null;
  }

  // 🔥 Xóa thông tin đăng nhập (logout)
  static Future<void> clear() async {
    final prefs = await _prefs;
    await prefs.clear();
  }

  // 🔥 Cập nhật điểm
  static Future<void> updatePoints(int newPoints) async {
    final prefs = await _prefs;
    await prefs.setInt('point', newPoints);
  }

  // 🔥 Lấy toàn bộ thông tin user
  static Future<Map<String, dynamic>> getUserInfo() async {
    final prefs = await _prefs;
    return {
      'user_id': prefs.getString('user_id') ?? '',
      'username': prefs.getString('username') ?? '',
      'email': prefs.getString('email') ?? '',
      'phone': prefs.getString('phone') ?? '',
      'role': prefs.getString('role') ?? 'user',
      'is_admin': prefs.getBool('is_admin') ?? false,
      'point': prefs.getInt('point') ?? 0,
    };
  }
}
