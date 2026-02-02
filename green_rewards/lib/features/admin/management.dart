import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';

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

  /// =======================
  /// XOÁ USER (CÓ XÁC NHẬN)
  /// =======================
  Future<void> confirmDeleteUser(Map user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá user'),
        content: Text('Bạn có chắc muốn xoá user "${user["username"]}" không?'),
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

    if (ok == true) {
      /// TODO: gọi API xoá user khi backend có
      setState(() {
        _futureUsers = ApiService.getUsers();
      });
    }
  }

  /// =======================
  /// RESET ĐIỂM (CÓ XÁC NHẬN)
  /// =======================
  Future<void> confirmResetPoint(Map user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset điểm'),
        content: Text(
          'Bạn có chắc muốn reset toàn bộ điểm của "${user["username"]}" không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (ok == true) {
      /// TODO: gọi API reset point khi backend có
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã reset điểm cho ${user["username"]}'),
          backgroundColor: Colors.green,
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
        title: const Text(
          'Quản lý User',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: _futureUsers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
            return const Center(child: Text('Chưa có user'));
          }

          final users = snapshot.data as List;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            itemBuilder: (_, i) {
              final u = users[i];
              final point = u["point"] ?? 0;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    child: const Icon(Icons.person, color: Colors.green),
                  ),
                  title: Text(
                    u["username"],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(u["phone"] ?? ''),
                      const SizedBox(height: 6),
                      Text(
                        'Điểm: $point',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Role: ${u["role"]}',
                        style: TextStyle(
                          color: u["role"] == "admin"
                              ? Colors.red
                              : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// RESET ĐIỂM
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.orange),
                        onPressed: () => confirmResetPoint(u),
                      ),

                      /// XOÁ USER (KHÔNG CHO XOÁ ADMIN)
                      if (u["role"] != "admin")
                        IconButton(
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
