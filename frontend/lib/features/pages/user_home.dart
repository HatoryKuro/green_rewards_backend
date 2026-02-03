import 'package:flutter/material.dart';
import 'package:green_rewards/features/user/voucher_change.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../scan/qrcode_user.dart';
import '../auth/login.dart';
import '../other/partner_list.dart';
import '../other/contact.dart';
import '../user/history_point.dart';
import '../scan/qrcode_scan.dart';
import '../user/voucher_wallet.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  late Future<int> _pointFuture;
  String _username = '';

  /// =======================
  /// LOAD USER + POINT
  /// =======================
  Future<int> _loadPoint() async {
    final prefs = await SharedPreferences.getInstance();

    final username = prefs.getString('username');
    if (username == null) return 0;

    _username = username;
    return prefs.getInt('point_$username') ?? 0;
  }

  @override
  void initState() {
    super.initState();
    _pointFuture = _loadPoint();
  }

  /// 🔥 RELOAD KHI QUAY VỀ HOME
  void _reloadPoint() {
    setState(() {
      _pointFuture = _loadPoint();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _pointFuture,
      builder: (context, snapshot) {
        final points = snapshot.data ?? 0;

        return Scaffold(
          appBar: AppBar(
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
                    borderRadius: BorderRadius.circular(6),
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
                    child: const Text(
                      'GreenPoints',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 28,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 48),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (_) => false,
                  );
                },
              ),
            ],
          ),

          /// =======================
          /// BODY
          /// =======================
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HELLO
                Text(
                  'Xin chào, $_username',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 16),

                /// =======================
                /// CARD POINT
                /// =======================
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ví GreenPoints',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$points điểm',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                /// =======================
                /// QR USER
                /// =======================
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.qr_code, color: Colors.green),
                    title: const Text('QR Code của tôi'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => QrCodeUser()),
                      );
                      _reloadPoint();
                    },
                  ),
                ),

                const SizedBox(height: 12),

                /// =======================
                /// VOUCHER
                /// =======================
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.card_giftcard,
                      color: Colors.green,
                    ),
                    title: const Text('Voucher của tôi'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => VoucherWallet()),
                      );
                      _reloadPoint();
                    },
                  ),
                ),

                const SizedBox(height: 16),

                /// =======================
                /// PARTNER
                /// =======================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Quán đối tác nổi bật',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => PartnerList()),
                        );
                        _reloadPoint();
                      },
                      child: const Text('Xem tất cả'),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                /// =======================
                /// BUTTONS
                /// =======================
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => VoucherChange()),
                          );
                          _reloadPoint();
                        },
                        child: const Text('Đổi voucher'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => HistoryPoint()),
                          );
                          _reloadPoint();
                        },
                        child: const Text('Lịch sử điểm'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
