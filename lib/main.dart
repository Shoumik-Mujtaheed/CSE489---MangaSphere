import 'package:flutter/material.dart';
import 'core/theme.dart';
import './core/auth_store.dart';
import 'pages/auth/login_page.dart';
import 'pages/home/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    return FutureBuilder<bool>(
      future: AuthStore.isLoggedIn(),
      builder: (context, snapshot) {
        // Simple splash/loading while reading prefs
        if (snapshot.connectionState != ConnectionState.done) {
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

        final loggedIn = snapshot.data ?? false;
        return loggedIn ? const HomePage() : const LoginPage();
      },
    );
  }
}
