import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String? photoURL;
  final bool isUploading;
  final VoidCallback onEditTap;

  const ProfileAvatar({
    Key? key,
    required this.photoURL,
    required this.isUploading,
    required this.onEditTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        isUploading
            ? const CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFF1A1A1A),
                child: CircularProgressIndicator(color: Color(0xFFD4A853)),
              )
            : CircleAvatar(
                radius: 50,
                backgroundColor: const Color(0xFF2A2A2A),
                backgroundImage: photoURL != null
                    ? NetworkImage(photoURL!)
                    : null,
                child: photoURL == null
                    ? const Icon(Icons.person, size: 50, color: Colors.white54)
                    : null,
              ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: isUploading ? null : onEditTap,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFD4A853),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF0D0D0D), width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
