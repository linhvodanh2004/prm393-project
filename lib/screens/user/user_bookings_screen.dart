import 'package:flutter/material.dart';

class UserBookingsScreen extends StatelessWidget {
  const UserBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Booking của tôi', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Màn hình Booking của tôi',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }
}
