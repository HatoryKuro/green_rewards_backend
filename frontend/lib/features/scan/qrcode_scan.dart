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
  List<Map<String, dynamic>> partners = [];
  bool isLoadingPartners = false;

  @override
  void initState() {
    super.initState();
    _loadPartners();
  }

  Future<void> _loadPartners() async {
    setState(() => isLoadingPartners = true);
    try {
      final response = await ApiService.getPartnerNames();
      setState(() {
        partners = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      // Fallback: dùng danh sách hardcode nếu API fail
      setState(() {
        partners = [
          {'name': 'May Cha'},
          {'name': 'TuTiMi'},
          {'name': 'Sunday Basic'},
          {'name': 'Sóng Sánh'},
          {'name': 'Te Amo'},
          {'name': 'Trà Sữa Boss'},
          {'name': 'Hồng Trà Ngô Gia'},
          {'name': 'Lục Trà Thăng Hoa'},
          {'name': 'Viên Viên'},
          {'name': 'TocoToco'},
        ];
      });
    } finally {
      setState(() => isLoadingPartners = false);
    }
  }

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
      builder: (_) => _AddPointDialog(
        username: username,
        partners: partners,
        isLoadingPartners: isLoadingPartners,
      ),
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
  final List<Map<String, dynamic>> partners;
  final bool isLoadingPartners;

  const _AddPointDialog({
    required this.username,
    required this.partners,
    required this.isLoadingPartners,
  });

  @override
  State<_AddPointDialog> createState() => _AddPointDialogState();
}

class _AddPointDialogState extends State<_AddPointDialog> {
  final billController = TextEditingController();
  final moneyController = TextEditingController();

  String selectedPartner = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Chọn partner đầu tiên trong danh sách
    if (widget.partners.isNotEmpty) {
      selectedPartner = widget.partners[0]['name'] ?? '';
    }
  }

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User: ${widget.username}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Partner Dropdown
            if (widget.isLoadingPartners)
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Đang tải danh sách đối tác...'),
                  SizedBox(height: 8),
                  LinearProgressIndicator(),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Đối tác:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedPartner.isNotEmpty
                            ? selectedPartner
                            : null,
                        isExpanded: true,
                        hint: const Text('Chọn đối tác'),
                        items: widget.partners.map((partner) {
                          return DropdownMenuItem<String>(
                            value: partner['name']?.toString() ?? '',
                            child: Text(partner['name']?.toString() ?? ''),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedPartner = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // Mã Bill
            TextField(
              controller: billController,
              decoration: const InputDecoration(
                labelText: 'Mã Bill *',
                border: OutlineInputBorder(),
                hintText: 'Nhập mã hóa đơn',
              ),
            ),
            const SizedBox(height: 12),

            // Số tiền
            TextField(
              controller: moneyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số tiền (VNĐ) *',
                border: OutlineInputBorder(),
                hintText: 'Ví dụ: 50000',
                suffixText: 'VNĐ',
              ),
              onChanged: (value) {
                // Cập nhật điểm tự động khi nhập tiền
                final money = int.tryParse(value) ?? 0;
                if (money > 0) {
                  final points = calcPoint(money);
                  // Có thể hiển thị điểm dự tính ở đây nếu cần
                }
              },
            ),

            // Hiển thị điểm tính được
            if (moneyController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Text('Điểm sẽ cộng: '),
                    Text(
                      '${calcPoint(int.tryParse(moneyController.text) ?? 0)} điểm',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 4),
            Text(
              'Công thức: 2 điểm / 1000 VNĐ',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            final money = int.tryParse(moneyController.text) ?? 0;

            if (selectedPartner.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vui lòng chọn đối tác')),
              );
              return;
            }

            if (billController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vui lòng nhập mã bill')),
              );
              return;
            }

            if (money <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ')),
              );
              return;
            }

            Navigator.pop(
              context,
              _ScanResult(
                point: calcPoint(money),
                partner: selectedPartner,
                billCode: billController.text.trim(),
              ),
            );
          },
          child: const Text('Xác nhận'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    billController.dispose();
    moneyController.dispose();
    super.dispose();
  }
}
