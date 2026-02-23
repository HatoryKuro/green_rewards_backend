import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/api_service.dart';

class CreateVoucher extends StatefulWidget {
  const CreateVoucher({super.key});

  @override
  State<CreateVoucher> createState() => _CreateVoucherState();
}

class _CreateVoucherState extends State<CreateVoucher> {
  final pointController = TextEditingController();
  final limitController = TextEditingController();

  String selectedPartner = '';
  DateTime? expiredDate;

  List<Map<String, dynamic>> partners = [];
  bool isLoadingPartners = false;
  bool isCreatingVoucher = false;
  bool isUnlimited = false;
  String partnerError = '';
  String pointError = '';
  String dateError = '';
  String limitError = '';

  double discountAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadPartners();

    pointController.addListener(_calculateDiscount);
    pointController.addListener(_validatePoint);
    limitController.addListener(_validateLimit);
  }

  void _validatePoint() {
    final point = int.tryParse(pointController.text) ?? 0;
    if (pointController.text.isNotEmpty && point < 500) {
      setState(() {
        pointError = 'Số điểm tối thiểu là 500 (tương đương 10.000đ)';
      });
    } else {
      setState(() {
        pointError = '';
      });
    }
  }

  void _validateLimit() {
    if (!isUnlimited && limitController.text.isNotEmpty) {
      final limit = int.tryParse(limitController.text) ?? 0;
      if (limit <= 0) {
        setState(() {
          limitError = 'Số lần đổi phải lớn hơn 0';
        });
      } else {
        setState(() {
          limitError = '';
        });
      }
    } else {
      setState(() {
        limitError = '';
      });
    }
  }

  void _validateDate() {
    if (expiredDate != null) {
      final now = DateTime.now();
      final minDate = now.add(const Duration(days: 1));

      if (expiredDate!.isBefore(minDate)) {
        setState(() {
          dateError = 'Voucher phải tồn tại ít nhất 24h (từ ngày mai trở đi)';
        });
      } else {
        setState(() {
          dateError = '';
        });
      }
    }
  }

  void _calculateDiscount() {
    final point = int.tryParse(pointController.text) ?? 0;

    if (point > 0) {
      final multiplier = point / 500.0;
      setState(() {
        discountAmount = multiplier * 10000.0;
      });
    } else {
      setState(() {
        discountAmount = 0.0;
      });
    }
  }

  Future<void> _loadPartners() async {
    setState(() {
      isLoadingPartners = true;
      partnerError = '';
    });

    try {
      final response = await ApiService.getPartnerNames();

      if (response is List) {
        if (response.isNotEmpty) {
          setState(() {
            partners = List<Map<String, dynamic>>.from(response);
            if (partners.isNotEmpty) {
              selectedPartner = partners[0]['name']?.toString() ?? '';
            }
          });
        } else {
          setState(() {
            partnerError =
                'Không có đối tác nào trong hệ thống. Vui lòng thêm đối tác trước khi tạo voucher.';
          });
        }
      } else {
        setState(() {
          partnerError =
              'Định dạng dữ liệu partners không đúng. Vui lòng thử lại.';
        });
      }
    } catch (e) {
      print('Lỗi khi load partners: $e');
      setState(() {
        partnerError =
            'Không thể tải danh sách đối tác. Vui lòng kiểm tra kết nối và thử lại.';
      });
    } finally {
      setState(() {
        isLoadingPartners = false;
      });
    }
  }

  Future<void> pickDate() async {
    final now = DateTime.now();
    final minDate = now.add(const Duration(days: 1));

    final date = await showDatePicker(
      context: context,
      initialDate: minDate,
      firstDate: minDate,
      lastDate: DateTime(now.year + 2),
    );

    if (date != null) {
      setState(() {
        expiredDate = date;
        _validateDate();
      });
    }
  }

  Future<void> publishVoucher() async {
    final point = int.tryParse(pointController.text) ?? 0;
    final maxPerUser = isUnlimited
        ? 0
        : (int.tryParse(limitController.text) ?? 0);

    if (selectedPartner.isEmpty) {
      showMsg('Vui lòng chọn nhà đối tác');
      return;
    }

    if (point < 500) {
      showMsg('Số điểm tối thiểu là 500 (tương đương 10.000đ)');
      return;
    }

    // VALIDATION ĐÃ SỬA: Chỉ kiểm tra khi không phải unlimited
    if (!isUnlimited) {
      if (limitController.text.isEmpty) {
        showMsg('Vui lòng nhập số lần đổi');
        return;
      }
      if (maxPerUser <= 0) {
        showMsg('Số lần đổi phải lớn hơn 0');
        return;
      }
    }

    if (expiredDate == null) {
      showMsg('Vui lòng chọn ngày hết hạn');
      return;
    }

    final minDate = DateTime.now().add(const Duration(days: 1));
    if (expiredDate!.isBefore(minDate)) {
      showMsg('Voucher phải tồn tại ít nhất 24h (chọn từ ngày mai trở đi)');
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận phát hành'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Voucher sẽ được gửi cho TẤT CẢ user. Bạn chắc chắn chứ?',
            ),
            const SizedBox(height: 12),
            Text(
              '🎁 $selectedPartner',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('💰 $point điểm (Tương đương ${discountAmount.toInt()}đ)'),
            const SizedBox(height: 4),
            Text(
              isUnlimited
                  ? '📝 Giới hạn: KHÔNG GIỚI HẠN (đổi liên tục) - maxPerUser=0'
                  : '📝 Giới hạn: $maxPerUser lần/user',
            ),
            const SizedBox(height: 4),
            Text(
              '📅 Hết hạn: ${expiredDate!.day}/${expiredDate!.month}/${expiredDate!.year}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Phát hành'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() {
      isCreatingVoucher = true;
    });

    try {
      final expiredDateString = expiredDate!.toIso8601String();

      // DEBUG: In thông tin sẽ gửi
      print('======= DEBUG VOUCHER CREATION =======');
      print('Partner: $selectedPartner');
      print('Point: $point');
      print('Max Per User: $maxPerUser (Unlimited: $isUnlimited)');
      print('Expired: $expiredDateString');
      print('=====================================');

      final result = await ApiService.createVoucher(
        partner: selectedPartner,
        point: point,
        maxPerUser: isUnlimited ? 0 : maxPerUser,
        expired: expiredDateString,
      );

      print('✅ Voucher created successfully: $result');

      showMsg(
        '🎉 Phát hành voucher thành công! ID: ${result['voucher_id'] ?? 'N/A'}',
      );

      pointController.clear();
      limitController.clear();
      setState(() {
        expiredDate = null;
        discountAmount = 0.0;
        isUnlimited = false;
        pointError = '';
        dateError = '';
        limitError = '';
      });
    } catch (e) {
      String errorMessage = 'Lỗi khi phát hành voucher';
      if (e is Exception) {
        errorMessage = e.toString().replaceAll('Exception: ', '');

        // Hiển thị chi tiết lỗi để debug
        if (errorMessage.contains('Thiếu trường maxPerUser')) {
          errorMessage +=
              '\n\n🔍 Gợi ý sửa lỗi:\n'
              '1. Kiểm tra backend đã được deploy với code mới chưa\n'
              '2. Đảm bảo field "maxPerUser" được gửi (kể cả giá trị 0)\n'
              '3. Kiểm tra kết nối API';
        } else if (errorMessage.contains('Lỗi kết nối')) {
          errorMessage +=
              '\n\n🔍 Kiểm tra:\n'
              '1. Máy chủ có đang hoạt động không\n'
              '2. Kết nối internet\n'
              '3. URL API: ${ApiService.baseUrl}';
        }
      }

      // Hiển thị dialog lỗi chi tiết
      _showErrorDialog(errorMessage);

      print('❌ Voucher creation error: $e');
    } finally {
      setState(() {
        isCreatingVoucher = false;
      });
    }
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Lỗi Phát Hành Voucher'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(errorMessage, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Thông tin gửi đi:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text('• Đối tác: $selectedPartner'),
              Text('• Điểm: ${pointController.text}'),
              Text(
                '• Giới hạn: ${isUnlimited ? "Không giới hạn (0)" : limitController.text}',
              ),
              if (expiredDate != null)
                Text(
                  '• Hết hạn: ${expiredDate!.day}/${expiredDate!.month}/${expiredDate!.year}',
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          if (errorMessage.contains('maxPerUser'))
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showDebugInfo();
              },
              child: const Text('Xem Chi Tiết Debug'),
            ),
        ],
      ),
    );
  }

  void _showDebugInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thông Tin Debug'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Kiểm tra backend:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('1. Đảm bảo code voucher.py đã được cập nhật:'),
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text(
                  '• Sửa: if not data.get(field) → if field not in data',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
              const SizedBox(height: 8),
              const Text('2. Restart server backend'),
              const SizedBox(height: 8),
              const Text('3. Kiểm tra endpoint:'),
              Text(
                'POST ${ApiService.baseUrl}/admin/vouchers',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Dữ liệu gửi đi:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  jsonEncode({
                    "partner": selectedPartner,
                    "point": int.tryParse(pointController.text) ?? 0,
                    "maxPerUser": isUnlimited
                        ? 0
                        : (int.tryParse(limitController.text) ?? 0),
                    "expired": expiredDate?.toIso8601String(),
                  }),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: msg.contains('❌') ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo Voucher'),
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// PARTNER SELECTION
            const Text(
              'Nhà đối tác',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),

            if (isLoadingPartners)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 10),
                    Text('Đang tải danh sách đối tác...'),
                  ],
                ),
              )
            else if (partnerError.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partnerError,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Thử lại'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                      onPressed: _loadPartners,
                    ),
                  ],
                ),
              )
            else if (partners.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Không có đối tác nào trong hệ thống.',
                  style: TextStyle(color: Colors.orange),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedPartner.isNotEmpty ? selectedPartner : null,
                    isExpanded: true,
                    hint: const Text('Chọn đối tác'),
                    items: partners.map((partner) {
                      final partnerName = partner['name']?.toString() ?? '';
                      final partnerId = partner['id']?.toString() ?? '';

                      return DropdownMenuItem<String>(
                        value: partnerName,
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  partnerName.isNotEmpty
                                      ? partnerName
                                            .substring(0, 1)
                                            .toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: Colors.green[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    partnerName,
                                    style: const TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (partnerId.isNotEmpty)
                                    Text(
                                      'ID: $partnerId',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedPartner = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),

            const SizedBox(height: 16),

            /// POINT INPUT
            const Text(
              'Số điểm cần đổi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: pointController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Ví dụ: 500 (tối thiểu)',
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: pointError.isNotEmpty ? Colors.red : Colors.grey,
                  ),
                ),
                errorText: pointError.isNotEmpty ? pointError : null,
                errorStyle: const TextStyle(color: Colors.red),
                prefixIcon: const Icon(Icons.star, color: Colors.amber),
                suffixText: 'điểm',
              ),
            ),

            /// HIỂN THỊ SỐ TIỀN ĐƯỢC GIẢM
            if (pointController.text.isNotEmpty &&
                int.tryParse(pointController.text) != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: pointError.isNotEmpty
                        ? Colors.red.shade50
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: pointError.isNotEmpty
                          ? Colors.red.shade100
                          : Colors.green.shade100,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.money,
                        color: pointError.isNotEmpty
                            ? Colors.red[700]
                            : Colors.green[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Số tiền được giảm:',
                              style: TextStyle(
                                fontSize: 12,
                                color: pointError.isNotEmpty
                                    ? Colors.red[600]
                                    : Colors.grey[600],
                              ),
                            ),
                            Text(
                              '${discountAmount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: pointError.isNotEmpty
                                    ? Colors.red
                                    : Colors.green,
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
                          color: pointError.isNotEmpty
                              ? Colors.red.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: pointError.isNotEmpty
                                ? Colors.red.shade200
                                : Colors.orange.shade200,
                          ),
                        ),
                        child: Text(
                          '500 điểm = 10.000đ',
                          style: TextStyle(
                            fontSize: 11,
                            color: pointError.isNotEmpty
                                ? Colors.red[700]
                                : Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            /// LIMIT INPUT
            const Text(
              'Số lần mỗi user được đổi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: limitController,
              keyboardType: TextInputType.number,
              enabled: !isUnlimited,
              decoration: InputDecoration(
                hintText: 'Ví dụ: 1 / 2 / 5',
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: limitError.isNotEmpty ? Colors.red : Colors.grey,
                  ),
                ),
                errorText: limitError.isNotEmpty ? limitError : null,
                errorStyle: const TextStyle(color: Colors.red),
                prefixIcon: const Icon(Icons.person, color: Colors.blue),
                helperText: isUnlimited
                    ? null
                    : 'Giới hạn số lần mỗi user có thể đổi voucher này',
                suffixIcon: isUnlimited
                    ? const Icon(Icons.lock, color: Colors.grey, size: 18)
                    : null,
              ),
            ),

            // Thêm thông báo khi chọn đổi liên tục
            if (isUnlimited)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.green[700],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontStyle: FontStyle.italic,
                          ),
                          children: const [
                            TextSpan(
                              text:
                                  'Đổi liên tục và không bị giới hạn số lần đổi',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            /// ĐỔI LIÊN TỤC CHECKBOX
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: isUnlimited,
                    onChanged: (value) {
                      setState(() {
                        isUnlimited = value ?? false;
                        if (isUnlimited) {
                          limitController.clear();
                          limitError = '';
                        }
                      });
                    },
                    activeColor: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Đổi Không Giới Hạn Số Lần',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isUnlimited
                              ? 'Voucher sẽ không bị giới hạn số lần đổi'
                              : 'Voucher sẽ bị giới hạn số lần đổi',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// EXPIRY DATE SELECTION
            const Text(
              'Thời hạn voucher',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  side: BorderSide(
                    color: dateError.isNotEmpty
                        ? Colors.red
                        : (expiredDate == null ? Colors.grey : Colors.green),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                onPressed: pickDate,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: dateError.isNotEmpty
                          ? Colors.red
                          : (expiredDate == null ? Colors.grey : Colors.green),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        expiredDate == null
                            ? 'Chọn ngày hết hạn (từ ngày mai)'
                            : 'Hết hạn: ${expiredDate!.day}/${expiredDate!.month}/${expiredDate!.year}',
                        style: TextStyle(
                          color: dateError.isNotEmpty
                              ? Colors.red
                              : (expiredDate == null
                                    ? Colors.grey
                                    : Colors.black),
                          fontWeight: expiredDate == null
                              ? FontWeight.normal
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (dateError.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  dateError,
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
              ),

            if (expiredDate != null && dateError.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.green[700], size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Còn ${expiredDate!.difference(DateTime.now()).inDays} ngày',
                      style: TextStyle(fontSize: 12, color: Colors.green[700]),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            /// CREATE VOUCHER BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      (isCreatingVoucher ||
                          isLoadingPartners ||
                          partners.isEmpty ||
                          pointError.isNotEmpty ||
                          dateError.isNotEmpty ||
                          limitError.isNotEmpty)
                      ? Colors.grey
                      : Colors.green[700],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                onPressed:
                    (isCreatingVoucher ||
                        isLoadingPartners ||
                        partners.isEmpty ||
                        pointError.isNotEmpty ||
                        dateError.isNotEmpty ||
                        limitError.isNotEmpty)
                    ? null
                    : publishVoucher,
                child: isCreatingVoucher
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Đang tạo voucher...',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      )
                    : const Text(
                        'PHÁT HÀNH VOUCHER',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
  void dispose() {
    pointController.removeListener(_calculateDiscount);
    pointController.removeListener(_validatePoint);
    limitController.removeListener(_validateLimit);
    pointController.dispose();
    limitController.dispose();
    super.dispose();
  }
}
