import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../user/history_point.dart';

class Management extends StatefulWidget {
  const Management({Key? key}) : super(key: key);

  @override
  State<Management> createState() => _ManagementState();
}

class _ManagementState extends State<Management> {
  late Future<List<dynamic>> _futureUsers;

  @override
  void initState() {
    super.initState();
    _futureUsers = ApiService.getUsers();
  }

  void reload() {
    setState(() {
      _futureUsers = ApiService.getUsers();
    });
  }

  /// =======================
  /// XOÁ USER
  /// =======================
  Future<void> confirmDeleteUser(Map user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá người dùng'),
        content: Text('Bạn có chắc muốn xoá tài khoản "${user["username"]}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final success = await ApiService.deleteUser(user["id"]);

    if (!mounted) return;

    if (success) {
      reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xoá người dùng thành công'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// =======================
  /// RESET POINT (GỌI API THẬT)
  /// =======================
  Future<void> confirmResetPoint(Map user) async {
    // 🔥 THÊM LOGIC CHẶN: Nếu điểm đã là 0 thì không hiện Dialog reset
    final int currentPoint = user["point"] ?? 0;
    if (currentPoint <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Người dùng này không có điểm để reset'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset điểm'),
        content: Text('Bạn muốn đưa điểm của "${user["username"]}" về 0?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    final success = await ApiService.resetPoint(user["id"]);

    if (!mounted) return;

    if (success) {
      reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã reset điểm cho ${user["username"]} thành công'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lỗi: Không thể reset điểm'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Danh sách người dùng'),
        centerTitle: true,
        actions: [
          // Đã loại bỏ nút Quét QR theo yêu cầu
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: reload,
            tooltip: 'Tải lại danh sách',
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futureUsers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Chưa có người dùng nào'));
          }

          final users = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            itemBuilder: (_, i) {
              final u = users[i];
              final int point = u["point"] ?? 0;
              final bool isAdmin = u["isAdmin"] == true || u["role"] == "admin";

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  onTap: isAdmin
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  HistoryPoint(username: u["username"]),
                            ),
                          );
                        },
                  leading: CircleAvatar(
                    backgroundColor: isAdmin
                        ? Colors.blue.shade100
                        : Colors.green.shade100,
                    child: Icon(
                      isAdmin ? Icons.admin_panel_settings : Icons.person,
                      color: isAdmin
                          ? Colors.blue.shade800
                          : Colors.green.shade800,
                    ),
                  ),
                  title: Text(
                    u["username"],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SĐT: ${u["phone"] ?? "Không có"}'),
                        if (!isAdmin)
                          Text(
                            'Điểm hiện tại: $point',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        Text(
                          'Quyền: ${isAdmin ? "Quản trị viên" : "Người dùng"}',
                          style: TextStyle(
                            color: isAdmin ? Colors.blue : Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: isAdmin
                      ? const Icon(
                          Icons.lock_outline,
                          color: Colors.grey,
                          size: 20,
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Reset điểm',
                              icon: Icon(
                                Icons.refresh,
                                // Hiển thị màu mờ hơn nếu điểm bằng 0
                                color: point > 0 ? Colors.orange : Colors.grey,
                              ),
                              onPressed: () => confirmResetPoint(u),
                            ),
                            IconButton(
                              tooltip: 'Xoá user',
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => confirmDeleteUser(u),
                            ),
                          ],
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
