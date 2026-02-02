import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ManagementPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("User Management")),
      body: FutureBuilder(
        future: ApiService.getUsers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          final users = snapshot.data as List;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(users[i]["username"]),
              subtitle: Text(users[i]["role"]),
            ),
          );
        },
      ),
    );
  }
}
