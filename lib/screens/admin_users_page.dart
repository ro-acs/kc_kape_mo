import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUsersPage extends StatelessWidget {
  const AdminUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Accounts"),
        backgroundColor: Colors.brown,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          if (users.isEmpty) {
            return const Center(child: Text("No users found."));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (_, index) {
              final data = users[index].data() as Map<String, dynamic>;
              final fullName = data['full_name'] ?? 'Unnamed User';
              final email = data['email'] ?? 'No email';
              final role = data['role'] ?? 'client';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.brown,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(fullName),
                  subtitle: Text(email),
                  trailing: Chip(
                    label: Text(
                      role,
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor:
                        role == 'admin' ? Colors.red : Colors.brown,
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
