import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  final String id;
  final List<String> participants; // User IDs
  final Map<String, String> participantNames; // UID -> Name
  final Map<String, String> participantAvatars; // UID -> Avatar URL
  final String lastMessage;
  final DateTime updatedAt;
  final Map<String, int> unreadCounts; // UID -> Unread Count

  ChatRoomModel({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.participantAvatars,
    required this.lastMessage,
    required this.updatedAt,
    required this.unreadCounts,
  });

  factory ChatRoomModel.fromMap(Map<String, dynamic> data, String documentId) {
    return ChatRoomModel(
      id: documentId,
      participants: List<String>.from(data['participants'] ?? []),
      participantNames: Map<String, String>.from(
        data['participantNames'] ?? {},
      ),
      participantAvatars: Map<String, String>.from(
        data['participantAvatars'] ?? {},
      ),
      lastMessage: data['lastMessage'] ?? '',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCounts: Map<String, int>.from(data['unreadCounts'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'participantNames': participantNames,
      'participantAvatars': participantAvatars,
      'lastMessage': lastMessage,
      'updatedAt': FieldValue.serverTimestamp(),
      'unreadCounts': unreadCounts,
    };
  }
}

class MessageModel {
  final String id;
  final String roomId;
  final String senderId;
  final String text;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  factory MessageModel.fromMap(Map<String, dynamic> data, String documentId) {
    return MessageModel(
      id: documentId,
      roomId: data['roomId'] ?? '',
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'senderId': senderId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
