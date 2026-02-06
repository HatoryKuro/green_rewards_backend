import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/api_service.dart';
import '../pages/user_home.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final userCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  bool loading = false;
  String error = "";

  Future<void> register() async {
    // Validate
    if (userCtrl.text.isEmpty ||
        emailCtrl.text.isEmpty ||
        phoneCtrl.text.isEmpty ||
        passCtrl.text.isEmpty) {
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
      final err = await ApiService.register(
        username: userCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );

      if (!mounted) return;

      setState(() => loading = false);

      if (err == null) {
        // 🔥 ĐĂNG KÝ THÀNH CÔNG - TỰ ĐỘNG ĐĂNG NHẬP
        try {
          final loginRes = await ApiService.login(
            userCtrl.text.trim(),
            passCtrl.text.trim(),
          );

          if (loginRes == null) {
            setState(() {
              error = "Đăng ký thành công nhưng đăng nhập thất bại";
            });
            return;
          }

          // 🔥 LƯU THÔNG TIN NGƯỜI DÙNG VÀO SHAREDPREFERENCES
          final userId = loginRes["_id"] ?? "";
          final role = loginRes["role"] ?? "user";
          final username = loginRes["username"];
          final email = loginRes["email"] ?? "";
          final phone = loginRes["phone"] ?? "";
          final isAdmin = loginRes["isAdmin"] ?? false;
          final point = loginRes["point"] ?? 0;

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_id', userId);
          await prefs.setString('username', username);
          await prefs.setString('email', email);
          await prefs.setString('phone', phone);
          await prefs.setString('role', role);
          await prefs.setBool('is_admin', isAdmin);
          await prefs.setInt('point', point);

          if (!mounted) return;

          // 🔥 CHUYỂN ĐẾN TRANG USER HOME
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const UserHome()),
            (_) => false,
          );
        } catch (loginError) {
          setState(() {
            error = "Đăng ký thành công nhưng đăng nhập thất bại: $loginError";
          });
        }
      } else {
        setState(() => error = err);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = "Lỗi kết nối: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tạo tài khoản user"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    'Đăng ký tài khoản mới',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Tham gia cùng GreenRewards 🌱",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: userCtrl,
                    decoration: const InputDecoration(
                      labelText: "Tên đăng nhập",
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                      hintText: "Nhập tên đăng nhập",
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                      hintText: "example@email.com",
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(
                      labelText: "Số điện thoại",
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                      hintText: "0123456789",
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Mật khẩu",
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                      hintText: "Nhập mật khẩu",
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: loading ? null : register,
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
                              "ĐĂNG KÝ",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  if (error.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[100]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              error,
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      '← Quay lại đăng nhập',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
