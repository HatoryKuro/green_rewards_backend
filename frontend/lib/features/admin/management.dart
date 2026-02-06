import 'package:flutter/material.dart';
import 'package:green_rewards/core/services/api_service.dart';
import 'package:green_rewards/core/services/user_preferences.dart';
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
  Map<String, dynamic> currentUser = {};
  bool isCurrentAdmin = false;
  bool isCurrentManager = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserInfo();
    _loadUsers();
  }

  Future<void> _loadCurrentUserInfo() async {
    try {
      final isAdmin = await UserPreferences.isAdmin();
      final role = await UserPreferences.getRole();

      setState(() {
        isCurrentAdmin = isAdmin;
        isCurrentManager = role == 'manager' || role == 'admin';
      });
    } catch (e) {
      print('Lỗi khi load thông tin user hiện tại: $e');
    }
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
  /// XOÁ USER (VỚI PHÂN QUYỀN)
  /// =======================
  Future<void> confirmDeleteUser(Map user) async {
    final String userId = user["id"];
    final String username = user["username"] ?? "người dùng";
    final bool isUserAdmin = user["isAdmin"] == true || user["role"] == "admin";
    final bool isUserManager =
        user["isManager"] == true || user["role"] == "manager";

    // 🔥 PHÂN QUYỀN XOÁ
    if (isUserAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể xóa tài khoản admin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Manager không thể xóa manager khác
    if (isUserManager && !isCurrentAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chỉ admin mới có thể xóa quản lý'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá người dùng'),
        content: Text('Bạn có chắc muốn xoá tài khoản "$username"?'),
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

    final success = await ApiService.deleteUser(userId);

    if (!mounted) return;

    if (success) {
      reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xoá người dùng "$username" thành công'),
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
  /// NÂNG/HẠ ROLE (CHỈ ADMIN)
  /// =======================
  Future<void> confirmChangeRole(Map user) async {
    final String userId = user["id"];
    final String username = user["username"] ?? "người dùng";
    final String currentRole = user["role"] ?? "user";
    final bool isUserAdmin = user["isAdmin"] == true || user["role"] == "admin";

    // Chỉ admin mới có quyền này
    if (!isCurrentAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chỉ admin mới có quyền thay đổi role'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Không cho phép thay đổi role của admin khác
    if (isUserAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể thay đổi role của admin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Xác định role mới
    String newRole = currentRole == "user" ? "manager" : "user";
    String newRoleName = newRole == "manager" ? "Quản lý" : "Người dùng";

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Thay đổi quyền'),
        content: Text(
          'Bạn có chắc muốn thay đổi quyền của "$username" '
          'từ ${currentRole == "user" ? "Người dùng" : "Quản lý"} '
          'thành $newRoleName?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await ApiService.updateUserRole(
        userId: userId,
        newRole: newRole,
      );

      if (!mounted) return;
      Navigator.pop(context); // Đóng loading

      // Kiểm tra kết quả từ API (Map trả về)
      if (result["success"] == true) {
        reload();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã thay đổi role của "$username" thành $newRoleName',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thay đổi role thất bại'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Đóng loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi thay đổi role: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// =======================
  /// RESET POINT (VỚI PHÂN QUYỀN)
  /// =======================
  Future<void> confirmResetPoint(Map user) async {
    final String userId = user["id"];
    final String username = user["username"] ?? "người dùng";
    final int currentPoint = (user["point"] is num)
        ? (user["point"] as num).toInt()
        : 0;

    // Kiểm tra nếu user là admin
    final bool isUserAdmin = user["isAdmin"] == true || user["role"] == "admin";
    if (isUserAdmin) {
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
  /// HIỂN THỊ BADGE THEO ROLE
  /// =======================
  Widget _buildRoleBadge(Map user) {
    final bool isUserAdmin = user["isAdmin"] == true || user["role"] == "admin";
    final bool isUserManager =
        user["isManager"] == true || user["role"] == "manager";

    if (isUserAdmin) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: const Text(
          'ADMIN',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
      );
    } else if (isUserManager) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: const Text(
          'QUẢN LÝ',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: const Text(
          'USER',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      );
    }
  }

  /// =======================
  /// HIỂN THỊ CÁC NÚT CHỨC NĂNG THEO QUYỀN
  /// =======================
  Widget _buildActionButtons(Map user) {
    final bool isUserAdmin = user["isAdmin"] == true || user["role"] == "admin";
    final bool isUserManager =
        user["isManager"] == true || user["role"] == "manager";
    final int point = (user["point"] is num)
        ? (user["point"] as num).toInt()
        : 0;
    final String username = user["username"] ?? "";

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Nút xem lịch sử (cho tất cả user không phải admin)
        if (!isUserAdmin)
          IconButton(
            tooltip: 'Xem lịch sử điểm',
            icon: const Icon(Icons.history, color: Colors.green),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HistoryPoint(username: username),
                ),
              );
            },
          ),

        // Nút reset điểm (chỉ cho user thường, không dành cho admin/manager)
        if (!isUserAdmin && !isUserManager && point > 0)
          IconButton(
            tooltip: 'Reset điểm',
            icon: Icon(
              Icons.refresh,
              color: point > 0 ? Colors.orange : Colors.grey,
            ),
            onPressed: point > 0 ? () => confirmResetPoint(user) : null,
          ),

        // Nút thay đổi role (CHỈ ADMIN mới thấy và chỉ cho user thường/manager)
        if (isCurrentAdmin && !isUserAdmin)
          IconButton(
            tooltip: user["role"] == "user"
                ? 'Nâng lên quản lý'
                : 'Hạ xuống user',
            icon: Icon(
              user["role"] == "user"
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              color: Colors.blue,
            ),
            onPressed: () => confirmChangeRole(user),
          ),

        // Nút xoá user (Admin có thể xoá manager và user, Manager chỉ có thể xoá user)
        if ((isCurrentAdmin && !isUserAdmin) ||
            (isCurrentManager &&
                !isCurrentAdmin &&
                !isUserAdmin &&
                !isUserManager))
          IconButton(
            tooltip: 'Xoá user',
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => confirmDeleteUser(user),
          ),
      ],
    );
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
  /// XÂY DỰNG THỐNG KÊ
  /// =======================
  Widget _buildStats() {
    final totalUsers = users.length;
    final adminCount = users
        .where((u) => u["isAdmin"] == true || u["role"] == "admin")
        .length;
    final managerCount = users
        .where(
          (u) =>
              (u["isManager"] == true || u["role"] == "manager") &&
              !(u["isAdmin"] == true || u["role"] == "admin"),
        )
        .length;
    final userCount = totalUsers - adminCount - managerCount;

    return Container(
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
                '$totalUsers người',
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
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    color: Colors.red,
                    margin: const EdgeInsets.only(right: 4),
                  ),
                  Text('Admin: $adminCount'),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    color: Colors.blue,
                    margin: const EdgeInsets.only(right: 4),
                  ),
                  Text('Quản lý: $managerCount'),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    color: Colors.green,
                    margin: const EdgeInsets.only(right: 4),
                  ),
                  Text('User: $userCount'),
                ],
              ),
            ],
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
        _buildStats(),

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
              final bool isUserAdmin =
                  u["isAdmin"] == true || u["role"] == "admin";
              final bool isUserManager =
                  u["isManager"] == true || u["role"] == "manager";
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
                  onTap: isUserAdmin
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
                    backgroundColor: isUserAdmin
                        ? Colors.red.shade100
                        : isUserManager
                        ? Colors.blue.shade100
                        : Colors.green.shade100,
                    child: Icon(
                      isUserAdmin
                          ? Icons.admin_panel_settings
                          : isUserManager
                          ? Icons.supervisor_account
                          : Icons.person,
                      color: isUserAdmin
                          ? Colors.red.shade800
                          : isUserManager
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
                      color: isUserAdmin
                          ? Colors.red.shade800
                          : isUserManager
                          ? Colors.blue.shade800
                          : Colors.black,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Email: $email'),
                        Text('SĐT: $phone'),
                        if (!isUserAdmin && !isUserManager)
                          Text(
                            'Điểm: $point',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        const SizedBox(height: 4),
                        _buildRoleBadge(u),
                      ],
                    ),
                  ),
                  trailing: _buildActionButtons(u),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: reload,
        tooltip: 'Tải lại',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
