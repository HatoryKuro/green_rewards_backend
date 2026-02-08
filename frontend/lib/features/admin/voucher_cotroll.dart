import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/api_service.dart';
import 'voucher_create.dart'; // Import màn hình tạo voucher

class Controllvoucher extends StatefulWidget {
  const Controllvoucher({super.key});

  @override
  State<Controllvoucher> createState() => _ControllvoucherState();
}

class _ControllvoucherState extends State<Controllvoucher> {
  List<dynamic> vouchers = [];
  Map<int, bool> expanded = {};
  bool isLoading = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadVouchers();
  }

  /// =======================
  /// LOAD VOUCHERS FROM API
  /// =======================
  Future<void> loadVouchers() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await ApiService.getAllVouchers();

      setState(() {
        if (response is List) {
          vouchers = response;
          // Initialize expanded map
          for (int i = 0; i < vouchers.length; i++) {
            expanded[i] = false;
          }
        } else {
          vouchers = [];
          errorMessage = 'Định dạng dữ liệu không đúng';
        }
      });
    } catch (e) {
      print('Lỗi khi load vouchers: $e');
      setState(() {
        errorMessage =
            'Không thể tải danh sách voucher. Vui lòng kiểm tra kết nối và thử lại.';
        vouchers = [];
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// =======================
  /// LẤY SĐT USER
  /// =======================
  Future<String> getUserPhone(String username) async {
    try {
      final userInfo = await ApiService.getUserByUsername(username);
      if (userInfo != null) {
        return userInfo['phone']?.toString() ?? 'Chưa có SĐT';
      }
      return 'Chưa có SĐT';
    } catch (e) {
      return 'Không lấy được SĐT';
    }
  }

  /// =======================
  /// TÍNH TOÁN SỐ TIỀN ĐƯỢC GIẢM
  /// =======================
  double _calculateDiscountAmount(int point) {
    // Công thức: 500 điểm = 10.000đ
    if (point > 0) {
      final multiplier = point / 500.0;
      return multiplier * 10000.0;
    }
    return 0.0;
  }

  /// =======================
  /// FORMAT SỐ TIỀN
  /// =======================
  String _formatCurrency(double amount) {
    return amount.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  /// =======================
  /// THU HỒI VOUCHER
  /// =======================
  Future<void> revokeVoucher(
    int index,
    String voucherId,
    String partner,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận thu hồi'),
        content: Text('Bạn có chắc muốn thu hồi voucher "$partner"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Thu hồi'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Gọi API để xóa voucher
      final success = await ApiService.deleteVoucher(voucherId);

      if (success) {
        // Xóa voucher khỏi danh sách
        setState(() {
          vouchers.removeAt(index);
        });

        showMsg('🗑️ Đã thu hồi voucher "$partner"');
      } else {
        showMsg('❌ Thu hồi voucher thất bại');
      }
    } catch (e) {
      showMsg('❌ Lỗi khi thu hồi voucher: ${e.toString()}');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// =======================
  /// LẤY DANH SÁCH USER ĐÃ ĐỔI VOUCHER
  /// =======================
  Future<List<Map<String, dynamic>>> getRedeemUsers(
    Map<String, dynamic> voucher,
  ) async {
    final List<Map<String, dynamic>> result = [];

    try {
      // Lấy tất cả user
      final allUsers = await ApiService.getUsers();

      // Lấy voucherId
      final voucherId = voucher['_id']?.toString() ?? '';

      for (final user in allUsers) {
        final username = user['username']?.toString() ?? '';
        if (username.isEmpty) continue;

        try {
          // Lấy voucher của user
          final userVouchers = await ApiService.getUserVouchers(username);

          // Đếm số lần user đã đổi voucher này
          int count = 0;
          for (final v in userVouchers) {
            final vData = v as Map<String, dynamic>;
            final vId =
                vData['voucher_id']?.toString() ??
                vData['_id']?.toString() ??
                '';
            if (vId == voucherId) {
              count++;
            }
          }

          if (count > 0) {
            final phone = await getUserPhone(username);

            result.add({
              'username': username,
              'phone': phone,
              'count': count,
              'status': count > 0 ? 'Đã đổi' : 'Chưa đổi',
            });
          }
        } catch (e) {
          print('Lỗi khi lấy voucher của user $username: $e');
        }
      }
    } catch (e) {
      print('Lỗi khi lấy danh sách user đổi voucher: $e');
    }

    return result;
  }

  /// =======================
  /// LẤY THỐNG KÊ VOUCHER
  /// =======================
  Future<Map<String, dynamic>> getVoucherStats(String voucherId) async {
    try {
      // Lấy tất cả user
      final allUsers = await ApiService.getUsers();
      int totalRedeems = 0;
      int activeUsers = 0;

      for (final user in allUsers) {
        final username = user['username']?.toString() ?? '';
        if (username.isEmpty) continue;

        try {
          final userVouchers = await ApiService.getUserVouchers(username);

          for (final v in userVouchers) {
            final vData = v as Map<String, dynamic>;
            final vId =
                vData['voucher_id']?.toString() ??
                vData['_id']?.toString() ??
                '';
            if (vId == voucherId) {
              totalRedeems++;
              activeUsers++;
              break;
            }
          }
        } catch (e) {
          continue;
        }
      }

      return {'totalRedeems': totalRedeems, 'activeUsers': activeUsers};
    } catch (e) {
      return {'totalRedeems': 0, 'activeUsers': 0};
    }
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: msg.contains('❌') ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Voucher'),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: loadVouchers),
        ],
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang tải danh sách voucher...'),
                ],
              ),
            )
          : errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: loadVouchers,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            )
          : vouchers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.card_giftcard, color: Colors.grey[400], size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Chưa có voucher nào',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to create voucher page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateVoucher(),
                        ),
                      );
                    },
                    child: const Text('Tạo voucher mới'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: vouchers.length,
              itemBuilder: (context, index) {
                final v = vouchers[index] as Map<String, dynamic>;
                final partner = v['partner']?.toString() ?? 'Unknown';
                final point = v['point'] is int
                    ? v['point']
                    : int.tryParse(v['point']?.toString() ?? '0') ?? 0;
                final maxPerUser = v['maxPerUser'] is int
                    ? v['maxPerUser']
                    : int.tryParse(v['maxPerUser']?.toString() ?? '1') ?? 1;
                final expired = v['expired']?.toString() ?? '';
                final voucherId = v['_id']?.toString() ?? '';
                final createdAt = v['created_at']?.toString() ?? '';

                // Parse dates
                DateTime? expiredDate;
                DateTime? createdDate;

                try {
                  expiredDate = DateTime.parse(expired);
                } catch (e) {
                  expiredDate = null;
                }

                try {
                  if (createdAt.isNotEmpty) {
                    createdDate = DateTime.parse(createdAt);
                  }
                } catch (e) {
                  createdDate = null;
                }

                final isExpired =
                    expiredDate != null && expiredDate.isBefore(DateTime.now());
                final daysLeft = expiredDate != null
                    ? expiredDate.difference(DateTime.now()).inDays
                    : 0;

                // Tính số tiền được giảm
                final discountAmount = _calculateDiscountAmount(point);

                expanded[index] ??= false;

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// HEADER
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    partner,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                expanded[index]!
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: Colors.green[700],
                              ),
                              onPressed: () {
                                setState(() {
                                  expanded[index] = !expanded[index]!;
                                });
                              },
                            ),
                          ],
                        ),

                        /// VOUCHER INFO
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green.shade100),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.monetization_on,
                                color: Colors.green[700],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Giảm ${_formatCurrency(discountAmount)}đ',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    Text(
                                      '($point điểm)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        /// VOUCHER DETAILS
                        Row(
                          children: [
                            Icon(
                              Icons.repeat,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Giới hạn: $maxPerUser lần/user',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: isExpired ? Colors.red : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                isExpired
                                    ? 'Đã hết hạn'
                                    : 'Hết hạn: ${expiredDate?.day}/${expiredDate?.month}/${expiredDate?.year} (Còn $daysLeft ngày)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isExpired
                                      ? Colors.red
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (createdDate != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.date_range,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Tạo ngày: ${createdDate.day}/${createdDate.month}/${createdDate.year}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],

                        /// EXPANDED CONTENT - USER LIST
                        if (expanded[index]!)
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: getRedeemUsers(v),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return Container(
                                  margin: const EdgeInsets.only(top: 16),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Chưa có user nào đổi voucher này',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                );
                              }

                              final users = snapshot.data!;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Danh sách user đã đổi:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Thống kê
                                  FutureBuilder<Map<String, dynamic>>(
                                    future: getVoucherStats(voucherId),
                                    builder: (context, statsSnapshot) {
                                      if (statsSnapshot.hasData) {
                                        final stats = statsSnapshot.data!;
                                        return Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            children: [
                                              Column(
                                                children: [
                                                  Text(
                                                    '${stats['activeUsers']}',
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.blue,
                                                    ),
                                                  ),
                                                  const Text(
                                                    'User',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Column(
                                                children: [
                                                  Text(
                                                    '${stats['totalRedeems']}',
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                  const Text(
                                                    'Lượt đổi',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                      return const SizedBox();
                                    },
                                  ),

                                  const SizedBox(height: 12),
                                  ...users.map((user) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  user['username'],
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  '📞 ${user['phone']}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '${user['count']} lần',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                              );
                            },
                          ),

                        const SizedBox(height: 16),

                        /// ACTION BUTTONS - CHỈ CÒN NÚT THU HỒI
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.delete, size: 18),
                            label: const Text('Thu hồi voucher'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[50],
                              foregroundColor: Colors.red[700],
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () =>
                                revokeVoucher(index, voucherId, partner),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[700],
        onPressed: () {
          // Navigate to create voucher page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateVoucher()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
