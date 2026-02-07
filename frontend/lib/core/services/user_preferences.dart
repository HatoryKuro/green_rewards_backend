import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  // ================== SAVE USER INFO ==================
  static Future<void> saveUserInfo({
    required String userId,
    required String username,
    required String email,
    required String phone,
    required String role,
    required bool isAdmin,
    required bool isManager,
    required int point,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
    await prefs.setString('username', username);
    await prefs.setString('email', email);
    await prefs.setString('phone', phone);
    await prefs.setString('role', role);
    await prefs.setBool('is_admin', isAdmin);
    await prefs.setBool('is_manager', isManager);
    await prefs.setInt('point', point);
  }

  // ================== GETTERS ==================
  static Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id') ?? '';
  }

  static Future<String> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username') ?? '';
  }

  static Future<String> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email') ?? '';
  }

  static Future<String> getPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('phone') ?? '';
  }

  static Future<String> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role') ?? 'user';
  }

  static Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role') ?? 'user';
    final isAdmin = prefs.getBool('is_admin') ?? false;
    return role == 'admin' || isAdmin;
  }

  static Future<bool> isManager() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role') ?? 'user';
    final isManager = prefs.getBool('is_manager') ?? false;
    return role == 'manager' || role == 'admin' || isManager;
  }

  static Future<int> getPoint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('point') ?? 0;
  }

  // ================== UPDATE METHODS ==================
  static Future<void> updatePoint(int newPoint) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('point', newPoint);
  }

  static Future<void> updateRole(String newRole) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', newRole);

    if (newRole == 'admin') {
      await prefs.setBool('is_admin', true);
      await prefs.setBool('is_manager', true);
    } else if (newRole == 'manager') {
      await prefs.setBool('is_admin', false);
      await prefs.setBool('is_manager', true);
    } else {
      await prefs.setBool('is_admin', false);
      await prefs.setBool('is_manager', false);
    }
  }

  // ================== CHECK METHODS ==================
  static Future<bool> isUser() async {
    final role = await getRole();
    return role == 'user';
  }

  static Future<bool> isAdminOrManager() async {
    final role = await getRole();
    return role == 'admin' || role == 'manager';
  }

  // ================== CLEAR DATA ==================
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ================== VALIDATION ==================
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    return username != null && username.isNotEmpty;
  }

  // ================== GET ALL USER INFO ==================
  static Future<Map<String, dynamic>> getAllUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'user_id': prefs.getString('user_id') ?? '',
      'username': prefs.getString('username') ?? '',
      'email': prefs.getString('email') ?? '',
      'phone': prefs.getString('phone') ?? '',
      'role': prefs.getString('role') ?? 'user',
      'is_admin': prefs.getBool('is_admin') ?? false,
      'is_manager': prefs.getBool('is_manager') ?? false,
      'point': prefs.getInt('point') ?? 0,
    };
  }
}
