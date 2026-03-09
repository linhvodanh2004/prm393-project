import 'package:flutter/material.dart';
import '../../widgets/common/notification_badge_icon.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Khám phá', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        centerTitle: true,
        actions: const [NotificationBadgeIcon()],
      ),
      body: const Center(
        child: Text(
          'Màn hình Khám phá',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }
}
