import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';

class HistoryPoint extends StatefulWidget {
  final String username;

  const HistoryPoint({super.key, required this.username});

  @override
  State<HistoryPoint> createState() => _HistoryPointState();
}

class _HistoryPointState extends State<HistoryPoint> {
  Map<String, dynamic>? userData;
  List<dynamic> _combinedHistory = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final userFuture = ApiService.getUserByUsername(widget.username);
      final vouchersFuture = ApiService.getUserVouchers(widget.username);

      final results = await Future.wait([userFuture, vouchersFuture]);
      final user = results[0] as Map<String, dynamic>?;
      final vouchers = results[1] as List<dynamic>;

      List<dynamic> allHistory = [];

      if (user != null && user['history'] != null) {
        allHistory.addAll(List.from(user['history']));
      }

      for (var voucher in vouchers) {
        if (voucher['exchanged_at'] != null) {
          int point = voucher['point'] ?? 0;
          String partner = voucher['partner'] ?? 'Đối tác';
          String exchangedAt = voucher['exchanged_at'];
          allHistory.add({
            'type': 'exchange',
            'point': -point,
            'partner': partner,
            'time': exchangedAt,
            'message': 'Đổi voucher $partner',
          });
        }
      }

      allHistory.sort((a, b) {
        DateTime timeA = _parseDateTime(a['time'] ?? '');
        DateTime timeB = _parseDateTime(b['time'] ?? '');
        return timeB.compareTo(timeA);
      });

      setState(() {
        userData = user;
        _combinedHistory = allHistory;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print('Error loading history: $e');
    }
  }

  DateTime _parseDateTime(String timeStr) {
    try {
      return DateTime.parse(timeStr);
    } catch (e) {
      return DateTime.now();
    }
  }

  // Helper lấy type viết thường
  String? _normalizedType(Map<String, dynamic> item) {
    return item['type']?.toString().toLowerCase();
  }

  Icon getIcon(Map<String, dynamic> item) {
    final type = _normalizedType(item);
    switch (type) {
      case 'add':
        return const Icon(Icons.add_circle, color: Colors.green);
      case 'exchange':
        return const Icon(Icons.card_giftcard, color: Colors.purple);
      case 'reset':
        return const Icon(Icons.report_problem, color: Colors.red);
      case 'minus':
        return const Icon(Icons.remove_circle, color: Colors.orange);
      default:
        return const Icon(Icons.info, color: Colors.blueGrey);
    }
  }

  Color getColor(Map<String, dynamic> item) {
    final type = _normalizedType(item);
    switch (type) {
      case 'add':
        return Colors.green.shade50;
      case 'exchange':
        return Colors.purple.shade50;
      case 'reset':
        return Colors.red.shade50;
      case 'minus':
        return Colors.orange.shade50;
      default:
        return Colors.grey.shade200;
    }
  }

  Color getTextColor(Map<String, dynamic> item) {
    final type = _normalizedType(item);
    switch (type) {
      case 'add':
        return Colors.green.shade900;
      case 'exchange':
        return Colors.purple.shade900;
      case 'reset':
        return Colors.red.shade900;
      case 'minus':
        return Colors.orange.shade900;
      default:
        return Colors.black;
    }
  }

  String formatPoint(int point, Map<String, dynamic> item) {
    final type = _normalizedType(item);
    if (type == 'reset') return 'Về 0';
    if (point > 0) return '+$point';
    return '$point';
  }

  String getTypeTitle(Map<String, dynamic> item) {
    final type = _normalizedType(item);
    switch (type) {
      case 'add':
        return 'TÍCH ĐIỂM';
      case 'exchange':
        return 'ĐỔI VOUCHER';
      case 'reset':
        return 'RESET ĐIỂM';
      case 'minus':
        return 'TRỪ ĐIỂM';
      default:
        return 'GIAO DỊCH';
    }
  }

