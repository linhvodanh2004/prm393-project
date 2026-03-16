import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/chat_model.dart';
import '../../services/chat_service.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _chatService = ChatService();
  late final String _currentId;

  @override
  void initState() {
    super.initState();
    // Read uid in initState to avoid race condition at field-declaration time
    _currentId = FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  String _getOtherUserId(ChatRoomModel room) {
    return room.participants.firstWhere(
      (id) => id != _currentId,
      orElse: () => '',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentId.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D0D),
        body: Center(
          child: Text(
            'Vui lòng đăng nhập',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Tin nhắn', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<ChatRoomModel>>(
        stream: _chatService.getUserChatRooms(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4A853)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Lỗi tải tin nhắn: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final rooms = snapshot.data ?? [];

          if (rooms.isEmpty) {
            return const Center(
              child: Text(
                'Bạn chưa có tin nhắn nào',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            );
          }

          return ListView.separated(
            itemCount: rooms.length,
            separatorBuilder: (ctx, idx) =>
                const Divider(color: Colors.white12, height: 1),
            itemBuilder: (context, index) {
              final room = rooms[index];
              final targetId = _getOtherUserId(room);
              if (targetId.isEmpty) return const SizedBox();

              final targetName =
                  room.participantNames[targetId] ?? 'Người dùng';
              final targetAvatar = room.participantAvatars[targetId];
              final unreadCount = room.unreadCounts[_currentId] ?? 0;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF2A2A2A),
                  backgroundImage:
                      targetAvatar != null && targetAvatar.isNotEmpty
                      ? NetworkImage(targetAvatar)
                      : null,
                  child: targetAvatar == null || targetAvatar.isEmpty
                      ? const Icon(Icons.person, color: Colors.white54)
                      : null,
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        targetName,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: unreadCount > 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    room.lastMessage,
                    style: TextStyle(
                      color: unreadCount > 0 ? Colors.white : Colors.white54,
                      fontWeight: unreadCount > 0
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                onTap: () {
                  // Mark as read immediately when tapped
                  if (unreadCount > 0) {
                    _chatService.markRoomAsRead(room.id);
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatDetailScreen(
                        roomId: room.id,
                        targetId: targetId,
                        targetName: targetName,
                        targetAvatar: targetAvatar,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
