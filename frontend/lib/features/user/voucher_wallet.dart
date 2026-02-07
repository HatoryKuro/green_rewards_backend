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

  List<dynamic> userVouchers = []; // Voucher user đã đổi
  List<dynamic> availableVouchers = []; // Voucher có thể đổi
  List<dynamic> insufficientVouchers = []; // Voucher chưa đủ điểm
  List<dynamic> expiredVouchers = []; // Voucher hết hạn

  bool isLoadingUser = true;
  bool isLoadingVouchers = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInitialData();
  }

  /// =======================
  /// KHỞI TẠO DỮ LIỆU BAN ĐẦU
  /// =======================
  Future<void> _loadInitialData() async {
    // 1. Load user data trước
    await _loadUserData();

    // 2. Sau đó mới load voucher data nếu có username
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
      userVouchers = [];
      availableVouchers = [];
      insufficientVouchers = [];
      expiredVouchers = [];
    });

    try {
      // Load available vouchers from API
      final availableResponse = await ApiService.getAvailableVouchers();

      // Load user's vouchers (đã đổi)
      final userVouchersResponse = await ApiService.getUserVouchers(
        currentUsername,
      );

      final now = DateTime.now();

      // Process available vouchers (for exchange)
      for (final voucher in availableResponse) {
        final voucherData = voucher as Map<String, dynamic>;
        final point = voucherData['point'] is int
            ? voucherData['point']
            : int.tryParse(voucherData['point']?.toString() ?? '0') ?? 0;
        final expired = voucherData['expired']?.toString() ?? '';
        final maxPerUser = voucherData['maxPerUser'] is int
            ? voucherData['maxPerUser']
            : int.tryParse(voucherData['maxPerUser']?.toString() ?? '1') ?? 1;

        // Parse expired date
        DateTime? expiredDate;
        try {
          expiredDate = DateTime.parse(expired);
        } catch (e) {
          expiredDate = null;
        }

        final isExpired = expiredDate != null && expiredDate.isBefore(now);
        final canExchange = userPoints >= point;

        // Check if user has already exchanged this voucher max times
        final voucherId = voucherData['_id']?.toString() ?? '';
        final userExchangedCount = userVouchersResponse.where((v) {
          final vData = v as Map<String, dynamic>;
          final vId =
              vData['voucher_id']?.toString() ?? vData['_id']?.toString() ?? '';
          return vId == voucherId && vData['status']?.toString() != 'used';
        }).length;

        final reachedLimit = userExchangedCount >= maxPerUser;

        if (isExpired || reachedLimit) {
          expiredVouchers.add({
            ...voucherData,
            'reason': isExpired ? 'Hết hạn' : 'Đã đạt giới hạn',
          });
        } else if (!canExchange) {
          insufficientVouchers.add(voucherData);
        } else {
          availableVouchers.add(voucherData);
        }
      }

      // Process user's vouchers (đã đổi)
      setState(() {
        userVouchers = userVouchersResponse;
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
  /// MARK VOUCHER AS USED
  /// =======================
  Future<void> _useVoucher(
    String voucherId,
    Map<String, dynamic> voucher,
  ) async {
    final partner = voucher['partner']?.toString() ?? 'Unknown';
    final point = voucher['point'] is int
        ? voucher['point']
        : int.tryParse(voucher['point']?.toString() ?? '0') ?? 0;
    final billCode = voucher['billCode']?.toString() ?? '';

    // Show QR dialog
    final qrData =
        'VOUCHER|$currentUsername|$point|$partner|${DateTime.now().toIso8601String()}|$billCode';

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
                  if (billCode.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Mã Bill: $billCode',
                      style: const TextStyle(fontSize: 14, color: Colors.blue),
                    ),
                  ],
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
  /// BUILD VOUCHER CARD FOR USER (ĐÃ ĐỔI)
  /// =======================
  Widget _buildUserVoucherCard(Map<String, dynamic> voucher) {
    final partner = voucher['partner']?.toString() ?? 'Unknown';
    final point = voucher['point'] is int
        ? voucher['point']
        : int.tryParse(voucher['point']?.toString() ?? '0') ?? 0;
    final status = voucher['status']?.toString() ?? 'usable';
    final exchangedAt = voucher['exchanged_at']?.toString() ?? '';
    final usedAt = voucher['used_at']?.toString();
    final voucherId = voucher['_id']?.toString() ?? '';
    final billCode = voucher['billCode']?.toString() ?? '';

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

            // Hiển thị mã Bill nếu có
            if (billCode.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.receipt, size: 16, color: Colors.blue[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Mã Bill: $billCode',
                    style: TextStyle(fontSize: 12, color: Colors.blue[600]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],

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
  /// BUILD VOUCHER CARD FOR EXCHANGE (CÓ THỂ ĐỔI)
  /// =======================
  Widget _buildExchangeVoucherCard(Map<String, dynamic> voucher) {
    final partner = voucher['partner']?.toString() ?? 'Unknown';
    final point = voucher['point'] is int
        ? voucher['point']
        : int.tryParse(voucher['point']?.toString() ?? '0') ?? 0;
    final maxPerUser = voucher['maxPerUser'] is int
        ? voucher['maxPerUser']
        : int.tryParse(voucher['maxPerUser']?.toString() ?? '1') ?? 1;
    final expired = voucher['expired']?.toString() ?? '';
    final voucherId = voucher['_id']?.toString() ?? '';
    final billCode = voucher['billCode']?.toString() ?? '';
    final reason = voucher['reason']?.toString();

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
    final isExpired =
        expiredDate != null && expiredDate.isBefore(DateTime.now());

    // Tính số tiền được giảm
    final discountAmount = _calculateDiscountAmount(point);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: reason != null ? Colors.grey[100] : null,
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
                      color: reason != null ? Colors.grey : Colors.green,
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
                    color: reason != null
                        ? Colors.grey.shade200
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$point điểm',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: reason != null ? Colors.grey : Colors.green,
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
                color: reason != null
                    ? Colors.grey.shade100
                    : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: reason != null
                      ? Colors.grey.shade300
                      : Colors.amber.shade200,
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
                        color: reason != null ? Colors.grey : Colors.amber[800],
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatCurrency(discountAmount)}đ',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: reason != null ? Colors.grey : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Hiển thị mã Bill nếu có
            if (billCode.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.receipt, size: 16, color: Colors.blue[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Mã Bill: $billCode',
                    style: TextStyle(fontSize: 12, color: Colors.blue[600]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],

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

            if (reason != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.info, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    'Lý do: $reason',
                    style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: reason != null
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'KHÔNG THỂ ĐỔI',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    )
                  : !canExchange
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'CHƯA ĐỦ ĐIỂM',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    )
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        // Navigate to voucher change page với voucher data
                        Navigator.pushNamed(
                          context,
                          '/voucher-change',
                          arguments: {
                            'voucherId': voucherId,
                            'voucherData': voucher,
                          },
                        );
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.card_giftcard, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'ĐỔI VOUCHER',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
            ),

            if (!canExchange && reason == null)
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

  @override
  Widget build(BuildContext context) {
    // Hiển thị loading khi đang load user data
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

    // Hiển thị lỗi nếu không có user data
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

    // Tính toán số voucher theo từng loại
    final usableVouchers = userVouchers.where((v) {
      final status =
          (v as Map<String, dynamic>)['status']?.toString() ?? 'usable';
      return status == 'usable';
    }).toList();

    final usedVouchers = userVouchers.where((v) {
      final status =
          (v as Map<String, dynamic>)['status']?.toString() ?? 'usable';
      return status == 'used';
    }).toList();

    // Build UI bình thường khi đã có user data
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
            Tab(icon: Icon(Icons.card_giftcard), text: 'CÓ THỂ ĐỔI'),
            Tab(icon: Icon(Icons.money_off), text: 'CHƯA ĐỦ ĐIỂM'),
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
                // Tab 1: Voucher của tôi (đã đổi)
                RefreshIndicator(
                  onRefresh: _loadAllVoucherData,
                  child: userVouchers.isEmpty
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
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.card_giftcard),
                                label: const Text('Đổi voucher ngay'),
                                onPressed: () {
                                  _tabController.index = 1;
                                },
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            // Sub tabs cho voucher của tôi
                            Container(
                              color: Colors.green[50],
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () {
                                        // Hiển thị tất cả
                                      },
                                      child: Text(
                                        'Có thể dùng (${usableVouchers.length})',
                                        style: TextStyle(
                                          color: Colors.green[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () {
                                        // Hiển thị đã sử dụng
                                      },
                                      child: Text(
                                        'Đã sử dụng (${usedVouchers.length})',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: usableVouchers.length,
                                itemBuilder: (context, index) {
                                  final voucher =
                                      usableVouchers[index]
                                          as Map<String, dynamic>;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _buildUserVoucherCard(voucher),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                ),

                // Tab 2: Có thể đổi
                RefreshIndicator(
                  onRefresh: _loadAllVoucherData,
                  child: availableVouchers.isEmpty
                      ? Center(
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
                                'Không có voucher có thể đổi',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Hãy tích lũy thêm điểm để đổi voucher',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: availableVouchers.length,
                          itemBuilder: (context, index) {
                            final voucher =
                                availableVouchers[index]
                                    as Map<String, dynamic>;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildExchangeVoucherCard(voucher),
                            );
                          },
                        ),
                ),

                // Tab 3: Chưa đủ điểm
                RefreshIndicator(
                  onRefresh: _loadAllVoucherData,
                  child: insufficientVouchers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.money_off,
                                color: Colors.grey[400],
                                size: 64,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Tất cả voucher đều đủ điểm để đổi',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Bạn có $userPoints điểm',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: insufficientVouchers.length,
                          itemBuilder: (context, index) {
                            final voucher =
                                insufficientVouchers[index]
                                    as Map<String, dynamic>;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildExchangeVoucherCard(voucher),
                            );
                          },
                        ),
                ),

                // Tab 4: Hết hạn/Đạt giới hạn
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
                                'Không có voucher hết hạn',
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
                              child: _buildExchangeVoucherCard(voucher),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[700],
        onPressed: () {
          // Đi đến màn hình đổi voucher
          Navigator.pushNamed(context, '/voucher-change');
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
