import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/services/api_service.dart';

class ScanQR extends StatefulWidget {
  const ScanQR({super.key});

  @override
  State<ScanQR> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanQR> {
  bool scanned = false;

  Future<void> handleQR(String raw) async {
    if (scanned) return;
    scanned = true;

    final parts = raw.split('|');
    if (parts.length != 2 || parts[0] != 'USERQR') {
      showMsg('QR không hợp lệ');
      scanned = false;
      return;
    }

    final username = parts[1];

    final result = await showDialog<_ScanResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddPointDialog(username: username),
    );

    if (result == null || result.point <= 0) {
      scanned = false;
      return;
    }

    try {
      /// 🔥 GỌI API THAY VÌ SHAREDPREFERENCES
      final res = await ApiService.addPointByQR(
        username: username,
        partner: result.partner,
        billCode: result.billCode,
        point: result.point,
      );

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.eco, color: Colors.green, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Cộng điểm thành công 🎉',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '+${result.point} điểm cho $username',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                'Tổng điểm: ${res["point"]}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
        ),
      );

      /// 🔙 QUAY VỀ MANAGEMENT → reload
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      showMsg('❌ Lỗi cộng điểm: $e');
      scanned = false;
    }
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text('QR Scan (Admin)'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final value = capture.barcodes.first.rawValue;
              if (value != null) handleQR(value);
            },
          ),
          Container(color: Colors.black.withOpacity(0.45)),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 3),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: const [
                Icon(Icons.eco, color: Colors.greenAccent, size: 42),
                SizedBox(height: 8),
                Text(
                  'Đưa QR vào khung để quét',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// =======================
/// MODEL KẾT QUẢ
/// =======================
class _ScanResult {
  final int point;
  final String partner;
  final String billCode;

  _ScanResult({
    required this.point,
    required this.partner,
    required this.billCode,
  });
}

/// =======================
/// DIALOG NHẬP THÔNG TIN
/// =======================
class _AddPointDialog extends StatefulWidget {
  final String username;

  const _AddPointDialog({required this.username});

  @override
  State<_AddPointDialog> createState() => _AddPointDialogState();
}

class _AddPointDialogState extends State<_AddPointDialog> {
  final billController = TextEditingController();
  final moneyController = TextEditingController();

  String partner = 'May Cha';

  final partners = [
    'May Cha',
    'TuTiMi',
    'Sunday Basic',
    'Sóng Sánh',
    'Te Amo',
    'Trà Sữa Boss',
    'Hồng Trà Ngô Gia',
    'Lục Trà Thăng Hoa',
    'Viên Viên',
    'TocoToco',
  ];

  int calcPoint(int money) => (money ~/ 1000) * 2;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Cộng điểm'),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          children: [
            Text(
              'User: ${widget.username}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: partner,
              items: partners
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() => partner = v!),
              decoration: const InputDecoration(labelText: 'Partner'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: billController,
              decoration: const InputDecoration(
                labelText: 'Mã Bill',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: moneyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số tiền (VNĐ)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            final money = int.tryParse(moneyController.text) ?? 0;
            if (money <= 0 || billController.text.isEmpty) return;

            Navigator.pop(
              context,
              _ScanResult(
                point: calcPoint(money),
                partner: partner,
                billCode: billController.text.trim(),
              ),
            );
          },
          child: const Text('Xác nhận'),
        ),
      ],
    );
  }
}
