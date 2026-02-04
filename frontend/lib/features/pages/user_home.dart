import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import service để lấy dữ liệu thật
import '../../core/services/api_service.dart';

import '../scan/qrcode_user.dart';
import '../auth/login.dart';
import '../other/partner_list.dart';
import '../other/contact.dart';
import '../user/history_point.dart';
import '../user/voucher_wallet.dart';
import '../user/voucher_change.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  late Future<Map<String, dynamic>?> _userDateFuture;
  String _username = '';

  @override
  void initState() {
    super.initState();
    _userDateFuture = _loadUserData();
  }

  /// =======================
  /// LOAD USER DATA TỪ API (Giống Management)
  /// =======================
  Future<Map<String, dynamic>?> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUsername = prefs.getString('username') ?? '';
    setState(() {
      _username = currentUsername;
    });

    // Lấy danh sách tất cả users từ ApiService giống management.dart
    final users = await ApiService.getUsers();

    // Tìm đúng user đang đăng nhập để lấy point mới nhất
    try {
      return users.firstWhere((u) => u["username"] == currentUsername);
    } catch (e) {
      return null;
    }
  }

  /// 🔥 RELOAD KHI QUAY VỀ HOME
  void _reloadPoint() {
    setState(() {
      _userDateFuture = _loadUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _userDateFuture,
      builder: (context, snapshot) {
        // Lấy điểm từ snapshot giống management.dart
        final userData = snapshot.data;
        final points = userData != null ? (userData["point"] ?? 0) : 0;

        return Scaffold(
          backgroundColor: const Color(0xFFF1F8E9), // Tông xanh lá nhạt
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            titleSpacing: 0,
            title: Row(
              children: [
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ContactPage()),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/icon/app_icon2.png',
                      width: 45,
                      height: 45,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'GreenPoints',
                      style: TextStyle(
                        fontWeight: FontWeight.w900, // Fix lỗi .black
                        color: Colors.green[800],
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.green),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (_) => false,
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HELLO
                Text(
                  'Xin chào,',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                Text(
                  '$_username 🌿',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 16),

                /// =======================
                /// CARD POINT (Nổi bật)
                /// =======================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF66BB6A), Color(0xFF388E3C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ví GreenPoints của bạn',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$points điểm',
                        style: const TextStyle(
                          fontSize: 36,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                /// =======================
                /// QUICK ACTIONS (QR & VOUCHER)
                /// =======================
                Row(
                  children: [
                    Expanded(
                      child: _buildShortCut(
                        icon: Icons.qr_code_scanner,
                        label: 'Mã của tôi',
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const QrCodeUser(),
                            ),
                          );
                          _reloadPoint();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildShortCut(
                        icon: Icons.wallet_giftcard,
                        label: 'Voucher',
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const VoucherWallet(),
                            ),
                          );
                          _reloadPoint();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                /// =======================
                /// PARTNER (CHẠY NGANG - LOGO TỪ ASSET)
                /// =======================
                const Text(
                  'Quán đối tác nổi bật',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: 10,
                    itemBuilder: (context, i) {
                      return Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.green.shade100),
                          image: DecorationImage(
                            image: AssetImage(
                              'assets/images/partners/${i + 1}.png',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PartnerList()),
                      );
                      _reloadPoint();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Bấm vào đây để xem thêm',
                            style: TextStyle(
                              color: Colors.green[800],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                /// =======================
                /// MAIN BUTTONS
                /// =======================
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const VoucherChange(),
                            ),
                          );
                          _reloadPoint();
                        },
                        child: const Text(
                          'ĐỔI VOUCHER',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.green.shade700,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HistoryPoint(),
                            ),
                          );
                          _reloadPoint();
                        },
                        child: Text(
                          'LỊCH SỬ ĐIỂM',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShortCut({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.green[600], size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
