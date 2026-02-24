import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/api_service.dart';
import 'voucher_wallet.dart'; // Điều hướng sang ví voucher sau khi đổi thành công

/// Màn hình cho phép người dùng đổi điểm lấy voucher
class VoucherChange extends StatefulWidget {
  final String? voucherId;
  final Map<String, dynamic>? voucherData;

  const VoucherChange({super.key, this.voucherId, this.voucherData});

  @override
  State<VoucherChange> createState() => _VoucherChangeState();
}

class _VoucherChangeState extends State<VoucherChange> {
  List<dynamic> availableVouchers = []; // Danh sách voucher có thể đổi
  bool isLoading = false; // Đang tải dữ liệu
  String errorMessage = ''; // Thông báo lỗi
  String currentUsername = ''; // Tên người dùng hiện tại
  int userPoints = 0; // Số điểm hiện có

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Tải thông tin người dùng
    _loadAvailableVouchers(); // Tải danh sách voucher
  }

  /// ==================== TẢI THÔNG TIN NGƯỜI DÙNG ====================
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
      // Nếu không có trong SharedPreferences, thử lấy từ API
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
        // Lỗi load user – không cần in, chỉ cần hiển thị thông báo sau
      }
    }
  }

  /// ==================== TẢI DANH SÁCH VOUCHER CÓ THỂ ĐỔI ====================
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
      // Lỗi kết nối hoặc xử lý – hiển thị thông báo cho người dùng
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

  /// ==================== TÍNH SỐ TIỀN GIẢM DỰA TRÊN ĐIỂM ====================
  double _calculateDiscountAmount(int point) {
    // Công thức: 500 điểm = 10.000đ
    if (point > 0) {
      final multiplier = point / 500.0;
      return multiplier * 10000.0;
    }
    return 0.0;
  }

  /// ==================== ĐỊNH DẠNG TIỀN TỆ (VD: 10,000) ====================
  String _formatCurrency(double amount) {
    return amount.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  /// ==================== XỬ LÝ ĐỔI VOUCHER ====================
  Future<void> _exchangeVoucher(
    String voucherId,
    int point,
    String partner,
    int maxPerUser,
    int exchangedCount, // Số lần user đã đổi voucher này (do server cung cấp)
  ) async {
    // Kiểm tra thông tin người dùng
    if (currentUsername.isEmpty) {
      _showError(
        'Không tìm thấy thông tin người dùng. Vui lòng đăng nhập lại.',
      );
      return;
    }

    // Kiểm tra đủ điểm
    if (userPoints < point) {
      _showError(
        'Bạn không đủ điểm để đổi voucher này. Cần $point điểm, bạn có $userPoints điểm.',
      );
      return;
    }

    // Kiểm tra giới hạn số lần đổi (maxPerUser)
    if (exchangedCount >= maxPerUser) {
      _showError('Bạn đã đạt giới hạn đổi voucher này ($maxPerUser lần).');
      return;
    }

    final discountAmount = _calculateDiscountAmount(point);

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
      // Gọi API đổi voucher
      final result = await ApiService.exchangeVoucher(
        username: currentUsername,
        voucherId: voucherId,
      );

      // Cập nhật điểm mới từ server
      final newPoints = result['new_point'] ?? userPoints - point;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('point', newPoints);

      setState(() {
        userPoints = newPoints;
      });

      // Đóng dialog loading
      if (mounted) Navigator.pop(context);

      // Tải lại danh sách voucher để cập nhật exchanged_count (nếu server hỗ trợ)
      await _loadAvailableVouchers();

      // Hiển thị thành công và chuyển sang ví voucher
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
      // Đóng dialog loading nếu có lỗi
      if (mounted) Navigator.pop(context);

      String errorMsg = 'Lỗi khi đổi voucher';
      if (e is Exception) {
        errorMsg = e.toString().replaceAll('Exception: ', '');
      }
      _showError('❌ $errorMsg');
    }
  }

  /// Hiển thị thông báo lỗi dạng SnackBar
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// ==================== XÂY DỰNG THẺ VOUCHER ====================
  Widget _buildVoucherCard(Map<String, dynamic> voucher) {
    // Lấy các trường từ dữ liệu voucher
    final partner = voucher['partner']?.toString() ?? 'Unknown';
    final point = voucher['point'] is int
        ? voucher['point']
        : int.tryParse(voucher['point']?.toString() ?? '0') ?? 0;
    final maxPerUser = voucher['maxPerUser'] is int
        ? voucher['maxPerUser']
        : int.tryParse(voucher['maxPerUser']?.toString() ?? '1') ?? 1;
    final expired = voucher['expired']?.toString() ?? '';
    final voucherId = voucher['_id']?.toString() ?? '';

    // Số lần user đã đổi voucher này (do server trả về, mặc định 0 nếu không có)
    final exchangedCount = voucher['exchanged_count'] is int
        ? voucher['exchanged_count']
        : int.tryParse(voucher['exchanged_count']?.toString() ?? '0') ?? 0;

    // Parse ngày hết hạn
    DateTime? expiredDate;
    try {
      expiredDate = DateTime.parse(expired);
    } catch (e) {
      expiredDate = null;
    }

    // Tính toán trạng thái
    final daysLeft = expiredDate != null
        ? expiredDate.difference(DateTime.now()).inDays
        : 0;
    final isExpired = expiredDate != null && daysLeft < 0;
    final hasEnoughPoints = userPoints >= point;
    final hasReachedLimit = exchangedCount >= maxPerUser; // Đã đạt giới hạn?
    final canExchange = hasEnoughPoints && !isExpired && !hasReachedLimit;

    final discountAmount = _calculateDiscountAmount(point);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Tên đối tác + điểm
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

            // Hiển thị số tiền giảm nổi bật
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

            // Giới hạn đổi
            Row(
              children: [
                Icon(Icons.repeat, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Giới hạn: $maxPerUser lần/user (đã đổi $exchangedCount lần)',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // Ngày hết hạn
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

            // Nút đổi voucher (xám nếu không thể đổi)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: canExchange ? Colors.green : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: canExchange
                    ? () => _exchangeVoucher(
                        voucherId,
                        point,
                        partner,
                        maxPerUser,
                        exchangedCount,
                      )
                    : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!hasEnoughPoints) const Icon(Icons.warning, size: 20),
                    if (!hasEnoughPoints) const SizedBox(width: 8),
                    Text(
                      canExchange
                          ? 'ĐỔI VOUCHER'
                          : isExpired
                          ? 'ĐÃ HẾT HẠN'
                          : hasReachedLimit
                          ? 'ĐÃ ĐẠT GIỚI HẠN'
                          : 'KHÔNG ĐỦ ĐIỂM',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            // Hiển thị thông báo phụ nếu thiếu điểm
            if (!hasEnoughPoints && !isExpired && !hasReachedLimit)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Bạn cần $point điểm, hiện có $userPoints điểm',
                  style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                  textAlign: TextAlign.center,
                ),
              ),

            // Hiển thị thông báo phụ nếu đã đạt giới hạn
            if (hasReachedLimit && !isExpired)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Bạn đã đổi đủ $maxPerUser lần cho voucher này',
                  style: TextStyle(fontSize: 12, color: Colors.red[700]),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Làm mới dữ liệu (kéo xuống hoặc nhấn nút reload)
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
          // Nút reload
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isLoading ? null : _refreshData,
            tooltip: 'Làm mới',
          ),
          // Hiển thị điểm hiện tại
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
          // Thanh thông tin người dùng
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
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Nội dung chính
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
