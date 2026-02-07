import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // THÊM DÒNG NÀY
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
  bool isCurrentAdmin = false;
  bool isCurrentManager = false;
  String currentRole = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserInfo();
    _loadUsers();
  }

  Future<void> _loadCurrentUserInfo() async {
    try {
      final role = await UserPreferences.getRole();
      setState(() {
        currentRole = role;
        isCurrentAdmin = role == 'admin';
        isCurrentManager = role == 'admin' || role == 'manager';
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
    final String userRole = user["role"] ?? "user";

    // 🔥 PHÂN QUYỀN XOÁ
    if (userRole == "admin") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể xóa tài khoản admin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Manager không thể xóa manager khác
    if (userRole == "manager" && !isCurrentAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Manager không thể xóa manager khác'),
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

    // Không cho phép thay đổi role của admin
    if (currentRole == "admin") {
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
          'Bạn có chắc muốn thay đổi quyền của "$username" thành $newRoleName?',
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
    final String userRole = user["role"] ?? "user";

    // Kiểm tra nếu user là admin
    if (userRole == "admin") {
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
          'Bạn muốn đưa điểm của "$username" về 0?\nHiện tại: $currentPoint điểm\n\nLý do: Hệ thống lỗi nên điểm trả về 0',
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
      // Lấy thông tin người đang đăng nhập
      final prefs = await SharedPreferences.getInstance();
      final currentUsername = prefs.getString('username') ?? 'system';

      // GỌI API VỚI THAM SỐ RESET_BY
      final success = await ApiService.resetPoint(
        userId,
        resetBy: currentUsername,
      );

      if (!mounted) return;
      Navigator.pop(context); // Đóng loading

      if (success) {
        reload();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã reset $currentPoint điểm cho $username thành công',
            ),
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
  /// LẤY DANH SÁCH CÁC NÚT CHỨC NĂNG
  /// =======================
  List<Widget> _getActionButtons(Map user) {
    final String userRole = user["role"] ?? "user";
    final int point = (user["point"] is num)
        ? (user["point"] as num).toInt()
        : 0;
    final String username = user["username"] ?? "";

    List<Widget> buttons = [];

    // Nút xem lịch sử (cho tất cả user không phải admin)
    if (userRole != "admin") {
      buttons.add(
        IconButton(
          icon: const Icon(Icons.history, size: 22),
          color: Colors.green,
          tooltip: 'Xem lịch sử điểm',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HistoryPoint(username: username),
              ),
            );
          },
        ),
      );
    }

    // Nút reset điểm (chỉ cho user thường, không dành cho admin/manager)
    if (userRole == "user" && point > 0) {
      buttons.add(
        IconButton(
          icon: const Icon(Icons.refresh, size: 22),
          color: Colors.orange,
          tooltip: 'Reset điểm về 0',
          onPressed: () => confirmResetPoint(user),
        ),
      );
    }

    // Nút thay đổi role (CHỈ ADMIN mới thấy và chỉ cho user thường/manager)
    if (isCurrentAdmin && userRole != "admin") {
      buttons.add(
        IconButton(
          icon: Icon(
            userRole == "user" ? Icons.arrow_upward : Icons.arrow_downward,
            size: 22,
          ),
          color: Colors.blue,
          tooltip: userRole == "user" ? 'Nâng lên quản lý' : 'Hạ xuống user',
          onPressed: () => confirmChangeRole(user),
        ),
      );
    }

    // Nút xoá user
    bool canDelete = false;

    if (isCurrentAdmin && userRole != "admin") {
      // Admin có thể xoá manager và user
      canDelete = true;
    } else if (currentRole == "manager" && userRole == "user") {
      // Manager chỉ có thể xoá user thường
      canDelete = true;
    }

    if (canDelete) {
      buttons.add(
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 22),
          color: Colors.red,
          tooltip: 'Xoá người dùng',
          onPressed: () => confirmDeleteUser(user),
        ),
      );
    }

    return buttons;
  }

  /// =======================
  /// HIỂN THỊ BADGE THEO ROLE
  /// =======================
  Widget _buildRoleBadge(Map user) {
    final String userRole = user["role"] ?? "user";

    String roleText = 'USER';
    Color color = Colors.green;

    if (userRole == "admin") {
      roleText = 'ADMIN';
      color = Colors.red;
    } else if (userRole == "manager") {
      roleText = 'MANAGER';
      color = Colors.blue;
    }

    return Chip(
      label: Text(
        roleText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
        .where((u) => (u["role"] ?? "user") == "admin")
        .length;
    final managerCount = users
        .where((u) => (u["role"] ?? "user") == "manager")
        .length;
    final userCount = totalUsers - adminCount - managerCount;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TỔNG QUAN',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Row(
                children: [
                  Text(
                    '$totalUsers người dùng',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Admin', '$adminCount', Colors.red),
              _buildStatItem('Manager', '$managerCount', Colors.blue),
              _buildStatItem('User', '$userCount', Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: users.length,
            itemBuilder: (_, i) {
              final u = users[i];
              final int point = (u["point"] is num)
                  ? (u["point"] as num).toInt()
                  : 0;
              final String userRole = u["role"] ?? "user";
              final String username = u["username"] ?? "Không có tên";
              final String email = u["email"] ?? "Không có email";
              final String phone = u["phone"] ?? "Không có SĐT";

              Color borderColor;
              if (userRole == "admin") {
                borderColor = Colors.red.shade200;
              } else if (userRole == "manager") {
                borderColor = Colors.blue.shade200;
              } else {
                borderColor = Colors.grey.shade200;
              }

              final actionButtons = _getActionButtons(u);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: borderColor, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: userRole == "admin"
                                ? Colors.red.shade100
                                : userRole == "manager"
                                ? Colors.blue.shade100
                                : Colors.green.shade100,
                            radius: 20,
                            child: Icon(
                              userRole == "admin"
                                  ? Icons.admin_panel_settings
                                  : userRole == "manager"
                                  ? Icons.supervisor_account
                                  : Icons.person,
                              color: userRole == "admin"
                                  ? Colors.red.shade800
                                  : userRole == "manager"
                                  ? Colors.blue.shade800
                                  : Colors.green.shade800,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        username,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    _buildRoleBadge(u),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  email,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'SĐT: $phone',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Hiển thị điểm cho user thường
                      if (userRole == "user" && point > 0)
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.green.shade700,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$point điểm',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Các button chức năng (chỉ icon)
                      if (actionButtons.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: actionButtons,
                          ),
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
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        title: Text(
          isCurrentAdmin
              ? 'Quản lý người dùng (Admin)'
              : 'Quản lý người dùng (Manager)',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 22),
            onPressed: reload,
            tooltip: 'Tải lại',
            color: Colors.green,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? _buildLoading()
          : hasError
          ? _buildError()
          : users.isEmpty
          ? _buildEmpty()
          : _buildUserList(),
    );
  }
}
