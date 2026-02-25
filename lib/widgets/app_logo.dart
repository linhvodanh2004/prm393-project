import 'package:flutter/material.dart';

// ─── App Logo Lockup ──────────────────────────────────────────────────────────
// Hiển thị icon app (từ local asset) + tên app + tagline ngắn.
//
// ★ Để dùng với file logo thật:
//   1. Đặt file tại: assets/images/logo.png
//   2. Đăng ký trong pubspec.yaml:
//        flutter:
//          assets:
//            - assets/images/logo.png
//   3. (Không cần sửa code gì thêm — Image.asset sẽ tự load)
class AppLogoLockup extends StatelessWidget {
  final double iconSize;
  final double fontSize;

  const AppLogoLockup({
    super.key,
    this.iconSize = 48,
    this.fontSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        LogoIcon(size: iconSize),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'StayBook',                   // ← Đổi thành tên app của bạn
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                height: 1.1,
              ),
            ),
            Text(
              'Đặt phòng đẳng cấp',        // ← Tagline ngắn (có thể xoá)
              style: TextStyle(
                color: const Color(0xFFD4A853),
                fontSize: fontSize * 0.55,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Logo Icon ────────────────────────────────────────────────────────────────
// Khi chưa có file asset → hiện AppIconPlaceholder ngay (không thử load).
// Khi đã có file logo thật:
//   1. Đặt file tại: assets/images/logo.png
//   2. Khai báo trong pubspec.yaml:
//        flutter:
//          assets:
//            - assets/images/logo.png
//   3. Đổi [_hasAsset] thành true — Image.asset sẽ được dùng.
class LogoIcon extends StatelessWidget {
  final double size;
  const LogoIcon({super.key, required this.size});

  static const String _assetPath = 'assets/images/logo.png';

  // ★ Đổi thành true khi đã thêm file logo vào assets
  static const bool _hasAsset = false;

  @override
  Widget build(BuildContext context) {
    if (!_hasAsset) return AppIconPlaceholder(size: size);

    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        _assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => AppIconPlaceholder(size: size),
      ),
    );
  }
}

// ─── App Icon Placeholder ─────────────────────────────────────────────────────
// Trông như app icon thật: vuông bo góc chuẩn iOS/Android ratio,
// gradient vàng sang đậm, icon hotel căn giữa, inner highlight mờ ở trên.
class AppIconPlaceholder extends StatelessWidget {
  final double size;
  const AppIconPlaceholder({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.22; // Bo góc chuẩn app icon (~22% như iOS)

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8C06A), Color(0xFF9C6A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 1.0],
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          // Ambient shadow
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.35),
            blurRadius: size * 0.25,
            offset: Offset(0, size * 0.08),
          ),
          // Gold glow
          BoxShadow(
            color: const Color(0xFFD4A853).withOpacity(0.3),
            blurRadius: size * 0.2,
            offset: Offset(0, size * 0.04),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Inner highlight — efek cahaya di bagian atas kiri (seperti app icon asli)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size * 0.5,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(radius),
                  topRight: Radius.circular(radius),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.18),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Icon căn giữa
          Center(
            child: Icon(
              Icons.hotel_rounded,
              color: Colors.white,
              size: size * 0.50,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
