import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Ensure a chat room exists between two users, returns Room ID
  Future<String> createOrGetRoom(
    String targetId,
    String targetName,
    String targetAvatar,
    String currentName,
    String currentAvatar,
  ) async {
    final currentId = _auth.currentUser!.uid;

    if (currentId == targetId) throw Exception('Cannot chat with yourself');

    // Create a predictable ID to avoid duplicates (lexicographical combination)
    List<String> ids = [currentId, targetId];
    ids.sort();
    String roomId = '${ids[0]}_${ids[1]}';

    final docRef = _firestore.collection('chat_rooms').doc(roomId);

    final docSnap = await docRef.get();
    if (!docSnap.exists) {
      // Room doesn't exist, create it
      final newRoom = ChatRoomModel(
        id: roomId,
        participants: [currentId, targetId],
        participantNames: {currentId: currentName, targetId: targetName},
        participantAvatars: {currentId: currentAvatar, targetId: targetAvatar},
        lastMessage: '',
        updatedAt: DateTime.now(),
        unreadCounts: {currentId: 0, targetId: 0},
      );
      await docRef.set(newRoom.toMap());
    }

    return roomId;
  }

  // Stream user's chat rooms
  Stream<List<ChatRoomModel>> getUserChatRooms() {
    final currentId = _auth.currentUser!.uid;

    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: currentId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatRoomModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Total unread messages across all rooms for current user.
  Stream<int> getTotalUnreadCount() {
    final currentId = _auth.currentUser?.uid;
    if (currentId == null) return Stream.value(0);

    return getUserChatRooms().map((rooms) {
      int total = 0;
      for (final r in rooms) {
        total += (r.unreadCounts[currentId] ?? 0);
      }
      return total;
    });
  }

  // Stream messages for a specific room
  Stream<List<MessageModel>> getMessages(String roomId) {
    return _firestore
        .collection('messages')
        .where('roomId', isEqualTo: roomId)
        .orderBy('createdAt', descending: true) // Newest first for listview
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Send a message
  Future<void> sendMessage(String roomId, String targetId, String text) async {
    final currentId = _auth.currentUser!.uid;

    // 1. Add message document
    final msg = MessageModel(
      id: '',
      roomId: roomId,
      senderId: currentId,
      text: text,
      createdAt: DateTime.now(),
    );
    await _firestore.collection('messages').add(msg.toMap());

    // 2. Update Room metadata (lastMessage, updatedAt, increment target unread count)
    await _firestore.collection('chat_rooms').doc(roomId).update({
      'lastMessage': text,
      'updatedAt': FieldValue.serverTimestamp(),
      'unreadCounts.$targetId': FieldValue.increment(1),
    });

    // 3. Trigger Notification
    final currentName = _auth.currentUser?.displayName ?? 'Một người';
    await NotificationService().createNotification(
      recipientId: targetId,
      title: 'Tin nhắn mới từ $currentName',
      body: text,
      type: 'chat',
      relatedId: roomId,
    );
  }

  // Mark room as read for the current user
  Future<void> markRoomAsRead(String roomId) async {
    final currentId = _auth.currentUser!.uid;
    await _firestore.collection('chat_rooms').doc(roomId).update({
      'unreadCounts.$currentId': 0,
    });
  }
}
