import 'package:flutter/material.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Quản lý User', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Màn hình Quản lý User',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }
}
