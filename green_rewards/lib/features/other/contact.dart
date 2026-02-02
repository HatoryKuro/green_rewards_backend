import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  void showDonateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
        title: Row(
          children: [
            const Expanded(
              child: Text(
                'Ủng hộ phát triển App',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icon/app_icon2.png', width: 120, height: 120),
            const SizedBox(height: 12),
            const Text(
              'Chuyển khoản MoMo',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              '0377 765 300',
              style: TextStyle(fontSize: 18, color: Colors.green),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Sao chép số'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                Clipboard.setData(const ClipboardData(text: '0377765300'));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã sao chép số MoMo')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Liên hệ & Ủng hộ')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),

            /// LOGO
            Image.asset('assets/icon/app_icon2.png', width: 120, height: 120),

            const SizedBox(height: 16),

            /// APP NAME
            const Text(
              'QR Discount App',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 28),

            /// DESCRIPTION (CĂN TRÁI NHƯNG NẰM GIỮA MÀN)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: const Text(
                '• Ứng dụng quản lý voucher & điểm thưởng\n'
                '• Hỗ trợ QR Code nhanh chóng\n'
                '• Dành cho Admin & Partner\n'
                '• Giao diện đơn giản, dễ dùng\n'
                '• Cảm ơn bạn đã sử dụng app ❤️',
                style: TextStyle(height: 1.6),
                textAlign: TextAlign.center,
              ),
            ),

            const Spacer(),

            /// DONATION BUTTON
            ElevatedButton.icon(
              icon: const Icon(Icons.favorite, size: 18),
              label: const Text(
                'Donation qua MoMo',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: () => showDonateDialog(context),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
