import 'package:flutter/material.dart';
import 'core/theme/theme_load.dart'; // 👈 thêm splash screen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QR Discount',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.grey[100],
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      // 👇 chỉ đổi dòng này
      home: const ThemeLoadPage(),
    );
  }
}
