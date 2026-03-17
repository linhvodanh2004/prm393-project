import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/room_model.dart';
import '../../services/favorite_service.dart';
import 'room_details_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _favService = FavoriteService();
  final _db = FirebaseFirestore.instance;
  late final String _uid;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  Future<List<RoomModel>> _fetchRooms(List<String> ids) async {
    if (ids.isEmpty) return [];
    // Firestore 'whereIn' limit is 30; chunk if needed
    final List<RoomModel> rooms = [];
    for (int i = 0; i < ids.length; i += 30) {
      final chunk = ids.sublist(i, (i + 30).clamp(0, ids.length));
      final snap = await _db
          .collection('rooms')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      rooms.addAll(
          snap.docs.map((d) => RoomModel.fromMap(d.data(), d.id)));
    }
    return rooms;
  }

  Future<void> _unfavorite(String roomId) async {
    try {
      await _favService.removeFavorite(_uid, roomId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi: $e'),
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_uid.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D0D),
        body: Center(
            child: Text('Vui lòng đăng nhập',
                style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Yêu thích',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<String>>(
        stream: _favService.streamFavoriteIds(_uid),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFFFFD700)));
          }

          final ids = snap.data ?? [];
          if (ids.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border,
                      color: Colors.white12, size: 64),
                  SizedBox(height: 16),
                  Text('Chưa có phòng yêu thích',
                      style: TextStyle(
                          color: Colors.white38, fontSize: 16)),
                ],
              ),
            );
          }

          return FutureBuilder<List<RoomModel>>(
            future: _fetchRooms(ids),
            builder: (ctx2, roomSnap) {
              if (roomSnap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFFFD700)));
              }

              final rooms = roomSnap.data ?? [];
              if (rooms.isEmpty) {
                return const Center(
                    child: Text('Không tìm thấy phòng',
                        style: TextStyle(color: Colors.white38)));
              }

              return RefreshIndicator(
                color: const Color(0xFFFFD700),
                backgroundColor: const Color(0xFF1A1A1A),
                onRefresh: () async => setState(() {}),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: rooms.length,
                  itemBuilder: (_, i) =>
                      _buildRoomCard(context, rooms[i]),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRoomCard(BuildContext context, RoomModel room) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => RoomDetailsScreen(room: room)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                  child: room.images.isNotEmpty
                      ? Image.network(room.images.first,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              height: 180,
                              color: const Color(0xFF2A2A2A),
                              child: const Icon(Icons.broken_image,
                                  color: Colors.white24)))
                      : Container(
                          height: 180,
                          color: const Color(0xFF2A2A2A),
                          child: const Icon(Icons.meeting_room,
                              color: Colors.white24)),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () => _unfavorite(room.id),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle),
                      child: const Icon(Icons.favorite,
                          color: Colors.redAccent, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(room.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatPrice(room.basePrice)} / đêm',
                    style: const TextStyle(
                        color: Color(0xFFFFD700), fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M₫';
    }
    return '${(price / 1000).toStringAsFixed(0)}k₫';
  }
}
