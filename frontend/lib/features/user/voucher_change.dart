import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/api_service.dart';
import 'voucher_wallet.dart'; // Thêm import để điều hướng

class VoucherChange extends StatefulWidget {
  final String? voucherId;
  final Map<String, dynamic>? voucherData;

  const VoucherChange({super.key, this.voucherId, this.voucherData});

  @override
  State<VoucherChange> createState() => _VoucherChangeState();
}

class _VoucherChangeState extends State<VoucherChange> {
  List<dynamic> availableVouchers = [];
  bool isLoading = false;
  String errorMessage = '';
  String currentUsername = '';
  int userPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAvailableVouchers();
  }

  /// =======================
  /// LOAD USER DATA
  /// =======================
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? '';
    final points = prefs.getInt('point') ?? 0;

    if (username.isNotEmpty) {
      setState(() {
        currentUsername = username;
        userPoints = points;
      });
    } else {
      // Nếu không có trong prefs, thử lấy từ API
      try {
        final userInfo = await ApiService.getUserByUsername(username);
        if (userInfo != null && mounted) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('point', userInfo["point"] ?? 0);

          setState(() {
            userPoints = userInfo["point"] ?? 0;
          });
        }
      } catch (e) {
        print('Lỗi khi load user points: $e');
      }
    }
  }

  /// =======================
  /// LOAD AVAILABLE VOUCHERS FROM API
  /// =======================
  Future<void> _loadAvailableVouchers() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await ApiService.getAvailableVouchers();

      setState(() {
        if (response is List) {
          availableVouchers = response;
        } else {
          availableVouchers = [];
          errorMessage = 'Định dạng dữ liệu không đúng';
        }
      });
    } catch (e) {
      print('Lỗi khi load available vouchers: $e');
      setState(() {
        errorMessage =
            'Không thể tải danh sách voucher. Vui lòng kiểm tra kết nối và thử lại.';
        availableVouchers = [];
      });
    } finally {
      setState(() {
        isLoading = false;
      });
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
  /// EXCHANGE VOUCHER
  /// =======================
  Future<void> _exchangeVoucher(
    String voucherId,
    int point,
    String partner,
  ) async {
    final discountAmount = _calculateDiscountAmount(point);

    if (currentUsername.isEmpty) {
      _showError(
        'Không tìm thấy thông tin người dùng. Vui lòng đăng nhập lại.',
      );
      return;
    }

    if (userPoints < point) {
      _showError(
        'Bạn không đủ điểm để đổi voucher này. Cần $point điểm, bạn có $userPoints điểm.',
      );
      return;
    }

    // Xác nhận đổi voucher
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận đổi voucher'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bạn có chắc muốn đổi voucher từ:'),
              const SizedBox(height: 8),
              Text(
                '🎁 $partner',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 4),
              Text('💰 $point điểm', style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 12),
              Text(
                'Số tiền được giảm: ${_formatCurrency(discountAmount)}đ',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                'Số điểm hiện tại: $userPoints điểm',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                'Số điểm sau khi đổi: ${userPoints - point} điểm',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đổi ngay'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Hiển thị loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang xử lý đổi voucher...'),
          ],
        ),
      ),
    );

    try {
      // Gọi API để đổi voucher
      final result = await ApiService.exchangeVoucher(
        username: currentUsername,
        voucherId: voucherId,
      );

      // Cập nhật điểm mới
      final newPoints = result['new_point'] ?? userPoints - point;

      // Lưu điểm mới vào SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('point', newPoints);

      // Cập nhật state userPoints
      setState(() {
        userPoints = newPoints;
      });

      // Đóng dialog loading
      if (mounted) Navigator.pop(context);

      // Hiển thị thành công
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('🎉 Đổi voucher thành công!'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bạn đã đổi voucher $partner thành công!'),
                const SizedBox(height: 8),
                Text('Số tiền được giảm: ${_formatCurrency(discountAmount)}đ'),
                const SizedBox(height: 8),
                Text('Số điểm còn lại: $newPoints điểm'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // đóng dialog
                // Thay thế màn hình hiện tại (VoucherChange) bằng VoucherWallet mới
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const VoucherWallet()),
                );
              },
              child: const Text('Xem voucher'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Đóng dialog loading
      if (mounted) Navigator.pop(context);

      String errorMsg = 'Lỗi khi đổi voucher';
      if (e is Exception) {
        errorMsg = e.toString().replaceAll('Exception: ', '');
      }
      _showError('❌ $errorMsg');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// =======================
  /// BUILD VOUCHER CARD
  /// =======================
  Widget _buildVoucherCard(Map<String, dynamic> voucher) {
    final partner = voucher['partner']?.toString() ?? 'Unknown';
    final point = voucher['point'] is int
        ? voucher['point']
        : int.tryParse(voucher['point']?.toString() ?? '0') ?? 0;
    final maxPerUser = voucher['maxPerUser'] is int
        ? voucher['maxPerUser']
        : int.tryParse(voucher['maxPerUser']?.toString() ?? '1') ?? 1;
    final expired = voucher['expired']?.toString() ?? '';
    final voucherId = voucher['_id']?.toString() ?? '';

    // Parse expired date
    DateTime? expiredDate;
    try {
      expiredDate = DateTime.parse(expired);
    } catch (e) {
      expiredDate = null;
    }

    final canExchange = userPoints >= point;
    final daysLeft = expiredDate != null
        ? expiredDate.difference(DateTime.now()).inDays
        : 0;
    final isExpired = expiredDate != null && daysLeft < 0;

    // Tính số tiền được giảm
    final discountAmount = _calculateDiscountAmount(point);

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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
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
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$point điểm',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Hiển thị số tiền được giảm NỔI BẬT
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade200, width: 2),
              ),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      'GIẢM NGAY',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[800],
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatCurrency(discountAmount)}đ',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Icon(Icons.repeat, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Giới hạn: $maxPerUser lần/user',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                      color: isExpired ? Colors.red : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: canExchange && !isExpired
                      ? Colors.green
                      : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: canExchange && !isExpired
                    ? () => _exchangeVoucher(voucherId, point, partner)
                    : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!canExchange) const Icon(Icons.warning, size: 20),
                    if (!canExchange) const SizedBox(width: 8),
                    Text(
                      canExchange && !isExpired
                          ? 'ĐỔI VOUCHER'
                          : isExpired
                          ? 'ĐÃ HẾT HẠN'
                          : 'KHÔNG ĐỦ ĐIỂM',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            if (!canExchange)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Bạn cần $point điểm, hiện có $userPoints điểm',
                  style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Hàm refresh tổng hợp
  Future<void> _refreshData() async {
    await _loadUserData();
    await _loadAvailableVouchers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đổi Voucher'),
        backgroundColor: Colors.green[700],
        actions: [
          // Nút reload ở góc phải
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isLoading ? null : _refreshData,
            tooltip: 'Làm mới',
          ),
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
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green.shade50,
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.green[700], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xin chào, $currentUsername',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Số điểm hiện có: $userPoints điểm',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLoading)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              'Đang tải voucher...',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (errorMessage.isNotEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, color: Colors.red, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              errorMessage,
                              style: TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadAvailableVouchers,
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (availableVouchers.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.card_giftcard,
                              color: Colors.grey[400],
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Hiện chưa có voucher nào',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Vui lòng quay lại sau',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _refreshData,
                        child: ListView.builder(
                          itemCount: availableVouchers.length,
                          itemBuilder: (context, index) {
                            final voucher =
                                availableVouchers[index]
                                    as Map<String, dynamic>;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildVoucherCard(voucher),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
