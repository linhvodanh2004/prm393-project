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

### 3. Firebase Configuration

#### A. Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" and follow the setup wizard
3. Enable Google Analytics (optional)

#### B. Configure Android App

1. In Firebase Console, click "Add app" → Select Android
2. Register your app with package name: `com.example.prm393_project`
3. Download `google-services.json`
4. Place it in `android/app/` directory

#### C. Get SHA-1 Fingerprint (Required for Google Sign-In)

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

#### D. Enable Authentication Methods

1. In Firebase Console, go to **Authentication** → **Sign-in method**
2. Enable **Email/Password**
3. Enable **Google** sign-in provider
4. Save changes

#### E. Create Firestore Database

1. In Firebase Console, go to **Firestore Database**
2. Click **Create database**
3. Choose **Start in test mode** (for development)
4. Select a location closest to your users
5. Click **Enable**

#### F. Configure Firestore Security Rules (Optional)

For development, you can use test mode. For production, update rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

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
