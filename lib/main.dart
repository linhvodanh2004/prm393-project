import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

import 'screens/auth/complete_profile_screen.dart';
import 'models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PRM393 Project',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final User? user = snapshot.data;
          
          if (user == null) {
            return const LoginScreen();
          }

          // User is authenticated, check their Firestore profile
          return FutureBuilder<UserModel?>(
            future: authService.getUserData(user.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: Color(0xFF0D0D0D),
                  body: Center(
                    child: CircularProgressIndicator(color: Color(0xFFD4A853)),
                  ),
                );
              }

              final userModel = userSnapshot.data;
              
              if (userModel == null || !userModel.hasCompleteProfile) {
                // Route to incomplete profile page
                return const CompleteProfileScreen();
              }

              // Otherwise route to Home
              return HomeScreen(userModel: userModel);
            },
          );
        }
        return const Scaffold(
          backgroundColor: Color(0xFF0D0D0D),
          body: Center(child: CircularProgressIndicator(color: Color(0xFFD4A853))),
        );
      },
    );
  }
}
