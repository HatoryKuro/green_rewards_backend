import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../user/history_point.dart';

class Management extends StatefulWidget {
  const Management({Key? key}) : super(key: key);

  @override
  State<Management> createState() => _ManagementState();
}

class _ManagementState extends State<Management> {
  List<dynamic> users = [];
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final userList = await ApiService.getUsers();

      if (!mounted) return;

      // Kiểm tra dữ liệu trả về
      print('API trả về ${userList.length} users');
      if (userList.isNotEmpty) {
        print('User đầu tiên: ${userList[0]}');
      }

      setState(() {
        users = userList;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = e.toString();
      });

      print('Lỗi khi load users: $e');
    }
  }

  void reload() {
    _loadUsers();
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xoá người dùng thất bại'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// =======================
  /// RESET POINT (GỌI API THẬT)
  /// =======================
  Future<void> confirmResetPoint(Map user) async {
    final String userId = user["id"];
    final String username = user["username"] ?? "người dùng";
    final int currentPoint = (user["point"] is num)
        ? (user["point"] as num).toInt()
        : 0;

    // Kiểm tra nếu user là admin
    final bool isAdmin = user["isAdmin"] == true || user["role"] == "admin";
    if (isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể reset điểm của admin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 🔥 THÊM LOGIC CHẶN: Nếu điểm đã là 0 thì không hiện Dialog reset
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
        content: Text(
          'Bạn muốn đưa điểm của "$username" về 0?\nHiện tại: $currentPoint điểm',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset về 0'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await ApiService.resetPoint(userId);

      if (!mounted) return;
      Navigator.pop(context); // Đóng loading

      if (success) {
        reload();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã reset điểm cho $username thành công'),
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
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Đóng loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi reset điểm: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// =======================
  /// XÂY DỰNG GIAO DIỆN LOADING
  /// =======================
  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            'Đang tải danh sách người dùng...',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  /// =======================
  /// XÂY DỰNG GIAO DIỆN LỖI
  /// =======================
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 20),
            const Text(
              'Không thể tải danh sách người dùng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Lỗi: $errorMessage',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              onPressed: reload,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  /// =======================
  /// XÂY DỰNG GIAO DIỆN DANH SÁCH RỖNG
  /// =======================
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.group_off, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            'Chưa có người dùng nào',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Text(
            'Người dùng đăng ký sẽ hiển thị ở đây',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Tải lại'),
            onPressed: reload,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }

  /// =======================
  /// XÂY DỰNG GIAO DIỆN DANH SÁCH USER
  /// =======================
  Widget _buildUserList() {
    return Column(
      children: [
        // Thông tin tổng quan
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tổng số người dùng',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    '${users.length} người',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Người dùng thường',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    '${users.where((u) => u["isAdmin"] != true && u["role"] != "admin").length} người',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Danh sách user
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            itemCount: users.length,
            itemBuilder: (_, i) {
              final u = users[i];
              final int point = (u["point"] is num)
                  ? (u["point"] as num).toInt()
                  : 0;
              final bool isAdmin = u["isAdmin"] == true || u["role"] == "admin";
              final String username = u["username"] ?? "Không có tên";
              final String email = u["email"] ?? "Không có email";
              final String phone = u["phone"] ?? "Không có SĐT";

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
                              builder: (_) => HistoryPoint(username: username),
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
                      size: 24,
                    ),
                  ),
                  title: Text(
                    username,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isAdmin ? Colors.blue.shade800 : Colors.black,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Email: $email'),
                        Text('SĐT: $phone'),
                        if (!isAdmin)
                          Text(
                            'Điểm: $point',
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
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: const Text(
                            'ADMIN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Nút xem lịch sử
                            IconButton(
                              tooltip: 'Xem lịch sử điểm',
                              icon: const Icon(
                                Icons.history,
                                color: Colors.green,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        HistoryPoint(username: username),
                                  ),
                                );
                              },
                            ),
                            // Nút reset điểm
                            IconButton(
                              tooltip: point > 0
                                  ? 'Reset điểm'
                                  : 'Không có điểm để reset',
                              icon: Icon(
                                Icons.refresh,
                                color: point > 0 ? Colors.orange : Colors.grey,
                              ),
                              onPressed: point > 0
                                  ? () => confirmResetPoint(u)
                                  : null,
                            ),
                            // Nút xoá user
                            IconButton(
                              tooltip: 'Xoá user',
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => confirmDeleteUser(u),
                            ),
                          ],
                        ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Quản lý người dùng'),
        centerTitle: true,
      ),
      body: isLoading
          ? _buildLoading()
          : hasError
          ? _buildError()
          : users.isEmpty
          ? _buildEmpty()
          : _buildUserList(),
      // Floating Action Button để thêm user (nếu cần)
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: reload,
        tooltip: 'Tải lại',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
