import 'package:flutter/material.dart';
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

  // ================= LOGIN =================
  Future<void> login() async {
    final res = await ApiService.login(
      userCtrl.text.trim(),
      passCtrl.text.trim(),
    );

    if (res == null) {
      _showErrorPopup("Sai tài khoản hoặc mật khẩu");
      return;
    }

    final role = res["role"];

    if (role == "admin") {
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
      _showErrorPopup("Role không hợp lệ");
    }
  }

  // ================= POPUP ERROR =================
  void _showErrorPopup(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: const [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text("Đăng nhập thất bại"),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
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
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                      ),
                    ),

                    const SizedBox(height: 26),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text(
                          'ĐĂNG NHẬP',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextButton(
                      onPressed: _confirmGoRegister,
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