  String formatMessage(Map<String, dynamic> history) {
    final type = _normalizedType(history);
    final message = history['message'] ?? '';
    final partner = history['partner'] ?? '';
    final resetBy = history['reset_by'] ?? '';
    final oldPoint = history['old_point'] ?? 0;
    final newPoint = history['new_point'] ?? 0;

    if (type == 'reset') {
      if (resetBy.isNotEmpty) {
        return 'Đã reset $oldPoint điểm về 0 (bởi $resetBy) - Lý do: $message';
      }
      return 'Đã reset $oldPoint điểm về 0 - Lý do: $message';
    } else if (type == 'add' && partner.isNotEmpty) {
      return 'Tích điểm từ $partner';
    } else if (type == 'exchange' && partner.isNotEmpty) {
      return 'Đổi voucher $partner';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử điểm'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData == null && _combinedHistory.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Không thể tải lịch sử',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _loadData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            )
          : _buildHistoryContent(),
    );
  }

  Widget _buildHistoryContent() {
    final totalPoint = userData != null && userData!['point'] is num
        ? (userData!['point'] as num).toInt()
        : 0;

    if (_combinedHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history_toggle_off, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              'Chưa có lịch sử giao dịch',
              style: TextStyle(color: Colors.grey, fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              'Bắt đầu tích điểm bằng cách quét QR tại các đối tác',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Lọc lịch sử: exchange (đổi voucher) và không phải exchange (đổi điểm)
    final exchangeHistory = _combinedHistory.where((h) {
      final type = h['type']?.toString().toLowerCase();
      return type == 'exchange';
    }).toList();

    final nonExchangeHistory = _combinedHistory.where((h) {
      final type = h['type']?.toString().toLowerCase();
      return type != 'exchange';
    }).toList();

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.green.shade700, Colors.green.shade400],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(25),
            ),
          ),
          child: Column(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: 40,
                child: Icon(
                  Icons.person,
                  size: 50,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.username,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'TỔNG ĐIỂM HIỆN TẠI',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                '$totalPoint điểm',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: DefaultTabController(
            length: 2, // Chỉ còn 2 tab
            child: Column(
              children: [
                Container(
                  color: Colors.green.shade50,
                  child: const TabBar(
                    labelColor: Colors.green,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.green,
                    tabs: [
                      Tab(text: 'ĐỔI ĐIỂM'), // Tab đầu tiên đổi tên
                      Tab(text: 'ĐỔI VOUCHER'), // Giữ nguyên
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Tab "Đổi điểm" hiển thị tất cả giao dịch không phải exchange
                      _buildHistoryList(nonExchangeHistory, 'Lịch sử đổi điểm'),
                      // Tab "Đổi voucher" chỉ hiển thị exchange
                      _buildHistoryList(exchangeHistory, 'Lịch sử đổi voucher'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList(List history, String title) {
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.list_alt, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Chưa có $title',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (_, index) {
        final h = history[index];
        final int p = h['point'] is num ? (h['point'] as num).toInt() : 0;
        final partner = h['partner'] ?? '';
        final billCode = h['bill'] ?? '';
        final time = h['time'] ?? '';
        final resetBy = h['reset_by'] ?? '';
        final oldPoint = h['old_point'] ?? 0;
        final newPoint = h['new_point'] ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: getColor(h),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.green.shade100, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: getColor(h).withOpacity(0.8),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                child: Row(
                  children: [
                    getIcon(h),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        getTypeTitle(h),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: getTextColor(h),
                        ),
                      ),
                    ),
                    Text(
                      formatPoint(p, h),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: p >= 0 ? Colors.green.shade700 : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (partner.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.store,
                              size: 16,
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Đối tác: $partner',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (billCode.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.receipt,
                              size: 16,
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Mã hóa đơn: $billCode',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),

                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            time,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (h['message'] != null && h['message'].isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          formatMessage(h),
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),

                    if (_normalizedType(h) == 'reset')
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (resetBy.isNotEmpty)
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Bởi: $resetBy',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            Text(
                              'Điểm cũ: $oldPoint → Điểm mới: $newPoint',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
