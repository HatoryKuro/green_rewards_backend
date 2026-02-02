import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../pages/management.dart';
import '../auth/register.dart'; // 👈 giữ đúng file bạn đang dùng

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  String error = "";

  Future<void> login() async {
    final res = await ApiService.login(
      userCtrl.text.trim(),
      passCtrl.text.trim(),
    );

    if (res != null && res["role"] == "admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const ManagementPage(key: ValueKey('management_page')),
        ),
      );
    } else {
      setState(() => error = "Login failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
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

                    const SizedBox(height: 24),

                    TextField(
                      key: const ValueKey('username_field'),
                      controller: userCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      key: const ValueKey('password_field'),
                      controller: passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        key: const ValueKey('login_button'),
                        onPressed: login,
                        child: const Text(
                          'ĐĂNG NHẬP',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),

                    // ===== NÚT ĐĂNG KÝ (ĐÃ MANG QUA) =====
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const Register()),
                        );
                      },
                      child: const Text('Tạo tài khoản user'),
                    ),

                    if (error.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        error,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
