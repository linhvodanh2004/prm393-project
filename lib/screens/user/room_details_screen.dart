import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import '../../models/room_model.dart';
import '../../models/order_model.dart';

class RoomDetailsScreen extends StatelessWidget {
  final RoomModel room;

  const RoomDetailsScreen({super.key, required this.room});

  Future<void> _createOrder(BuildContext context) async {
    try {
      final orderRef = FirebaseFirestore.instance.collection('orders').doc();

      await orderRef.set({
        'userId': FirebaseAuth.instance.currentUser!.uid,
        'employeeId': null, // chưa có nhân viên xử lý
        'timeUsed': null, // thời gian sử dụng sẽ được cập nhật sau
        'roomId': room.id,
        'createdAt': DateTime.now(),
        'isDone': false,
        'isDeleted': false,
        'status': 'pending', // trạng thái ban đầu
        'paymentMethod': 'COD', // thanh toán khi nhận phòng
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Đặt phòng thành công!")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi khi đặt phòng: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        title: Text(room.type),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Nút Back
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh phòng
            room.image.isNotEmpty
                ? Image.network(room.image.first, fit: BoxFit.cover)
                : const SizedBox(height: 200, child: Icon(Icons.meeting_room)),

            const SizedBox(height: 16),

            // Mô tả
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                room.description,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),

            const SizedBox(height: 16),

            // Giá
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "${room.price} VND",
                style: const TextStyle(
                  color: Color(0xFFD4A853),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Trạng thái
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                room.isAvailable ? "Còn trống" : "Hết phòng",
                style: TextStyle(
                  color: room.isAvailable ? Colors.green : Colors.red,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),

      // Nút Book it
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD4A853),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () {
            // TODO: xử lý logic đặt phòng
            _createOrder(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Đặt phòng thành công!")),
            );
          },
          child: const Text(
            "Book it",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
