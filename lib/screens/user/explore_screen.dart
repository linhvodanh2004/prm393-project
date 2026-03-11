import 'package:flutter/material.dart';

import '../../models/room_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'room_details_screen.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('room').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final rooms = snapshot.data!.docs.map((doc) {
          return RoomModel.fromFirestore(doc);
        }).toList();

        return ListView.builder(
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final room = rooms[index];
            return Card(
              color: const Color(0xFF1A1A1A),
              child: ListTile(
                leading: room.image.isNotEmpty
                    ? Image.network(
                        room.image.first,
                        width: 60,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.meeting_room, color: Colors.white),
                title: Text(
                  room.type,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  "${room.price} VND - ${room.isAvailable ? 'Available' : 'Used'}",
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
                onTap: () {
                  // TODO: chuyển sang RoomDetailsScreen
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RoomDetailsScreen(room: room),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
