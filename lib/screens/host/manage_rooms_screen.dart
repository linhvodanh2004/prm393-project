import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/room_model.dart';
import '../../services/room_service.dart';
import 'edit_room_screen.dart'; // We will create this next
import '../../widgets/common/notification_badge_icon.dart';

class ManageRoomsScreen extends StatefulWidget {
  const ManageRoomsScreen({super.key});

  @override
  State<ManageRoomsScreen> createState() => _ManageRoomsScreenState();
}

class _ManageRoomsScreenState extends State<ManageRoomsScreen> {
  final RoomService _roomService = RoomService();
  final String? _hostId = FirebaseAuth.instance.currentUser?.uid;

  String _formatPrice(double price) {
    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return formatCurrency.format(price);
  }

  void _navigateToAddRoom() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditRoomScreen()),
    );
  }

  void _navigateToEditRoom(RoomModel room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditRoomScreen(existingRoom: room),
      ),
    );
  }

  Future<void> _deleteRoom(RoomModel room) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Xác nhận xóa',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Bạn có chắc muốn xóa phòng "${room.title}" không?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _roomService.deleteRoom(room.id);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Đã xóa phòng')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hostId == null) {
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
        title: const Text(
          'Quản lý phòng',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        centerTitle: true,
        actions: const [NotificationBadgeIcon()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddRoom,
        backgroundColor: const Color(0xFFD4A853),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: StreamBuilder<List<RoomModel>>(
        stream: _roomService.getRoomsByHost(_hostId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4A853)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Đã xảy ra lỗi: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final rooms = snapshot.data ?? [];

          if (rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.meeting_room_outlined,
                    size: 80,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bạn chưa có phòng nào',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              final hasImage = room.images.isNotEmpty;

              return Card(
                color: const Color(0xFF1A1A1A),
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _navigateToEditRoom(room),
                  child: Row(
                    children: [
                      // Thumbnail
                      Container(
                        width: 100,
                        height: 100,
                        color: const Color(0xFF2A2A2A),
                        child: hasImage
                            ? Image.network(
                                room.images.first,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.white54,
                                ),
                              )
                            : const Icon(
                                Icons.hotel_outlined,
                                color: Colors.white54,
                                size: 40,
                              ),
                      ),
                      const SizedBox(width: 16),
                      // Info
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                room.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_formatPrice(room.basePrice)} / đêm',
                                style: const TextStyle(
                                  color: Color(0xFFD4A853),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildStatusBadge(room.status),
                                  const SizedBox(width: 8),
                                  Text(
                                    'SL: ${room.quantity}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Actions Menu
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          color: Colors.white54,
                        ),
                        color: const Color(0xFF2A2A2A),
                        onSelected: (value) {
                          if (value == 'edit') {
                            _navigateToEditRoom(room);
                          } else if (value == 'delete') {
                            _deleteRoom(room);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Chỉnh sửa',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Xóa',
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'available':
        color = Colors.green;
        label = 'Sẵn sàng';
        break;
      case 'maintenance':
        color = Colors.orange;
        label = 'Bảo trì';
        break;
      case 'unavailable':
        color = Colors.redAccent;
        label = 'Ngưng HĐ';
        break;
      default:
        color = Colors.grey;
        label = 'Không rõ';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
