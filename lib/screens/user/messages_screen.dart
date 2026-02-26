import 'package:flutter/material.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Tin nhắn', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Màn hình Tin nhắn',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }
}
