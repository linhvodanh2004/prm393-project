import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/room_model.dart';
import '../../models/user_model.dart';
import '../../models/voucher_model.dart';
import '../../models/property_model.dart';
import '../../services/chat_service.dart';
import '../../services/property_service.dart';
import '../../services/room_service.dart';
import '../../services/voucher_service.dart';
import '../../utils/format_utils.dart';
import '../chat/chat_detail_screen.dart';
import '../user/room_details_screen.dart';

class HostPublicProfileScreen extends StatefulWidget {
  final String hostId;
  final String? initialRoomId;

  const HostPublicProfileScreen({
    super.key,
    required this.hostId,
    this.initialRoomId,
  });

  @override
  State<HostPublicProfileScreen> createState() => _HostPublicProfileScreenState();
}

class _HostPublicProfileScreenState extends State<HostPublicProfileScreen> {
  final _db = FirebaseFirestore.instance;
  final _roomService = RoomService();
  final _chatService = ChatService();
  final _voucherService = VoucherService();
  final _propertyService = PropertyService();

  bool _sendingQuick = false;

  Future<UserModel?> _getHost() async {
    final doc = await _db.collection('users').doc(widget.hostId).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Stream<PropertyModel?> _propertyStream() =>
      _propertyService.getPropertyByHost(widget.hostId);

  Future<void> _openChat(UserModel host, {String? quickMessage}) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final currentName = (currentUser.displayName ?? currentUser.email ?? 'Khách').trim();
    final currentAvatar = (currentUser.photoURL ?? '').trim();

    final hostName = host.name;
    final hostAvatar = (host.photoURL ?? '').trim();

    final roomId = await _chatService.createOrGetRoom(
      host.uid,
      hostName,
      hostAvatar,
      currentName,
      currentAvatar,
    );

    if (quickMessage != null && quickMessage.trim().isNotEmpty) {
      await _chatService.sendMessage(roomId, host.uid, quickMessage.trim());
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(
          roomId: roomId,
          targetId: host.uid,
          targetName: hostName,
          targetAvatar: hostAvatar,
        ),
      ),
    );
  }

  Future<void> _showQuickMessageSheet(UserModel host) async {
    final ctrl = TextEditingController();
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flash_on, color: Color(0xFFFFD700), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Gửi tin nhắn nhanh cho ${host.name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              style: const TextStyle(color: Colors.white),
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Nhập nội dung...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (ctrl.text.trim().isEmpty) return;
                      Navigator.pop(ctx, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Gửi'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (sent != true) return;
    if (!mounted) return;

    setState(() => _sendingQuick = true);
    try {
      await _openChat(host, quickMessage: ctrl.text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi gửi tin nhắn: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sendingQuick = false);
    }
  }

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.white38),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );

  Widget _roomCard(RoomModel room) {
    final image = room.images.isNotEmpty ? room.images.first : null;
    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RoomDetailsScreen(room: room)),
          );
        },
        child: Row(
          children: [
            Container(
              width: 96,
              height: 96,
              color: const Color(0xFF2A2A2A),
              child: image == null
                  ? const Icon(Icons.meeting_room_outlined,
                      color: Colors.white38, size: 36)
                  : Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white38,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${FormatUtils.vnd(room.basePrice)} / giờ',
                      style: const TextStyle(
                        color: Color(0xFFD4A853),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      room.status,
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.white38),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _copyVoucher(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép mã voucher'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _discountLabel(VoucherModel v) {
    if (v.type == 'PERCENT') {
      final pct = v.value.toStringAsFixed(0);
      if (v.maxDiscount != null && v.maxDiscount! > 0) {
        return 'Giảm $pct% (tối đa ${FormatUtils.vnd(v.maxDiscount!)})';
      }
      return 'Giảm $pct%';
    }
    return 'Giảm ${FormatUtils.vnd(v.value)}';
  }

  Widget _voucherTile(VoucherModel v) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        v.code,
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (v.endAt != null)
                      Text(
                        'HSD: ${FormatUtils.dateVi(v.endAt!)}',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _discountLabel(v),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                if (v.minSubtotal > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Đơn tối thiểu: ${FormatUtils.vnd(v.minSubtotal)}',
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Sao chép',
            onPressed: () => _copyVoucher(v.code),
            icon: const Icon(Icons.copy, color: Colors.white70, size: 18),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Thông tin chủ nhà',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<UserModel?>(
        future: _getHost(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4A853)),
            );
          }

          final host = snap.data;
          if (host == null) {
            return const Center(
              child: Text(
                'Không tìm thấy thông tin chủ nhà',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: StreamBuilder<PropertyModel?>(
                  stream: _propertyStream(),
                  builder: (context, propSnap) {
                    final p = propSnap.data;
                    final title = (p?.title ?? '').trim().isNotEmpty
                        ? p!.title
                        : host.name;
                    final address = (p?.address ?? '').trim().isNotEmpty
                        ? p!.address
                        : (host.address ?? '');
                    final desc = (p?.description ?? '').trim();
                    final imageUrl = (p?.coverImage ?? '').trim();

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: const Color(0xFF2A2A2A),
                            backgroundImage: imageUrl.isNotEmpty
                                ? NetworkImage(imageUrl)
                                : (host.photoURL != null &&
                                        host.photoURL!.isNotEmpty
                                    ? NetworkImage(host.photoURL!)
                                    : null),
                            child: (imageUrl.isEmpty &&
                                    (host.photoURL == null ||
                                        host.photoURL!.isEmpty))
                                ? const Icon(Icons.business, color: Colors.white54)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                _infoRow(
                                  Icons.location_on_outlined,
                                  address.trim().isNotEmpty
                                      ? address
                                      : 'Chưa cập nhật địa chỉ',
                                ),
                                if (desc.isNotEmpty)
                                  _infoRow(Icons.info_outline, desc),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _sendingQuick
                                            ? null
                                            : () => _openChat(host),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          side: const BorderSide(color: Colors.white24),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                                        label: const Text('Nhắn tin'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _sendingQuick
                                            ? null
                                            : () => _showQuickMessageSheet(host),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFFFD700),
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        icon: _sendingQuick
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.black,
                                                ),
                                              )
                                            : const Icon(Icons.flash_on, size: 18),
                                        label: const Text('Gửi nhanh'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: const [
                    Icon(Icons.local_offer_outlined,
                        color: Color(0xFFD4A853), size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Voucher đang áp dụng',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              StreamBuilder<List<VoucherModel>>(
                stream: _voucherService.getActiveVouchersByHost(widget.hostId),
                builder: (context, vSnap) {
                  if (vSnap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFFD4A853)),
                      ),
                    );
                  }
                  if (vSnap.hasError) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Text(
                        'Lỗi tải voucher: ${vSnap.error}',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    );
                  }
                  final vouchers =
                      (vSnap.data ?? []).where((v) => v.isValid).toList();
                  if (vouchers.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Chưa có voucher',
                          style: TextStyle(color: Colors.white38),
                        ),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      children: vouchers.map(_voucherTile).toList(),
                    ),
                  );
                },
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Phòng khác của chủ nhà',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<RoomModel>>(
                  stream: _roomService.getRoomsByHost(widget.hostId),
                  builder: (context, roomsSnap) {
                    if (roomsSnap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Color(0xFFD4A853)),
                      );
                    }
                    if (roomsSnap.hasError) {
                      return Center(
                        child: Text(
                          'Lỗi tải phòng: ${roomsSnap.error}',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      );
                    }

                    var rooms = roomsSnap.data ?? [];
                    if (widget.initialRoomId != null) {
                      rooms = rooms.where((r) => r.id != widget.initialRoomId).toList();
                    }
                    rooms = rooms.where((r) => r.status == 'available').toList();

                    if (rooms.isEmpty) {
                      return const Center(
                        child: Text(
                          'Chủ nhà chưa có phòng khả dụng',
                          style: TextStyle(color: Colors.white38),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: rooms.length,
                      itemBuilder: (_, i) => _roomCard(rooms[i]),
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

