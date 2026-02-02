import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../features/auth/login.dart';

class ThemeLoadPage extends StatefulWidget {
  const ThemeLoadPage({Key? key}) : super(key: key);

  @override
  State<ThemeLoadPage> createState() => _ThemeLoadPageState();
}

class _ThemeLoadPageState extends State<ThemeLoadPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    // ⏱ hiệu ứng xoay
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // ⏭ delay sang Login
    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
            colors: [Color(0xFF43A047), Color(0xFF66BB6A), Color(0xFFA5D6A7)],
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

            // 🌱 LOADING CENTER
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // LOGO
                  Image.asset(
                    'assets/images/logo_truong.png',
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 30),

                  // 🌿 VÒNG XOAY LÁ
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (_, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // vòng tròn mờ
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.4),
                                  width: 3,
                                ),
                              ),
                            ),

                            // icon lá xoay quanh vòng
                            Transform.rotate(
                              angle: _controller.value * 2 * pi,
                              child: Transform.translate(
                                offset: const Offset(0, -50),
                                child: const Icon(
                                  Icons.eco,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Loading...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w500,
                    ),
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
