import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:green_rewards/features/admin/partner_create.dart';
import 'package:green_rewards/features/user/partner_list.dart';
import 'package:green_rewards/core/services/user_preferences.dart';
import '../auth/login.dart';
import '../../features/admin/voucher_create.dart';
import '../admin/management.dart';
import '../scan/qrcode_scan.dart';
import '../other/contact.dart';
import '../admin/voucher_cotroll.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  String currentRole = 'admin';
  bool isAdmin = true;
  bool isManager = false;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final role = await UserPreferences.getRole();
      final isAdminValue = await UserPreferences.isAdmin();
      setState(() {
        currentRole = role;
        isAdmin = isAdminValue;
        isManager = role == 'manager';
      });
    } catch (e) {
      print('Lỗi khi load role: $e');
    }
  }

  // Màu gradient cho admin (tông cam)
  final List<Color> adminGradientColors = [
    Color(0xFFFF8A00), // Cam sáng
    Color(0xFFFF6B35), // Cam đậm
    Color(0xFFFF5252), // Cam đỏ
  ];

  // Màu gradient cho manager (tông xanh dương)
  final List<Color> managerGradientColors = [
    Color(0xFF2196F3), // Xanh dương sáng
    Color(0xFF1976D2), // Xanh dương trung
    Color(0xFF0D47A1), // Xanh dương đậm
  ];

  // Danh sách các button cho admin
  final List<Map<String, dynamic>> adminButtons = [
    {
      'icon': Icons.qr_code_scanner,
      'label': 'Quét mã QR',
      'gradient': [Color(0xFFFF9800), Color(0xFFFF5722)],
    },
    {
      'icon': Icons.qr_code,
      'label': 'Tạo Voucher',
      'gradient': [Color(0xFFFFB74D), Color(0xFFFF7043)],
    },
    {
      'icon': Icons.people,
      'label': 'Quản lý User',
      'gradient': [Color(0xFFFFA726), Color(0xFFF57C00)],
    },
    {
      'icon': Icons.confirmation_num,
      'label': 'Quản lý Voucher',
      'gradient': [Color(0xFFFFCC80), Color(0xFFFF8A65)],
    },
    {
      'icon': Icons.store_mall_directory,
      'label': 'Quản lý Partners',
      'gradient': [Color(0xFFFFD180), Color(0xFFFF6E40)],
    },
    {
      'icon': Icons.add_business,
      'label': 'Tạo Partner',
      'gradient': [Color(0xFFFFE0B2), Color(0xFFFF5252)],
    },
  ];

  // Danh sách các button cho manager
  final List<Map<String, dynamic>> managerButtons = [
    {
      'icon': Icons.qr_code_scanner,
      'label': 'Quét mã QR',
      'gradient': [Color(0xFF64B5F6), Color(0xFF1976D2)],
    },
    {
      'icon': Icons.qr_code,
      'label': 'Tạo Voucher',
      'gradient': [Color(0xFF90CAF9), Color(0xFF1565C0)],
    },
    {
      'icon': Icons.people,
      'label': 'Quản lý User',
      'gradient': [Color(0xFF42A5F5), Color(0xFF0D47A1)],
    },
    {
      'icon': Icons.confirmation_num,
      'label': 'Quản lý Voucher',
      'gradient': [Color(0xFF29B6F6), Color(0xFF0277BD)],
    },
    {
      'icon': Icons.store_mall_directory,
      'label': 'Quản lý Partners',
      'gradient': [Color(0xFF26C6DA), Color(0xFF006064)],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final currentButtons = isAdmin ? adminButtons : managerButtons;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 12),

            /// LOGO → CONTACT
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ContactPage()),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/icon/app_icon2.png',
                  width: 42,
                  height: 42,
                  fit: BoxFit.scaleDown,
                ),
              ),
            ),

            /// TITLE
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isAdmin ? 'Admin Dashboard' : 'Manager Dashboard',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: isAdmin ? Color(0xFFFF6B35) : Color(0xFF1976D2),
                      ),
                    ),
                    Text(
                      '(${currentRole.toUpperCase()})',
                      style: TextStyle(
                        fontSize: 12,
                        color: isAdmin ? Color(0xFFFF5252) : Color(0xFF0D47A1),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 48),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            icon: Icon(
              Icons.logout,
              color: isAdmin ? Color(0xFFFF6B35) : Color(0xFF1976D2),
            ),
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

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isAdmin
                ? [Color(0xFFFFF3E0), Color(0xFFFFECB3)]
                : [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _headerCard(),
              const SizedBox(height: 24),

              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1,
                  children: currentButtons.map((button) {
                    return _adminActionButton(
                      icon: button['icon'] as IconData,
                      label: button['label'] as String,
                      gradient: (button['gradient'] as List<Color>),
                      onTap: () {
                        _handleButtonTap(button['label'] as String);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleButtonTap(String label) {
    switch (label) {
      case 'Quét mã QR':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ScanQR()),
        );
        break;
      case 'Tạo Voucher':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateVoucher()),
        );
        break;
      case 'Quản lý User':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const Management()),
        );
        break;
      case 'Quản lý Voucher':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const Controllvoucher()),
        );
        break;
      case 'Quản lý Partners':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PartnerList()),
        );
        break;
      case 'Tạo Partner':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PartnerCreate()),
        );
        break;
    }
  }

  Widget _headerCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isAdmin ? Color(0xFFFF6B35) : Color(0xFF1976D2))
                .withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: (isAdmin ? Color(0xFFFF6B35) : Color(0xFF1976D2)).withOpacity(
            0.2,
          ),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isAdmin
                    ? [Color(0xFFFF8A00), Color(0xFFFF5252)]
                    : [Color(0xFF2196F3), Color(0xFF0D47A1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isAdmin ? Icons.admin_panel_settings : Icons.supervisor_account,
              size: 30,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAdmin ? 'Chào mừng Admin 🚀' : 'Chào mừng Manager ⚡',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isAdmin ? Color(0xFFFF6B35) : Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isAdmin
                      ? 'Toàn quyền quản lý hệ thống'
                      : 'Quản lý người dùng và voucher',
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _adminActionButton({
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient[1].withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: gradient[0].withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon với background tròn
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 2,
                  ),
                ),
                child: Icon(icon, size: 32, color: Colors.white),
              ),
              const SizedBox(height: 12),

              // Text label
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.3,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
