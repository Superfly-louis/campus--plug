import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/chat_service.dart';
import 'services/firestore_service.dart';
import 'services/storage_service.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'core/app_router.dart';
import 'firebase_options.dart';
import 'core/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<StorageService>(create: (_) => StorageService()),
        Provider<ChatService>(create: (_) => ChatService()),
      ],
      child: const CampusPlugApp(),
    ),
  );
}

class CampusPlugApp extends StatelessWidget {
  const CampusPlugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Campus Plug',
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          final authService = Provider.of<AuthService>(context, listen: false);
          return AppRouter.destinationFor(authService.currentUserProfile);
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
