import 'package:flutter/material.dart';
import '../scan/qrcode_user.dart';

class VoucherChange extends StatelessWidget {
  const VoucherChange({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("USER HOME", style: TextStyle(fontSize: 24)),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code),
              label: const Text("Tạo Voucher"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QrCodeUser()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
