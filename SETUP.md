# Project Setup Guide

## Prerequisites

Before setting up this project, ensure you have the following installed:

- **Flutter SDK** (3.10.4 or higher)
- **Dart SDK** (comes with Flutter)
- **Android Studio** or **VS Code** with Flutter extensions
- **Firebase CLI** (optional, for advanced configuration)
- **Git**

## Project Overview

This is a Flutter mobile application with Firebase authentication (Google Sign-In and Email/Password) and Firestore database integration.

## Setup Instructions

### 1. Clone the Repository

```bash
git clone <repository-url>
cd prm393_project
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Firebase Configuration (Checklist)

> Ưu tiên làm đúng từng bước dưới đây để tránh lỗi `Firebase not initialized`, `PERMISSION_DENIED` hoặc FCM không nhận thông báo.

#### A. Tạo Firebase Project

1. Vào [Firebase Console](https://console.firebase.google.com/)
2. **Add project** → đặt tên, chọn region.
3. Bật/không bật Google Analytics tùy nhu cầu (không bắt buộc).

#### B. Thêm Android App

1. Trong Firebase Console → **Project settings → Your apps → Add app → Android**.
2. **Android package name**: kiểm tra trong `android/app/src/main/AndroidManifest.xml` và `android/app/build.gradle` (thường dạng `com.example.prm393_project` hoặc tên custom của bạn) và khai báo đúng.
3. Tải `google-services.json`.
4. Đặt file vào thư mục `android/app/google-services.json`.
5. Kiểm tra lại `android/build.gradle` và `android/app/build.gradle` đã có dòng apply `com.google.gms.google-services` (Flutter template thường đã cấu hình sẵn).

#### C. Thêm SHA-1 / SHA-256 (bắt buộc cho Google Sign-In)

**Debug SHA-1:**
```bash
cd android
./gradlew signingReport
```

Or on Windows:
```bash
cd android
gradlew.bat signingReport
```

Copy the SHA-1 fingerprint and add it to your Firebase project:
- Firebase Console → Project Settings → Your Android App → Add fingerprint

#### D. Bật phương thức đăng nhập (Authentication)

1. Firebase Console → **Authentication → Sign-in method**.
2. Bật:
   - **Email/Password**.
   - **Google**.
3. Lưu lại.

#### E. Tạo Firestore Database

1. Firebase Console → **Firestore Database**.
2. **Create database**.
3. Chọn:
   - Dev: có thể chọn *Start in test mode* (chỉ nên dùng trong giai đoạn phát triển).
   - Prod: *Production mode* (sau đó tự chỉnh rules).
4. Chọn region gần người dùng → **Enable**.

#### F. Import Firestore Indexes (nên làm)

Trong repo đã có file `firestore.indexes.json` mô tả các index cần thiết (bookings, notifications, vouchers,…).

**Cách 1 (CLI khuyến nghị)**:
- Cài Firebase CLI nếu chưa có.
- Ở thư mục project:
  ```bash
  firebase login
  firebase use prm393-project    # hoặc project id tương ứng trong firebase.json
  firebase firestore:indexes:apply firestore.indexes.json
  ```

**Cách 2 (thủ công trên console)**:
- Firebase Console → **Firestore Database → Indexes → Composite indexes**.
- Tạo lần lượt:
  - `bookings`: `(hostId ASC, createdAt DESC)`.
  - `bookings`: `(userId ASC, createdAt DESC)`.
  - `bookings`: `(hostId ASC, status ASC, createdAt DESC)`.
  - `notifications`: `(recipientId ASC, isRead ASC, createdAt DESC)`.
  - `host_requests`: `(userId ASC, createdAt DESC)`.
  - Và các index khác theo `firestore.indexes.json` nếu có cảnh báo từ Firestore.

#### G. Firestore Security Rules (dev vs prod)

**Dev (tạm thời):**

```javascript
rules_version = '2';
service cloud_firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**Prod (gợi ý định hướng):**
- Chỉ cho phép:
  - USER đọc/ghi tài liệu của chính mình (`users/{uid}`, `bookings` của user đó).
  - HOST chỉ đọc/ghi `rooms` của mình, booking liên quan.
  - ADMIN có quyền rộng hơn (có thể dùng custom claims / kiểm tra role trong field `role`).
> Quy tắc chi tiết nên được thiết kế sau khi chốt toàn bộ schema ở `README.md`.

### 4. Firebase Options (Optional)

If you need to support multiple platforms (iOS, Web), generate Firebase options:

```bash
flutterfire configure
```

This will create `lib/firebase_options.dart` automatically.

### 5. Run the Application

#### Android Emulator/Device

```bash
flutter run
```

#### Specific Device

```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device-id>
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration (auto-generated)
├── models/
│   ├── user_dto.dart        # User data transfer object
│   └── register_dto.dart    # Registration data transfer object
├── services/
│   └── auth_service.dart    # Authentication service
└── screens/
    ├── login_screen.dart    # Login UI
    ├── register_screen.dart # Registration UI
    ├── home_screen.dart     # Home screen
    └── user_details_screen.dart # User profile screen
```

## Features

- **Google Sign-In**: OAuth authentication via Google
- **Email/Password Registration**: Custom registration with 7 fields
  - Full Name
  - Email
  - Phone Number
  - Address
  - Age
  - Bio
  - Password
- **User Profile**: Display user information from Firestore
- **DTO Pattern**: Type-safe data transfer objects

## Database Schema

### Firestore Collection: `users`

**For Email/Password Users:**
```json
{
  "email": "user@example.com",
  "fullName": "John Doe",
  "phoneNumber": "+1234567890",
  "address": "123 Main St",
  "age": 25,
  "bio": "Software developer",
  "authProvider": "email",
  "createdAt": Timestamp
}
```

**For Google Sign-In Users:**
```json
{
  "email": "user@gmail.com",
  "displayName": "John Doe",
  "photoURL": "https://...",
  "authProvider": "google",
  "createdAt": Timestamp
}
```

## Troubleshooting

### Common Issues

#### 1. Google Sign-In Fails

**Solution:**
- Ensure SHA-1 fingerprint is added to Firebase Console
- Verify `google-services.json` is in `android/app/`
- Check that Google Sign-In is enabled in Firebase Console

#### 2. Build Errors

**Solution:**
```bash
flutter clean
flutter pub get
flutter run
```

#### 3. Firebase Not Initialized

**Solution:**
- Verify `google-services.json` exists in `android/app/`
- Check Firebase initialization in `main.dart`
- Ensure Firebase dependencies are correct in `pubspec.yaml`

#### 4. Firestore Permission Denied

**Solution:**
- Check Firestore security rules
- Ensure user is authenticated before accessing Firestore
- For development, use test mode rules

## Development Workflow

### Adding New Features

1. Update `task.md` with new tasks
2. Create implementation plan if needed
3. Implement features
4. Test thoroughly
5. Update documentation

### Testing

```bash
# Run tests
flutter test

# Run with coverage
flutter test --coverage
```

### Building for Release

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release
```

## Dependencies

Key packages used in this project:

- `firebase_core: ^4.4.0` - Firebase core functionality
- `firebase_auth: ^6.1.4` - Firebase authentication
- `google_sign_in: ^6.2.2` - Google Sign-In
- `cloud_firestore: ^6.1.0` - Firestore database

## Environment Variables

No environment variables are required. All configuration is done through Firebase configuration files.

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Firebase documentation
3. Check Flutter documentation
4. Contact the development team

## License

[Add your license information here]
