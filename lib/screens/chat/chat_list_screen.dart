import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import '../../services/chat_service.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _chatService = ChatService();
  final _db = FirebaseFirestore.instance;
  late final String _currentId;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Read uid in initState to avoid race condition at field-declaration time
    _currentId = FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _getOtherUserId(ChatRoomModel room) {
    return room.participants.firstWhere(
      (id) => id != _currentId,
      orElse: () => '',
    );
  }

  Future<UserModel?> _getCurrentUserModel() async {
    if (_currentId.isEmpty) return null;
    final doc = await _db.collection('users').doc(_currentId).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  bool _matchesUser(UserModel u, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final name = u.name.toLowerCase();
    final email = u.email.toLowerCase();
    final phone = (u.phoneNumber ?? '').toLowerCase();
    return name.contains(q) || email.contains(q) || phone.contains(q);
  }

  Future<void> _openChatWithUser(UserModel target, UserModel? me) async {
    if (_currentId.isEmpty) return;

    final currentName = (me?.name ??
            FirebaseAuth.instance.currentUser?.displayName ??
            FirebaseAuth.instance.currentUser?.email ??
            'Người dùng')
        .trim();
    final currentAvatar =
        (me?.photoURL ?? FirebaseAuth.instance.currentUser?.photoURL ?? '')
            .trim();

    final targetName = target.name;
    final targetAvatar = (target.photoURL ?? '').trim();

    try {
      final roomId = await _chatService.createOrGetRoom(
        target.uid,
        targetName,
        targetAvatar,
        currentName,
        currentAvatar,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailScreen(
            roomId: roomId,
            targetId: target.uid,
            targetName: targetName,
            targetAvatar: targetAvatar,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể mở chat: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<UserModel?>(
        future: _getCurrentUserModel(),
        builder: (context, meSnap) {
          final me = meSnap.data;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Tìm người dùng theo tên, email, SĐT...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon:
                        const Icon(Icons.search, color: Colors.white38),
                    suffixIcon: _searchQuery.trim().isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                            icon: const Icon(Icons.close,
                                color: Colors.white38),
                          ),
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _searchQuery.trim().isNotEmpty
                    ? StreamBuilder<QuerySnapshot>(
                        stream: _db.collection('users').snapshots(),
                        builder: (context, snap) {
                          if (snap.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFFD4A853)),
                            );
                          }
                          if (snap.hasError) {
                            return Center(
                              child: Text(
                                'Lỗi tải danh sách người dùng: ${snap.error}',
                                style: const TextStyle(color: Colors.red),
                              ),
                            );
                          }

                          var users = (snap.data?.docs ?? [])
                              .map((d) => UserModel.fromMap(
                                  d.id, d.data() as Map<String, dynamic>))
                              .where((u) => u.uid != _currentId)
                              .where((u) => _matchesUser(u, _searchQuery))
                              .toList();

                          users.sort((a, b) => a.name.compareTo(b.name));

                          if (users.isEmpty) {
                            return const Center(
                              child: Text(
                                'Không tìm thấy người dùng',
                                style: TextStyle(color: Colors.white38),
                              ),
                            );
                          }

                          return ListView.separated(
                            itemCount: users.length,
                            separatorBuilder: (_, __) => const Divider(
                                color: Colors.white12, height: 1),
                            itemBuilder: (context, index) {
                              final u = users[index];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  radius: 22,
                                  backgroundColor: const Color(0xFF2A2A2A),
                                  backgroundImage: u.photoURL != null &&
                                          u.photoURL!.isNotEmpty
                                      ? NetworkImage(u.photoURL!)
                                      : null,
                                  child: u.photoURL == null ||
                                          u.photoURL!.isEmpty
                                      ? const Icon(Icons.person,
                                          color: Colors.white54)
                                      : null,
                                ),
                                title: Text(
                                  u.name,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 16),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  [
                                    if (u.email.isNotEmpty) u.email,
                                    if ((u.phoneNumber ?? '').isNotEmpty)
                                      u.phoneNumber!,
                                  ].join(' • '),
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: const Icon(Icons.chevron_right,
                                    color: Colors.white38),
                                onTap: () => _openChatWithUser(u, me),
                              );
                            },
                          );
                        },
                      )
                    : StreamBuilder<List<ChatRoomModel>>(
                        stream: _chatService.getUserChatRooms(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFFD4A853)),
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
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 16),
                              ),
                            );
                          }

                          return ListView.separated(
                            itemCount: rooms.length,
                            separatorBuilder: (ctx, idx) => const Divider(
                                color: Colors.white12, height: 1),
                            itemBuilder: (context, index) {
                              final room = rooms[index];
                              final targetId = _getOtherUserId(room);
                              if (targetId.isEmpty) return const SizedBox();

                              final targetName =
                                  room.participantNames[targetId] ??
                                      'Người dùng';
                              final targetAvatar =
                                  room.participantAvatars[targetId];
                              final unreadCount =
                                  room.unreadCounts[_currentId] ?? 0;

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: const Color(0xFF2A2A2A),
                                  backgroundImage: targetAvatar != null &&
                                          targetAvatar.isNotEmpty
                                      ? NetworkImage(targetAvatar)
                                      : null,
                                  child: targetAvatar == null ||
                                          targetAvatar.isEmpty
                                      ? const Icon(Icons.person,
                                          color: Colors.white54)
                                      : null,
                                ),
                                title: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                  padding:
                                      const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    room.lastMessage,
                                    style: TextStyle(
                                      color: unreadCount > 0
                                          ? Colors.white
                                          : Colors.white54,
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
                                      builder: (context) =>
                                          ChatDetailScreen(
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
              ),
            ],
          );
        },
      ),
    );
  }
}
