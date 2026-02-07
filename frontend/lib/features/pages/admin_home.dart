import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:green_rewards/features/admin/partner_create.dart';
import 'package:green_rewards/features/other/partner_list.dart';
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

  @override
  Widget build(BuildContext context) {
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
                        color: Colors.green.shade700,
                      ),
                    ),
                    Text(
                      '(${currentRole.toUpperCase()})',
                      style: TextStyle(
                        fontSize: 12,
                        color: isAdmin ? Colors.red : Colors.blue,
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

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8F5E9), Color(0xFFF1F8E9)],
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
                  children: [
                    _adminActionButton(
                      icon: Icons.qr_code_scanner,
                      label: 'Quét mã QR',
                      color: Colors.green,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ScanQR()),
                        );
                      },
                    ),
                    _adminActionButton(
                      icon: Icons.qr_code,
                      label: 'Tạo Voucher',
                      color: Colors.teal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateVoucher(),
                          ),
                        );
                      },
                    ),
                    _adminActionButton(
                      icon: Icons.people,
                      label: 'Quản lý User',
                      color: isAdmin ? Colors.lightGreen : Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const Management()),
                        );
                      },
                    ),
                    _adminActionButton(
                      icon: Icons.confirmation_num,
                      label: 'Quản lý Voucher',
                      color: Colors.green,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ControllVoucher(),
                          ),
                        );
                      },
                    ),
                    _adminActionButton(
                      icon: Icons.store_mall_directory,
                      label: 'Quản lý Partners',
                      color: Colors.green,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PartnerList(),
                          ),
                        );
                      },
                    ),
                    // Thêm nút tạo partner nếu cần
                    if (isAdmin)
                      _adminActionButton(
                        icon: Icons.add_business,
                        label: 'Tạo Partner',
                        color: Colors.orange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PartnerCreate(),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isAdmin ? Icons.admin_panel_settings : Icons.supervisor_account,
            size: 48,
            color: isAdmin ? Colors.red : Colors.blue,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAdmin ? 'Chào mừng Admin 🌱' : 'Chào mừng Manager 🌱',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isAdmin
                      ? 'Quản lý toàn bộ hệ thống'
                      : 'Quản lý người dùng và voucher',
                  style: const TextStyle(color: Colors.grey),
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
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.85), color.withOpacity(0.65)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 42, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
