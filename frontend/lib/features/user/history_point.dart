import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';

class HistoryPoint extends StatefulWidget {
  final String username;

  const HistoryPoint({super.key, required this.username});

  @override
  State<HistoryPoint> createState() => _HistoryPointState();
}

class _HistoryPointState extends State<HistoryPoint> {
  late Future<Map<String, dynamic>> _futureUser;

  @override
  void initState() {
    super.initState();
    _futureUser = ApiService.getUserByUsername(widget.username);
  }

  Icon getIcon(String? type) {
    switch (type) {
      case 'add':
        return const Icon(Icons.add_circle, color: Colors.green);
      case 'minus':
        return const Icon(Icons.remove_circle, color: Colors.orange);
      case 'reset':
        return const Icon(Icons.report_problem, color: Colors.red);
      default:
        return const Icon(Icons.info, color: Colors.blueGrey);
    }
  }

  Color getColor(String? type) {
    switch (type) {
      case 'add':
        return Colors.green.shade50;
      case 'minus':
        return Colors.orange.shade50;
      case 'reset':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade200;
    }
  }

  String formatPoint(int point, String? type) {
    if (type == 'reset') return 'Về 0';
    if (point > 0) return '+$point';
    return point.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử điểm'),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureUser,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Lỗi: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Không load được dữ liệu'));
          }

          final user = snapshot.data!;
          final List historyRaw = user['history'] ?? [];
          final int totalPoint = user['point'] is num
              ? (user['point'] as num).toInt()
              : 0;
          final List history = historyRaw.reversed.toList();

          if (history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Chưa có lịch sử tích điểm',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Tài khoản: ${user["username"]}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('TỔNG ĐIỂM HIỆN TẠI'),
                    Text(
                      '$totalPoint',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: history.length,
                  itemBuilder: (_, i) {
                    final h = history[i];
                    final String type = h['type'] ?? '';
                    final int p = h['point'] is num
                        ? (h['point'] as num).toInt()
                        : 0;

                    // 🔥 TỰ ĐỘNG ĐỔI THÔNG BÁO NẾU LÀ RESET
                    String message = h['message'] ?? 'Giao dịch điểm';
                    if (type == 'reset') {
                      message = "Hệ thống lỗi nên điểm quay về 0";
                    }

                    return Card(
                      color: getColor(type),
                      elevation: 1,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: getIcon(type),
                        title: Text(
                          message,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: type == 'reset'
                                ? Colors.red.shade900
                                : Colors.black,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (h['bill'] != null)
                              Text(
                                'Mã bill: ${h['bill']}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            Text(
                              h['time'] ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        trailing: Text(
                          formatPoint(p, type),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: type == 'reset'
                                ? Colors.red
                                : (p >= 0 ? Colors.green.shade700 : Colors.red),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
