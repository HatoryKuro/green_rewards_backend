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

    // ⏱ Hiệu ứng quay chậm và mượt hơn
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // ⏭ Chuyển trang sau 5 giây
    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B5E20), Color(0xFF43A047), Color(0xFF81C784)],
          ),
        ),
        child: Stack(
          children: [
            // 🌿 Họa tiết trang trí chìm
            Positioned(
              top: -50,
              right: -50,
              child: Icon(
                Icons.eco,
                size: 200,
                color: Colors.white.withOpacity(0.1),
              ),
            ),

            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // LOGO TRƯỜNG
                  Image.asset(
                    'assets/images/logo_truong.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 60),

                  // 🌱 HIỆU ỨNG LOADING CHUYÊN NGHIỆP
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Vòng cung vẽ bằng CustomPainter
                      RotationTransition(
                        turns: _controller,
                        child: SizedBox(
                          width: 150,
                          height: 150,
                          child: CustomPaint(painter: LeafLoaderPainter()),
                        ),
                      ),
                      // Chữ Loading nằm ở giữa tâm vòng xoay
                      const Text(
                        'Loading...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Slogan hoặc tên ứng dụng phía dưới
                  Text(
                    'GREEN REWARDS',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
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

// 🎨 Lớp vẽ vòng cung và chiếc lá dẫn đầu
class LeafLoaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = 6.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 1. Vẽ vòng tròn nền mờ
    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, backgroundPaint);

    // 2. Vẽ vòng cung Loading (Gradient)
    final arcPaint = Paint()
      ..shader = SweepGradient(
        colors: [Colors.transparent, Colors.white],
        stops: [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // Bắt đầu từ đỉnh
      1.5 * pi, // Độ dài vòng cung
      false,
      arcPaint,
    );

    // 3. Vẽ chiếc lá ở điểm đầu của vòng cung
    final leafPainter = TextPainter(
      text: TextSpan(text: ' ', style: TextStyle(fontSize: 24)),
      textDirection: TextDirection.ltr,
    );
    leafPainter.layout();

    // Tính toán vị trí để "con mèo" (chiếc lá) luôn nằm ở đầu vòng xoay
    final angle = -pi / 2 + (1.5 * pi); // Vị trí kết thúc của vòng cung
    final leafOffset = Offset(
      center.dx + radius * cos(angle) - (leafPainter.width / 2),
      center.dy + radius * sin(angle) - (leafPainter.height / 2),
    );

    leafPainter.paint(canvas, leafOffset);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
