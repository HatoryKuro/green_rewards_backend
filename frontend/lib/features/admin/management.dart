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
        title: const Text('Xoá user'),
        content: Text('Bạn có chắc muốn xoá "${user["username"]}" không?'),
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

    if (!mounted) return; // 🔥 FIX CRASH

    if (success) {
      reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xoá user'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xoá thất bại'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// =======================
  /// RESET POINT
  /// =======================
  Future<void> confirmResetPoint(Map user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset điểm'),
        content: Text('Reset điểm của "${user["username"]}"?'),
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

    if (ok != true || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã reset điểm cho ${user["username"]}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Quản lý User'),
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
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(u["username"]),
                  subtitle: Text(
                    'Phone: ${u["phone"]}\nĐiểm: $point\nRole: ${u["role"]}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.orange),
                        onPressed: () => confirmResetPoint(u),
                      ),
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
