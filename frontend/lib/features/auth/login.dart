import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:green_rewards/features/pages/admin_home.dart';
import '../../core/services/api_service.dart';
import '../auth/register.dart';
import '../pages/user_home.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  bool loading = false;
  String error = "";

  // ================= LOGIN =================
  Future<void> login() async {
    if (userCtrl.text.isEmpty || passCtrl.text.isEmpty) {
      setState(() {
        error = "Vui lòng điền đầy đủ thông tin";
      });
      return;
    }

    setState(() {
      loading = true;
      error = "";
    });

    try {
      final res = await ApiService.login(
        userCtrl.text.trim(),
        passCtrl.text.trim(),
      );

      // 🔥 FIX LỖI CONTEXT CHẾT
      if (!mounted) return;

      setState(() => loading = false);

      if (res == null) {
        setState(() {
          error = "Sai tài khoản hoặc mật khẩu";
        });
        return;
      }

      final userId = res["_id"] ?? "";
      final role = res["role"];
      final username = res["username"];
      final email = res["email"] ?? "";
      final phone = res["phone"] ?? "";
      final isAdmin = res["isAdmin"] ?? false;
      final isManager = res["isManager"] ?? false; // Thêm field isManager
      final point = res["point"] ?? 0;

      // 🔥 LƯU ĐẦY ĐỦ THÔNG TIN NGƯỜI DÙNG VÀO SHAREDPREFERENCES
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', userId);
      await prefs.setString('username', username);
      await prefs.setString('email', email);
      await prefs.setString('phone', phone);
      await prefs.setString('role', role);
      await prefs.setBool('is_admin', isAdmin);
      await prefs.setBool('is_manager', isManager); // Lưu isManager
      await prefs.setInt('point', point);

      // 🔥 FIX TIẾP (sau await)
      if (!mounted) return;

      // Xử lý điều hướng theo role
      // ✅ CHỈNH SỬA: Cả admin và manager đều vào AdminHome
      if (role == "admin" || role == "manager") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminHome()),
        );
      } else if (role == "user") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const UserHome()),
        );
      } else {
        setState(() {
          error = "Role không hợp lệ: $role";
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = "Lỗi kết nối: $e";
      });
    }
  }

  // ================= CONFIRM REGISTER =================
  void _confirmGoRegister() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.eco, color: Colors.green, size: 28),
                  const SizedBox(width: 8),
                  const Text(
                    "Tạo tài khoản",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                "Bạn có chắc muốn chuyển sang trang đăng ký tài khoản không?",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Hủy"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const Register()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text("Đồng ý"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/icon/app_icon2.png', height: 120),
                    const SizedBox(height: 12),
                    const Text(
                      'GreenRewards',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Cùng nhau sống xanh 🌱",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: userCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Username / Email / Phone',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (error.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        error,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: loading ? null : login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'ĐĂNG NHẬP',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: loading ? null : _confirmGoRegister,
                      child: const Text(
                        'Tạo tài khoản user',
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
