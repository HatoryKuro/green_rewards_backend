import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'management.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  String error = "";

  void login() async {
    final res = await ApiService.login(userCtrl.text, passCtrl.text);

    if (res != null && res["role"] == "admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ManagementPage()),
      );
    } else {
      setState(() => error = "Login failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Admin Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: userCtrl,
              decoration: InputDecoration(labelText: "Username"),
            ),
            TextField(
              controller: passCtrl,
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            ElevatedButton(onPressed: login, child: Text("Login")),
            Text(error, style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
