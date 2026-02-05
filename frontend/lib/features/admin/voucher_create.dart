import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateVoucher extends StatefulWidget {
  const CreateVoucher({super.key});

  @override
  State<CreateVoucher> createState() => _CreateVoucherState();
}

class _CreateVoucherState extends State<CreateVoucher> {
  final pointController = TextEditingController();
  final limitController = TextEditingController();

  String selectedPartner = 'May Cha';
  DateTime? expiredDate;

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

  /// =======================
  /// CHỌN NGÀY HẾT HẠN
  /// =======================
  Future<void> pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );

    if (date != null) {
      setState(() {
        expiredDate = date;
      });
    }
  }

  /// =======================
  /// PHÁT HÀNH VOUCHER
  /// =======================
  Future<void> publishVoucher() async {
    final point = int.tryParse(pointController.text) ?? 0;
    final maxPerUser = int.tryParse(limitController.text) ?? 0;

    if (point <= 0 || expiredDate == null || maxPerUser <= 0) {
      showMsg('Vui lòng nhập đủ thông tin');
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận phát hành'),
        content: const Text(
          'Voucher sẽ được gửi cho TẤT CẢ user. Bạn chắc chắn chứ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Phát hành'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final prefs = await SharedPreferences.getInstance();

    final voucher = {
      'partner': selectedPartner,
      'point': point,
      'maxPerUser': maxPerUser, // 🔥 GIỚI HẠN ĐỔI / USER
      'expired': expiredDate!.toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
    };

    final list = prefs.getStringList('voucher_all_users') ?? [];
    list.add(jsonEncode(voucher));

    await prefs.setStringList('voucher_all_users', list);

    showMsg('🎉 Phát hành voucher thành công');
    Navigator.pop(context);
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo Voucher')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// PARTNER
            const Text('Nhà đối tác'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: selectedPartner,
              items: partners
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  selectedPartner = v!;
                });
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),

            const SizedBox(height: 16),

            /// POINT
            const Text('Số điểm cần đổi'),
            const SizedBox(height: 6),
            TextField(
              controller: pointController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Ví dụ: 100',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            /// LIMIT
            const Text('Số lần mỗi user được đổi'),
            const SizedBox(height: 6),
            TextField(
              controller: limitController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Ví dụ: 1 / 2 / 5',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            /// HẾT HẠN
            const Text('Thời hạn voucher'),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(
                expiredDate == null
                    ? 'Chọn ngày hết hạn'
                    : 'Hết hạn: ${expiredDate!.day}/${expiredDate!.month}/${expiredDate!.year}',
              ),
              onPressed: pickDate,
            ),

            const SizedBox(height: 32),

            /// BUTTON PHÁT HÀNH
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: publishVoucher,
                child: const Text(
                  'PHÁT HÀNH VOUCHER',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
