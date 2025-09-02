import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'core/theme.dart';
import 'core/user_session.dart';
import 'pages/auth/login_page.dart';
import 'pages/home/home_page.dart';
import 'pages/admin/admin_home_page.dart'; // You'll create this next

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  runApp(const MangaComicsReaderApp());
}

class MangaComicsReaderApp extends StatelessWidget {
  const MangaComicsReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MangaSphere',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme(),
      home: const _RootGate(),
    );
  }
}

class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.appBackground,
            body: Center(
              child: SizedBox(
                height: 28,
                width: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        // User is signed in if snapshot.data is not null
        final user = snapshot.data;
        if (user != null) {
          // User is authenticated, check their role
          return FutureBuilder<UserSession?>(
            future: UserSession.getCurrentSession(),
            builder: (context, sessionSnapshot) {
              if (sessionSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: AppTheme.appBackground,
                  body: Center(
                    child: SizedBox(
                      height: 28,
                      width: 28,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }

              final session = sessionSnapshot.data;
              
              // Route based on user role
              if (session?.isAdmin == true) {
                return const AdminHomePage(); // Admin dashboard
              } else {
                return const HomePage(); // Regular user home
              }
            },
          );
        }

        // User is not signed in
        return const LoginPage();
      },
    );
  }
}
