import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import '../models/login_model.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Wait for the animation to play beautifully
    await Future.delayed(const Duration(milliseconds: 3000));
    
    if (!mounted) return;

    // Perform the Auth Check logic
    final LoginModel? user = await AuthService.getUser();
    
    if (!mounted) return;

    if (user != null && user.token.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen(user: user)),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Deep midnight background to match the native splash we just fixed
    const Color bgColor = Color(0xFF0F0F1A);
    const Color accentColor = Color(0xFF764BA2);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // 1. Radiant Glow / Lighting effect in the center
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.2),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 2000.ms, curve: Curves.easeInOut)
            .custom(builder: (context, value, child) => Opacity(opacity: value.clamp(0.1, 0.4), child: child)),
          ),

          // 2. Main Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo with Heartbeat Pulse
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/icon/mgb_logo.jpeg',
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
                .animate()
                .scale(duration: 800.ms, curve: Curves.elasticOut)
                .then()
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.2))
                .scale(begin: const Offset(1,1), end: const Offset(1.05, 1.05), duration: 1500.ms, curve: Curves.easeInOut),

                const SizedBox(height: 30),

                // Animated App Name
                Text(
                  "Mind Gym Book",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    fontSize: 28,
                    shadows: [
                      Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                )
                .animate()
                .fadeIn(delay: 400.ms, duration: 600.ms)
                .slideY(begin: 0.5, end: 0, curve: Curves.easeOut),

                const SizedBox(height: 10),

                // Animated Slogan/Lighting Subtitle
                Text(
                  "Elevate Your Mindset",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    letterSpacing: 4.0,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                )
                .animate()
                .fadeIn(delay: 800.ms, duration: 600.ms)
                .shimmer(delay: 1500.ms, duration: 2000.ms, color: Colors.white.withOpacity(0.5)),
              ],
            ),
          ),
          
          // 3. Bottom Loading Indicator (Subtle)
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 40,
                height: 2,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.white.withOpacity(0.05),
                  color: accentColor.withOpacity(0.5),
                ),
              ),
            )
            .animate()
            .fadeIn(delay: 1200.ms),
          ),
        ],
      ),
    );
  }
}
