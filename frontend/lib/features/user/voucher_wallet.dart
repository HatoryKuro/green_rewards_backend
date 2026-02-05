import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VoucherWallet extends StatefulWidget {
  const VoucherWallet({super.key});

  @override
  State<VoucherWallet> createState() => _VoucherWalletState();
}

class _VoucherWalletState extends State<VoucherWallet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<String?> _usernameFuture;

  List<Map<String, dynamic>> usable = [];
  List<Map<String, dynamic>> expiredOrUsed = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Lấy username từ SharedPreferences ngay khi init
    _usernameFuture = _getUsernameFromPrefs();
    _loadVouchers();
  }

  Future<String?> _getUsernameFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_username');
  }

  Future<void> _loadVouchers() async {
    final username = await _usernameFuture;
    if (username == null) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'my_vouchers_$username';
    final raw = prefs.getStringList(key) ?? [];

    final now = DateTime.now();

    usable.clear();
    expiredOrUsed.clear();

    for (final e in raw) {
      final v = jsonDecode(e) as Map<String, dynamic>;
      final expired = DateTime.parse(v['expired']);
      final used = v['used'] == true;

      if (!used && expired.isAfter(now)) {
        usable.add(v);
      } else {
        expiredOrUsed.add(v);
      }
    }

    if (mounted) setState(() {});
  }

  /// =======================
  /// HIỆN QR + XÁC NHẬN ĐÃ DÙNG
  /// =======================
  Future<void> _useVoucher(Map<String, dynamic> voucher) async {
    final username = await _usernameFuture;
    if (username == null) return;

    final qrData =
        'VOUCHER|${voucher['partner']}|${voucher['point']}|${voucher['expired']}';

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'QUÉT VOUCHER',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 16),
                  QrImageView(data: qrData, size: 220),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Đã quét xong'),
                  ),
                ],
              ),
            ),

            /// ❌ nút đóng
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context, false),
              ),
            ),
          ],
        ),
      ),
    );

    /// nếu chưa quét → không làm gì
    if (confirmed != true) return;

    /// ĐÁNH DẤU ĐÃ DÙNG
    final prefs = await SharedPreferences.getInstance();
    final key = 'my_vouchers_$username';
    final raw = prefs.getStringList(key) ?? [];

    final updated = raw.map((e) {
      final v = jsonDecode(e) as Map<String, dynamic>;
      if (v['partner'] == voucher['partner'] &&
          v['expired'] == voucher['expired']) {
        v['used'] = true;
      }
      return jsonEncode(v);
    }).toList();

    await prefs.setStringList(key, updated);
    _loadVouchers();
  }

  /// =======================
  /// CARD VOUCHER
  /// =======================
  Widget _buildVoucherCard(Map<String, dynamic> v, {bool disabled = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: disabled ? Colors.grey.shade300 : Colors.green,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            v['partner'],
            style: TextStyle(
              color: disabled ? Colors.black54 : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${v['point']} POINT',
            style: TextStyle(
              color: disabled ? Colors.black54 : Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'HSD: ${DateTime.parse(v['expired']).day}/'
            '${DateTime.parse(v['expired']).month}/'
            '${DateTime.parse(v['expired']).year}',
            style: TextStyle(color: disabled ? Colors.black45 : Colors.white70),
          ),
          const SizedBox(height: 12),
          if (!disabled)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green,
                ),
                onPressed: () => _useVoucher(v),
                child: const Text(
                  'DÙNG NGAY',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            )
          else
            const Text(
              'Đã sử dụng / Hết hạn',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _usernameFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Ví Voucher')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Ví Voucher')),
            body: Center(
              child: Text(
                'Không tìm thấy thông tin người dùng',
                style: TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Ví Voucher'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'SỬ DỤNG'),
                Tab(text: 'HẾT HẠN'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              /// TAB SỬ DỤNG
              usable.isEmpty
                  ? const Center(child: Text('Không có voucher khả dụng'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: usable
                          .map((v) => _buildVoucherCard(v))
                          .toList(),
                    ),

              /// TAB HẾT HẠN / ĐÃ DÙNG
              expiredOrUsed.isEmpty
                  ? const Center(child: Text('Chưa có dữ liệu'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: expiredOrUsed
                          .map((v) => _buildVoucherCard(v, disabled: true))
                          .toList(),
                    ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
