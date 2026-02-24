import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// Import service để lấy dữ liệu thật
import '../../core/services/api_service.dart';

import '../scan/qrcode_user.dart';
import '../auth/login.dart';
import '../user/partner_list.dart';
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
  String _username = '';
  int _points = 0;
  bool _isLoading = true;

  // Danh sách các đối tác với thông tin chi tiết và đường dẫn ảnh
  final List<Map<String, dynamic>> _partners = [
    {
      'id': 1,
      'name': 'May Cha',
      'category': 'Trà sữa',
      'image': 'assets/images/partners/1.png',
      'color': Color(0xFF4CAF50),
      'gradient': [Color(0xFF4CAF50), Color(0xFF2E7D32)],
      'address': 'May Cha Tea & Milk Tea',
      'searchQuery': 'May Cha Trà Sữa',
    },
    {
      'id': 2,
      'name': 'TuTiMi',
      'category': 'Trà sữa',
      'image': 'assets/images/partners/2.png',
      'color': Color(0xFF66BB6A),
      'gradient': [Color(0xFF66BB6A), Color(0xFF388E3C)],
      'address': 'TuTiMi Milk Tea',
      'searchQuery': 'TuTiMi Trà Sữa',
    },
    {
      'id': 3,
      'name': 'Sunday Basic',
      'category': 'Trà sữa/Đồ uống',
      'image': 'assets/images/partners/3.png',
      'color': Color(0xFF81C784),
      'gradient': [Color(0xFF81C784), Color(0xFF43A047)],
      'address': 'Sunday Basic Coffee & Tea',
      'searchQuery': 'Sunday Basic Trà Sữa',
    },
    {
      'id': 4,
      'name': 'Sóng Sánh',
      'category': 'Trà sữa',
      'image': 'assets/images/partners/4.png',
      'color': Color(0xFFA5D6A7),
      'gradient': [Color(0xFFA5D6A7), Color(0xFF66BB6A)],
      'address': 'Sóng Sánh Bubble Tea',
      'searchQuery': 'Sóng Sánh Trà Sữa',
    },
    {
      'id': 5,
      'name': 'Te Amo',
      'category': 'Trà sữa',
      'image': 'assets/images/partners/5.png',
      'color': Color(0xFFC8E6C9),
      'gradient': [Color(0xFFC8E6C9), Color(0xFF81C784)],
      'address': 'Te Amo Tea House',
      'searchQuery': 'Te Amo Trà Sữa',
    },
    {
      'id': 6,
      'name': 'Trà Sữa Boss',
      'category': 'Trà sữa',
      'image': 'assets/images/partners/6.png',
      'color': Color(0xFF388E3C),
      'gradient': [Color(0xFF388E3C), Color(0xFF1B5E20)],
      'address': 'Trà Sữa Boss',
      'searchQuery': 'Trà Sữa Boss',
    },
    {
      'id': 7,
      'name': 'Hồng Trà Ngô Gia',
      'category': 'Trà/Hồng trà',
      'image': 'assets/images/partners/7.png',
      'color': Color(0xFF2E7D32),
      'gradient': [Color(0xFF2E7D32), Color(0xFF1B5E20)],
      'address': 'Hồng Trà Ngô Gia',
      'searchQuery': 'Hồng Trà Ngô Gia',
    },
    {
      'id': 8,
      'name': 'Lục Trà Thăng Hoa',
      'category': 'Trà trái cây',
      'image': 'assets/images/partners/8.png',
      'color': Color(0xFF43A047),
      'gradient': [Color(0xFF43A047), Color(0xFF2E7D32)],
      'address': 'Lục Trà Thăng Hoa',
      'searchQuery': 'Lục Trà Thăng Hoa',
    },
    {
      'id': 9,
      'name': 'Viên Viên',
      'category': 'Trà sữa',
      'image': 'assets/images/partners/9.png',
      'color': Color(0xFF4CAF50),
      'gradient': [Color(0xFF4CAF50), Color(0xFF388E3C)],
      'address': 'Viên Viên Bubble Tea',
      'searchQuery': 'Viên Viên Trà Sữa',
    },
    {
      'id': 10,
      'name': 'TocoToco',
      'category': 'Trà sữa',
      'image': 'assets/images/partners/10.png',
      'color': Color(0xFF66BB6A),
      'gradient': [Color(0xFF66BB6A), Color(0xFF43A047)],
      'address': 'TocoToco Bubble Tea',
      'searchQuery': 'TocoToco Trà Sữa',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// =======================
  /// LOAD USER DATA
  /// =======================
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUsername = prefs.getString('username') ?? '';

      // Lấy thông tin user từ API
      final userInfo = await ApiService.getUserByUsername(currentUsername);

      if (userInfo != null && mounted) {
        setState(() {
          _username = currentUsername;
          _points = userInfo["point"] ?? 0;
          _isLoading = false;
        });
      } else {
        // Fallback: lấy từ shared preferences
        final savedPoints = prefs.getInt('point') ?? 0;
        setState(() {
          _username = currentUsername;
          _points = savedPoints;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Lỗi khi load user data: $e');
      final prefs = await SharedPreferences.getInstance();
      final currentUsername = prefs.getString('username') ?? '';
      final savedPoints = prefs.getInt('point') ?? 0;

      if (mounted) {
        setState(() {
          _username = currentUsername;
          _points = savedPoints;
          _isLoading = false;
        });
      }
    }
  }

  /// 🔥 RELOAD KHI QUAY VỀ HOME
  void _reloadPoint() {
    _loadUserData();
  }

  /// =======================
  /// MỞ GOOGLE MAPS VỚI VỊ TRÍ QUÁN
  /// =======================
  Future<void> _openGoogleMaps(int partnerIndex) async {
    final partner = _partners[partnerIndex];
    final query = Uri.encodeComponent(partner['searchQuery'] as String);
    final url = 'https://www.google.com/maps/search/?api=1&query=$query';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể mở Google Maps'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// =======================
  /// SHOW PARTNER DETAIL DIALOG
  /// =======================
  void _showPartnerDialog(int partnerIndex) {
    final partner = _partners[partnerIndex];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hình ảnh partner với fallback
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  partner['image'] as String,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(Icons.store, size: 48, color: Colors.green),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 16),

            // Tên quán
            Text(
              partner['name'] as String,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
            SizedBox(height: 8),

            // Loại quán
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                partner['category'] as String,
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: 16),

            // Địa chỉ
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    partner['address'] as String,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),

            // Thứ tự
            Row(
              children: [
                Icon(Icons.star, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Text(
                  'Đối tác ${partner['id']} trong hệ thống',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4CAF50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _openGoogleMaps(partnerIndex);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.map, size: 18),
                SizedBox(width: 6),
                Text('Xem trên bản đồ'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF1F8E9),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.green),
              const SizedBox(height: 20),
              Text(
                'Đang tải thông tin...',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
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
                  fit: BoxFit.scaleDown,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  'GreenPoints',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
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
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HELLO SECTION
            Container(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    child: Icon(Icons.person, color: Colors.green),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xin chào,',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '$_username 🌿',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                gradient: LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tổng điểm tích lũy',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_points điểm',
                            style: const TextStyle(
                              fontSize: 36,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(Icons.star, color: Colors.white, size: 32),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: (_points % 100) / 100,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tiếp tục tích điểm để đổi voucher!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            /// =======================
            /// QUICK ACTIONS (QR & VOUCHER)
            /// =======================
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.1),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildShortCut(
                      icon: Icons.qr_code_scanner,
                      label: 'Mã của tôi',
                      gradient: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const QrCodeUser()),
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
                      gradient: [Color(0xFF66BB6A), Color(0xFF388E3C)],
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
            ),
            const SizedBox(height: 24),

            /// =======================
            /// MAIN BUTTONS
            /// =======================
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.1),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Đổi voucher button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.card_giftcard, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            'ĐỔI VOUCHER NGAY',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 12),

                  // Lịch sử điểm button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.green.shade300,
                        width: 2,
                      ),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HistoryPoint(username: _username),
                          ),
                        );
                        _reloadPoint();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, color: Colors.green),
                          SizedBox(width: 10),
                          Text(
                            'XEM LỊCH SỬ ĐIỂM',
                            style: TextStyle(
                              color: Colors.green[800],
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            /// =======================
            /// PARTNER CAROUSEL (ĐÃ CHUYỂN XUỐNG DƯỚI)
            /// =======================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quán đối tác nổi bật',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PartnerList()),
                    );
                    _reloadPoint();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Xem tất cả',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Carousel partners với thiết kế mới - NỀN TRẮNG, BỎ SỐ
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _partners.length,
                itemBuilder: (context, index) {
                  final partner = _partners[index];

                  return GestureDetector(
                    onTap: () => _showPartnerDialog(index),
                    onLongPress: () => _openGoogleMaps(index),
                    child: Container(
                      width: 110,
                      margin: EdgeInsets.only(right: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // Card partner với hình ảnh - NỀN TRẮNG HOÀN TOÀN
                          Container(
                            height: 100,
                            width: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                  spreadRadius: 1,
                                ),
                              ],
                              border: Border.all(
                                color: Colors.green.shade100,
                                width: 1.5,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Center(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    partner['image'] as String,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Icon(
                                          Icons.store,
                                          size: 32,
                                          color: Colors.green.shade400,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 8),

                          // Tên nhà cung cấp - rút gọn và căn giữa
                          Container(
                            width: 110,
                            child: Text(
                              partner['name'] as String,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.green[900],
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Hướng dẫn
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app, size: 14, color: Colors.green),
                  SizedBox(width: 6),
                  Text(
                    'Chạm để xem chi tiết • Giữ để mở bản đồ',
                    style: TextStyle(
                      color: Colors.green[800],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildShortCut({
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: gradient[1].withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 2,
                    offset: Offset(0, 1),
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
