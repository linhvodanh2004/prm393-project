import 'package:flutter/material.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM HH:mm').format(date);
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'booking':
        return Icons.event_note;
      case 'host_request':
        return Icons.admin_panel_settings;
      case 'chat':
        return Icons.chat;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'booking':
        return Colors.blueAccent;
      case 'host_request':
        return Colors.purpleAccent;
      case 'chat':
        return Colors.greenAccent;
      default:
        return const Color(0xFFD4A853);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Thông báo', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Colors.white54),
            tooltip: 'Đánh dấu đã đọc tất cả',
            onPressed: () {
              _notificationService.markAllAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã đánh dấu đọc tất cả')),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationService.getUserNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4A853)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Lỗi tải thông báo: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 64,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có thông báo nào',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (ctx, idx) =>
                const Divider(color: Colors.white12, height: 1),
            itemBuilder: (context, index) {
              final notif = notifications[index];

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                tileColor: notif.isRead
                    ? Colors.transparent
                    : const Color(0xFFD4A853).withOpacity(0.05),
                leading: CircleAvatar(
                  backgroundColor: _getColorForType(
                    notif.type,
                  ).withOpacity(0.2),
                  child: Icon(
                    _getIconForType(notif.type),
                    color: _getColorForType(notif.type),
                  ),
                ),
                title: Text(
                  notif.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: notif.isRead
                        ? FontWeight.normal
                        : FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      notif.body,
                      style: TextStyle(
                        color: notif.isRead ? Colors.white54 : Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(notif.createdAt),
                      style: const TextStyle(
                        color: Colors.white30,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  if (!notif.isRead) {
                    _notificationService.markAsRead(notif.id);
                  }
                  // Further routing based on type could be added here
                },
              );
            },
          );
        },
      ),
    );
  }
}
