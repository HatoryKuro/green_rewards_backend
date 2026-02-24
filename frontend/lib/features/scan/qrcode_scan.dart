import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/services/api_service.dart';

/// Màn hình quét QR dành cho admin:
/// - Quét mã USERQR để cộng điểm cho user (hiện dialog nhập thông tin)
/// - Quét mã VOUCHER để đánh dấu voucher đã sử dụng (hiện dialog xác nhận)
class ScanQR extends StatefulWidget {
  const ScanQR({super.key});

  @override
  State<ScanQR> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanQR> with SingleTickerProviderStateMixin {
  bool scanned = false; // Chống quét trùng trong một lần xử lý
  List<Map<String, dynamic>> partners = [];
  bool isLoadingPartners = false;
  late AnimationController _animationController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _loadPartners();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _scanAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPartners() async {
    setState(() => isLoadingPartners = true);
    try {
      final response = await ApiService.getPartnerNames();
      setState(() {
        partners = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      // Fallback: dùng danh sách cứng nếu API lỗi
      setState(() {
        partners = const [
          {'name': 'May Cha'},
          {'name': 'TuTiMi'},
          {'name': 'Sunday Basic'},
          {'name': 'Sóng Sánh'},
          {'name': 'Te Amo'},
          {'name': 'Trà Sữa Boss'},
          {'name': 'Hồng Trà Ngô Gia'},
          {'name': 'Lục Trà Thăng Hoa'},
          {'name': 'Viên Viên'},
          {'name': 'TocoToco'},
        ];
      });
    } finally {
      setState(() => isLoadingPartners = false);
    }
  }

  /// Xử lý khi quét được mã QR
  Future<void> handleQR(String raw) async {
    if (scanned) return;
    scanned = true;

    final parts = raw.split('|');
    final type = parts.isNotEmpty ? parts[0] : '';

    // Xử lý theo loại QR
    if (type == 'USERQR') {
      await _handleUserQR(parts);
    } else if (type == 'VOUCHER') {
      await _handleVoucherQR(parts);
    } else {
      _showErrorDialog('QR không hợp lệ', 'Định dạng không được hỗ trợ.');
      scanned = false;
    }
  }

  /// Xử lý QR dành cho user cộng điểm: USERQR|username
  Future<void> _handleUserQR(List<String> parts) async {
    if (parts.length != 2) {
      _showErrorDialog('QR không hợp lệ', 'Thiếu thông tin username.');
      scanned = false;
      return;
    }

    final username = parts[1];

    // Hiển thị dialog nhập thông tin cộng điểm
    final result = await showDialog<_ScanResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddPointDialog(
        username: username,
        partners: partners,
        isLoadingPartners: isLoadingPartners,
      ),
    );

    if (result == null || result.point <= 0) {
      scanned = false;
      return;
    }

    // Gọi API cộng điểm
    try {
      final res = await ApiService.addPointByQR(
        username: username,
        partner: result.partner,
        billCode: result.billCode,
        point: result.point,
      );

      if (!mounted) return;

      // Hiển thị popup thành công đẹp mắt
      await _showSuccessDialog(
        title: 'Cộng điểm thành công',
        content: '+${result.point} điểm cho $username',
        extra: 'Tổng điểm: ${res["point"]}',
        icon: Icons.eco,
      );

      // Quay về màn hình trước với kết quả true để reload nếu cần
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showErrorDialog('Lỗi cộng điểm', _parseErrorMessage(e));
      scanned = false;
    }
  }

  /// Xử lý QR voucher: VOUCHER|voucherId|username|point|partner|timestamp
  Future<void> _handleVoucherQR(List<String> parts) async {
    if (parts.length != 6) {
      _showErrorDialog('QR không hợp lệ', 'Dữ liệu voucher không đầy đủ.');
      scanned = false;
      return;
    }

    final voucherId = parts[1];
    final username = parts[2];
    final point = int.tryParse(parts[3]) ?? 0;
    final partner = parts[4];
    final timestamp = parts[5]; // có thể dùng để kiểm tra thời gian nếu cần

    if (voucherId.isEmpty || point <= 0 || partner.isEmpty) {
      _showErrorDialog('QR không hợp lệ', 'Thông tin voucher không chính xác.');
      scanned = false;
      return;
    }

    // Hiển thị dialog xác nhận sử dụng voucher
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _VoucherConfirmDialog(
        voucherId: voucherId,
        username: username,
        point: point,
        partner: partner,
      ),
    );

    if (confirm != true) {
      scanned = false;
      return;
    }

    // Hiển thị loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await ApiService.markVoucherUsed(voucherId);
      if (mounted) Navigator.pop(context); // đóng loading

      if (success) {
        await _showSuccessDialog(
          title: 'Sử dụng voucher thành công',
          content: 'Voucher $partner đã được xác nhận.',
          extra: 'Người dùng: $username',
          icon: Icons.verified,
        );
        if (mounted) Navigator.pop(context, true); // quay về và reload
      } else {
        // Trường hợp API trả về false nhưng không throw exception
        // Có thể do voucher đã dùng hoặc lỗi khác, cần phân tích thêm
        // Ở đây ta giả định backend throw exception khi có lỗi, nên ít khi vào đây
        _showErrorDialog('Lỗi', 'Không thể đánh dấu voucher đã sử dụng.');
        scanned = false;
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // đóng loading
      final errorMsg = _parseErrorMessage(e);
      // Kiểm tra nếu lỗi là do voucher đã được sử dụng
      if (errorMsg.toLowerCase().contains('already used') ||
          errorMsg.toLowerCase().contains('đã sử dụng')) {
        _showErrorDialog(
          'Voucher đã được sử dụng',
          'Voucher này đã được quét và xác nhận trước đó.',
        );
      } else {
        _showErrorDialog('Lỗi kết nối', errorMsg);
      }
      scanned = false;
    }
  }

  /// Trích xuất thông báo lỗi từ exception
  String _parseErrorMessage(dynamic e) {
    if (e is Exception) {
      return e.toString().replaceAll('Exception: ', '');
    }
    return e.toString();
  }

  /// Hiển thị dialog lỗi chung
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red[700]),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  /// Hiển thị popup thành công đẹp mắt
  Future<void> _showSuccessDialog({
    required String title,
    required String content,
    String? extra,
    required IconData icon,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.green, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            if (extra != null) ...[
              const SizedBox(height: 4),
              Text(
                extra,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text('QR Scan (Admin)'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final value = capture.barcodes.first.rawValue;
              if (value != null) handleQR(value);
            },
          ),
          Container(color: Colors.black.withOpacity(0.45)),
          // Khung quét có animation
          Center(
            child: AnimatedBuilder(
              animation: _scanAnimation,
              builder: (context, child) {
                return Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.greenAccent.withOpacity(
                        0.7 + 0.3 * _scanAnimation.value,
                      ),
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: const [
                Icon(Icons.eco, color: Colors.greenAccent, size: 42),
                SizedBox(height: 8),
                Text(
                  'Đưa QR vào khung để quét',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// =======================
/// KẾT QUẢ TỪ DIALOG NHẬP THÔNG TIN CỘNG ĐIỂM
/// =======================
class _ScanResult {
  final int point;
  final String partner;
  final String billCode;

  _ScanResult({
    required this.point,
    required this.partner,
    required this.billCode,
  });
}

/// =======================
/// DIALOG XÁC NHẬN SỬ DỤNG VOUCHER
/// =======================
class _VoucherConfirmDialog extends StatelessWidget {
  final String voucherId;
  final String username;
  final int point;
  final String partner;

  const _VoucherConfirmDialog({
    required this.voucherId,
    required this.username,
    required this.point,
    required this.partner,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.confirmation_number,
                color: Colors.green,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Xác nhận sử dụng voucher',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.person, 'Người dùng', username),
            _buildInfoRow(Icons.store, 'Đối tác', partner),
            _buildInfoRow(Icons.star, 'Điểm', '$point điểm'),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Xác nhận'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// =======================
/// DIALOG NHẬP THÔNG TIN CỘNG ĐIỂM
/// =======================
class _AddPointDialog extends StatefulWidget {
  final String username;
  final List<Map<String, dynamic>> partners;
  final bool isLoadingPartners;

  const _AddPointDialog({
    required this.username,
    required this.partners,
    required this.isLoadingPartners,
  });

  @override
  State<_AddPointDialog> createState() => _AddPointDialogState();
}

class _AddPointDialogState extends State<_AddPointDialog> {
  final billController = TextEditingController();
  final moneyController = TextEditingController();

  String selectedPartner = '';

  @override
  void initState() {
    super.initState();
    if (widget.partners.isNotEmpty) {
      selectedPartner = widget.partners[0]['name'] ?? '';
    }
  }

  int calcPoint(int money) => (money ~/ 1000) * 2;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_add, color: Colors.green),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Cộng điểm cho user',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Username: ${widget.username}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),

            // Chọn đối tác
            if (widget.isLoadingPartners)
              const LinearProgressIndicator()
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Đối tác:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedPartner.isNotEmpty
                            ? selectedPartner
                            : null,
                        isExpanded: true,
                        hint: const Text('Chọn đối tác'),
                        items: widget.partners.map((partner) {
                          return DropdownMenuItem<String>(
                            value: partner['name']?.toString() ?? '',
                            child: Text(partner['name']?.toString() ?? ''),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() => selectedPartner = newValue);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 12),

            // Mã bill
            TextField(
              controller: billController,
              decoration: const InputDecoration(
                labelText: 'Mã Bill *',
                border: OutlineInputBorder(),
                hintText: 'Nhập mã hóa đơn',
              ),
            ),
            const SizedBox(height: 12),

            // Số tiền
            TextField(
              controller: moneyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số tiền (VNĐ) *',
                border: OutlineInputBorder(),
                hintText: 'Ví dụ: 50000',
                suffixText: 'VNĐ',
              ),
              onChanged: (_) => setState(() {}),
            ),

            // Hiển thị điểm
            if (moneyController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Text('Điểm sẽ cộng: '),
                    Text(
                      '${calcPoint(int.tryParse(moneyController.text) ?? 0)} điểm',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      final money = int.tryParse(moneyController.text) ?? 0;
                      if (selectedPartner.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vui lòng chọn đối tác'),
                          ),
                        );
                        return;
                      }
                      if (billController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vui lòng nhập mã bill'),
                          ),
                        );
                        return;
                      }
                      if (money <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vui lòng nhập số tiền hợp lệ'),
                          ),
                        );
                        return;
                      }

                      Navigator.pop(
                        context,
                        _ScanResult(
                          point: calcPoint(money),
                          partner: selectedPartner,
                          billCode: billController.text.trim(),
                        ),
                      );
                    },
                    child: const Text('Xác nhận'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    billController.dispose();
    moneyController.dispose();
    super.dispose();
  }
}
