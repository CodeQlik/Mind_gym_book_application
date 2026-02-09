import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'models/login_model.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mind Gym Book',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Automatically switch based on system setting
      home: const AuthCheck(),
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  @override
  void initState() {
    super.initState();
    _checkUser();
  }

  Future<void> _checkUser() async {
    // Add a small delay for splash effect
    await Future.delayed(const Duration(seconds: 2));
    
    final user = await AuthService.getUser();
    
    if (mounted) {
      if (user != null) {
        // User logged in -> MainScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen(user: user)),
        );
      } else {
        // User not logged in -> LoginScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(Icons.menu_book_rounded, size: 80, color: Color(0xFF667EEA)),
             SizedBox(height: 20),
             CircularProgressIndicator(color: Color(0xFF667EEA)),
          ],
        ),
      ),
    );
  }
}