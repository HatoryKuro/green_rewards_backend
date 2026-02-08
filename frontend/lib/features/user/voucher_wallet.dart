import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/api_service.dart';

class VoucherWallet extends StatefulWidget {
  const VoucherWallet({super.key});

  @override
  State<VoucherWallet> createState() => _VoucherWalletState();
}

class _VoucherWalletState extends State<VoucherWallet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String currentUsername = '';
  int userPoints = 0;

  List<dynamic> myVouchers = []; // Tất cả voucher đã đổi
  List<dynamic> expiredVouchers = []; // Tất cả voucher không thể sử dụng

  bool isLoadingUser = true;
  bool isLoadingVouchers = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();
  }

  /// =======================
  /// KHỞI TẠO DỮ LIỆU BAN ĐẦU
  /// =======================
  Future<void> _loadInitialData() async {
    await _loadUserData();
    if (mounted && currentUsername.isNotEmpty) {
      await _loadAllVoucherData();
    } else if (mounted) {
      setState(() {
        errorMessage = 'Không tìm thấy thông tin người dùng';
        isLoadingUser = false;
      });
    }
  }

  /// =======================
  /// LOAD USER DATA
  /// =======================
  Future<void> _loadUserData() async {
    setState(() {
      isLoadingUser = true;
      errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username') ?? '';
      final points = prefs.getInt('point') ?? 0;

      if (mounted) {
        setState(() {
          currentUsername = username;
          userPoints = points;
          isLoadingUser = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Lỗi khi tải thông tin người dùng';
          isLoadingUser = false;
        });
      }
    }
  }

  /// =======================
  /// LOAD ALL VOUCHER DATA
  /// =======================
  Future<void> _loadAllVoucherData() async {
    if (currentUsername.isEmpty) {
      setState(() {
        errorMessage = 'Không tìm thấy thông tin người dùng';
        isLoadingVouchers = false;
      });
      return;
    }

    setState(() {
      isLoadingVouchers = true;
      errorMessage = '';
      myVouchers = [];
      expiredVouchers = [];
    });

    try {
      // Load available vouchers từ API
      final availableResponse = await ApiService.getAvailableVouchers();

      // Load user's vouchers (đã đổi)
      final userVouchersResponse = await ApiService.getUserVouchers(
        currentUsername,
      );

      final now = DateTime.now();

      // Tạo map để tra cứu nhanh thông tin voucher gốc
      final Map<String, dynamic> availableVoucherMap = {};
      for (final voucher in availableResponse) {
        final voucherData = voucher as Map<String, dynamic>;
        final id = voucherData['_id']?.toString() ?? '';
        if (id.isNotEmpty) {
          availableVoucherMap[id] = voucherData;
        }
      }

      // Phân loại voucher
      for (final userVoucher in userVouchersResponse) {
        final voucherData = userVoucher as Map<String, dynamic>;
        final voucherId = voucherData['voucher_id']?.toString() ?? '';
        final status = voucherData['status']?.toString() ?? 'usable';

        // Lấy thông tin voucher gốc
        final originalVoucher = availableVoucherMap[voucherId];
        if (originalVoucher != null) {
          final expired = originalVoucher['expired']?.toString() ?? '';
          final maxPerUser = originalVoucher['maxPerUser'] is int
              ? originalVoucher['maxPerUser']
              : int.tryParse(
                      originalVoucher['maxPerUser']?.toString() ?? '1',
                    ) ??
                    1;

          // Parse expired date
          DateTime? expiredDate;
          try {
            expiredDate = DateTime.parse(expired);
          } catch (e) {
            expiredDate = null;
          }

          final isExpired = expiredDate != null && expiredDate.isBefore(now);

          // Đếm số lần user đã đổi voucher này (chưa sử dụng)
          final userExchangedCount = userVouchersResponse.where((v) {
            final vData = v as Map<String, dynamic>;
            final vId = vData['voucher_id']?.toString() ?? '';
            return vId == voucherId && vData['status']?.toString() != 'used';
          }).length;

          final reachedLimit = userExchangedCount >= maxPerUser;

          // Xác định lý do không thể sử dụng
          String? reason;
          if (status == 'used') {
            reason = 'Đã sử dụng';
          } else if (isExpired) {
            reason = 'Hết hạn';
          } else if (reachedLimit) {
            reason = 'Đã đạt giới hạn';
          }

          // Thêm vào danh sách phù hợp
          final voucherWithInfo = {
            ...voucherData,
            'original_voucher': originalVoucher,
            'reason': reason,
            'isExpired': isExpired,
            'reachedLimit': reachedLimit,
          };

          if (reason != null) {
            expiredVouchers.add(voucherWithInfo);
          } else {
            myVouchers.add(voucherWithInfo);
          }
        } else {
          // Nếu không tìm thấy voucher gốc, coi như không thể sử dụng
          expiredVouchers.add({
            ...voucherData,
            'reason': 'Voucher không tồn tại',
          });
        }
      }

      // Sắp xếp: voucher chưa sử dụng lên đầu
      myVouchers.sort((a, b) {
        final statusA = a['status']?.toString() ?? 'usable';
        final statusB = b['status']?.toString() ?? 'usable';
        if (statusA == 'used' && statusB != 'used') return 1;
        if (statusA != 'used' && statusB == 'used') return -1;
        return 0;
      });

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Lỗi khi load voucher data: $e');
      if (mounted) {
        setState(() {
          errorMessage =
              'Không thể tải dữ liệu voucher. Vui lòng kiểm tra kết nối và thử lại.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingVouchers = false;
        });
      }
    }
  }

  /// =======================
  /// TÍNH TOÁN SỐ TIỀN ĐƯỢC GIẢM
  /// =======================
  double _calculateDiscountAmount(int point) {
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
  /// MARK VOUCHER AS USED
  /// =======================
  Future<void> _useVoucher(
    String voucherId,
    Map<String, dynamic> voucher,
  ) async {
    final originalVoucher = voucher['original_voucher'] ?? {};
    final partner = originalVoucher['partner']?.toString() ?? 'Unknown';
    final point = originalVoucher['point'] is int
        ? originalVoucher['point']
        : int.tryParse(originalVoucher['point']?.toString() ?? '0') ?? 0;

    // Show QR dialog
    final qrData =
        'VOUCHER|$currentUsername|$point|$partner|${DateTime.now().toIso8601String()}';

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
                  Text(
                    partner,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_formatCurrency(_calculateDiscountAmount(point))}đ',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '($point điểm)',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  QrImageView(
                    data: qrData,
                    size: 220,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Đã quét xong'),
                  ),
                ],
              ),
            ),
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

    if (confirmed != true) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang xác nhận sử dụng voucher...'),
          ],
        ),
      ),
    );

    try {
      // Call API to mark voucher as used
      final success = await ApiService.markVoucherUsed(voucherId);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (success) {
        // Show success message
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('🎉 Thành công!'),
            content: Text('Voucher $partner đã được đánh dấu là đã sử dụng.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Reload vouchers
                  _loadAllVoucherData();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        _showError('Không thể đánh dấu voucher đã sử dụng');
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      _showError('Lỗi khi sử dụng voucher: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// =======================
  /// BUILD VOUCHER CARD FOR MY VOUCHERS
  /// =======================
  Widget _buildMyVoucherCard(Map<String, dynamic> voucher) {
    final originalVoucher = voucher['original_voucher'] ?? {};
    final partner = originalVoucher['partner']?.toString() ?? 'Unknown';
    final point = originalVoucher['point'] is int
        ? originalVoucher['point']
        : int.tryParse(originalVoucher['point']?.toString() ?? '0') ?? 0;
    final status = voucher['status']?.toString() ?? 'usable';
    final exchangedAt = voucher['exchanged_at']?.toString() ?? '';
    final usedAt = voucher['used_at']?.toString();
    final voucherId = voucher['_id']?.toString() ?? '';

    // Tính số tiền được giảm
    final discountAmount = _calculateDiscountAmount(point);

    // Parse dates
    DateTime? exchangedDate;
    DateTime? usedDate;

    try {
      exchangedDate = DateTime.parse(exchangedAt);
    } catch (e) {
      exchangedDate = null;
    }

    if (usedAt != null && usedAt.isNotEmpty && usedAt != 'null') {
      try {
        usedDate = DateTime.parse(usedAt);
      } catch (e) {
        usedDate = null;
      }
    }

    final isUsed = status == 'used';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    partner,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isUsed ? Colors.grey : Colors.green,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isUsed
                        ? Colors.grey.shade200
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$point điểm',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isUsed ? Colors.grey : Colors.green,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Hiển thị số tiền được giảm
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUsed ? Colors.grey.shade100 : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isUsed ? Colors.grey.shade300 : Colors.amber.shade200,
                  width: 2,
                ),
              ),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      'GIẢM NGAY',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isUsed ? Colors.grey : Colors.amber[800],
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatCurrency(discountAmount)}đ',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isUsed ? Colors.grey : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            if (exchangedDate != null)
              Row(
                children: [
                  Icon(Icons.date_range, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Đổi ngày: ${exchangedDate.day}/${exchangedDate.month}/${exchangedDate.year}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),

            if (usedDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'Đã sử dụng: ${usedDate.day}/${usedDate.month}/${usedDate.year}',
                      style: const TextStyle(fontSize: 12, color: Colors.green),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: !isUsed
                  ? ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => _useVoucher(voucherId, voucher),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'SỬ DỤNG VOUCHER',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'ĐÃ SỬ DỤNG',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// =======================
  /// BUILD EXPIRED VOUCHER CARD
  /// =======================
  Widget _buildExpiredVoucherCard(Map<String, dynamic> voucher) {
    final originalVoucher = voucher['original_voucher'] ?? {};
    final partner = originalVoucher['partner']?.toString() ?? 'Unknown';
    final point = originalVoucher['point'] is int
        ? originalVoucher['point']
        : int.tryParse(originalVoucher['point']?.toString() ?? '0') ?? 0;
    final status = voucher['status']?.toString() ?? 'usable';
    final reason = voucher['reason']?.toString() ?? 'Không thể sử dụng';
    final exchangedAt = voucher['exchanged_at']?.toString() ?? '';
    final usedAt = voucher['used_at']?.toString();

    // Parse dates
    DateTime? exchangedDate;
    DateTime? usedDate;

    try {
      exchangedDate = DateTime.parse(exchangedAt);
    } catch (e) {
      exchangedDate = null;
    }

    if (usedAt != null && usedAt.isNotEmpty && usedAt != 'null') {
      try {
        usedDate = DateTime.parse(usedAt);
      } catch (e) {
        usedDate = null;
      }
    }

    final isUsed = status == 'used';

    // Tính số tiền được giảm
    final discountAmount = _calculateDiscountAmount(point);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    partner,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$point điểm',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Hiển thị số tiền được giảm
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      'GIẢM NGAY',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatCurrency(discountAmount)}đ',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Hiển thị lý do
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isUsed ? Icons.check_circle : Icons.warning,
                    size: 16,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reason,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            if (exchangedDate != null)
              Row(
                children: [
                  Icon(Icons.date_range, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Đổi ngày: ${exchangedDate.day}/${exchangedDate.month}/${exchangedDate.year}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),

            if (usedDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'Đã sử dụng: ${usedDate.day}/${usedDate.month}/${usedDate.year}',
                      style: const TextStyle(fontSize: 12, color: Colors.green),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'KHÔNG THỂ SỬ DỤNG',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingUser) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ví Voucher'),
          backgroundColor: Colors.green[700],
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang tải thông tin người dùng...'),
            ],
          ),
        ),
      );
    }

    if (currentUsername.isEmpty && errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ví Voucher'),
          backgroundColor: Colors.green[700],
        ),
        body: Center(
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
                onPressed: _loadInitialData,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ví Voucher'),
        backgroundColor: Colors.green[700],
        actions: [
          if (currentUsername.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Row(
                  children: [
                    Icon(Icons.star, color: Colors.yellow[700], size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '$userPoints',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.wallet), text: 'VOUCHER CỦA TÔI'),
            Tab(icon: Icon(Icons.timer_off), text: 'HẾT HẠN'),
          ],
        ),
      ),
      body: isLoadingVouchers
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang tải dữ liệu voucher...'),
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
                    onPressed: _loadAllVoucherData,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Voucher của tôi (còn hiệu lực)
                RefreshIndicator(
                  onRefresh: _loadAllVoucherData,
                  child: myVouchers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.wallet,
                                color: Colors.grey[400],
                                size: 64,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Bạn chưa có voucher nào',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Hãy đổi voucher để tích lũy ưu đãi',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: myVouchers.length,
                          itemBuilder: (context, index) {
                            final voucher =
                                myVouchers[index] as Map<String, dynamic>;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildMyVoucherCard(voucher),
                            );
                          },
                        ),
                ),

                // Tab 2: Hết hạn/Đã sử dụng/Đạt giới hạn
                RefreshIndicator(
                  onRefresh: _loadAllVoucherData,
                  child: expiredVouchers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.timer_off,
                                color: Colors.grey[400],
                                size: 64,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Không có voucher không thể sử dụng',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Tất cả voucher đều còn hiệu lực',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: expiredVouchers.length,
                          itemBuilder: (context, index) {
                            final voucher =
                                expiredVouchers[index] as Map<String, dynamic>;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildExpiredVoucherCard(voucher),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
