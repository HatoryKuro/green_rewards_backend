import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ManagementPage extends StatelessWidget {
  const ManagementPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Management"), centerTitle: true),
      body: FutureBuilder(
        future: ApiService.getUsers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data as List;

          return ListView.builder(
            key: const ValueKey('user_list'),
            itemCount: users.length,
            itemBuilder: (_, i) {
              return ListTile(
                key: ValueKey('user_item_$i'),
                leading: const Icon(Icons.person),
                title: Text(users[i]["username"]),
                subtitle: Text(users[i]["role"]),
              );
            },
          );
        },
      ),
    );
  }
}
