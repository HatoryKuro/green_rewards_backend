import 'dart:async';
import 'package:flutter/material.dart';
import '../../features/auth/login.dart';

class ThemeLoadPage extends StatefulWidget {
  const ThemeLoadPage({Key? key}) : super(key: key);

  @override
  State<ThemeLoadPage> createState() => _ThemeLoadPageState();
}

class _ThemeLoadPageState extends State<ThemeLoadPage> {
  @override
  void initState() {
    super.initState();

    // Delay 2 giây rồi chuyển sang LoginPage
    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF43A047), // xanh lá đậm
              Color(0xFF66BB6A), // xanh lá vừa
              Color(0xFFA5D6A7), // xanh lá nhạt
            ],
          ),
        ),
        child: Stack(
          children: [
            // 🌿 Background icon cây cỏ
            Positioned(
              top: 80,
              left: 30,
              child: Icon(Icons.eco, size: 60, color: Colors.white24),
            ),
            Positioned(
              bottom: 120,
              right: 40,
              child: Icon(Icons.grass, size: 70, color: Colors.white24),
            ),
            Positioned(
              bottom: 40,
              left: 50,
              child: Icon(Icons.local_florist, size: 50, color: Colors.white24),
            ),

            // 🌱 Logo trung tâm
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/logo_truong.png',
                    width: 160,
                    height: 160,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
