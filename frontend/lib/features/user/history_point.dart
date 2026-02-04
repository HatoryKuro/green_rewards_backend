import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';

class HistoryPoint extends StatefulWidget {
  const HistoryPoint({super.key});

  @override
  State<HistoryPoint> createState() => _HistoryPointState();
}

class _HistoryPointState extends State<HistoryPoint> {
  late Future<Map<String, dynamic>> _futureUser;

  // 🔥 USERNAME HIỆN TẠI
  // GIỮ NGUYÊN theo yêu cầu (không refactor)
  final String username = 'admin';

  @override
  void initState() {
    super.initState();
    _futureUser = ApiService.getUserByUsername(username);
  }

  Icon getIcon(String? type) {
    switch (type) {
      case 'add':
        return const Icon(Icons.add_circle, color: Colors.green);
      case 'minus':
        return const Icon(Icons.remove_circle, color: Colors.orange);
      case 'reset':
        return const Icon(Icons.warning, color: Colors.red);
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

  String formatPoint(int point) {
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
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Không load được dữ liệu'));
          }

          final user = snapshot.data!;
          final List historyRaw = user['history'] ?? [];
          final int point = (user['point'] ?? 0) as int;

          // ✅ CHỐNG NULL + SORT MỚI → CŨ
          final List history = historyRaw.reversed.toList();

          if (history.isEmpty) {
            return const Center(child: Text('Chưa có lịch sử'));
          }

          return Column(
            children: [
              // ================= HEADER =================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.green.shade100,
                child: Column(
                  children: [
                    Text(
                      'User: ${user["username"]}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tổng điểm: $point',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // ================= HISTORY LIST =================
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: history.length,
                  itemBuilder: (_, i) {
                    final h = history[i];

                    final int p = h['point'] is num
                        ? (h['point'] as num).toInt()
                        : 0;

                    return Card(
                      color: getColor(h['type']),
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: getIcon(h['type']),
                        title: Text(
                          h['message'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          h['time'] ?? '',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Text(
                          formatPoint(p),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: p >= 0 ? Colors.green : Colors.red,
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
