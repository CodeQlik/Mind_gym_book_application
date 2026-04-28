import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum ToastType { success, error, info }

class AppToasts {
  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.clearSnackBars();

    Color baseColor;
    IconData icon;
    Color iconColor;

    switch (type) {
      case ToastType.success:
        baseColor = const Color(0xFF10B981); // Emerald
        icon = Icons.check_circle_rounded;
        iconColor = Colors.white;
        break;
      case ToastType.error:
        baseColor = const Color(0xFFEF4444); // Crimson
        icon = Icons.error_rounded;
        iconColor = Colors.white;
        break;
      case ToastType.info:
        baseColor = const Color(0xFF3B82F6); // Blue
        icon = Icons.info_rounded;
        iconColor = Colors.white;
        break;
    }

    scaffoldMessenger.showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: baseColor.withOpacity(0.4), width: 1.5),
                boxShadow: [
                  BoxShadow(color: baseColor.withOpacity(0.1), blurRadius: 20, spreadRadius: -5)
                ],
              ),
              child: Row(
                children: [
                  // Animated Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: baseColor.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(icon, color: iconColor, size: 20),
                  ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack).rotate(duration: 400.ms),
                  
                  const SizedBox(width: 16),
                  
                  // Message Text
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .slideY(begin: 1, end: 0, duration: 500.ms, curve: Curves.easeOutQuart)
        .fadeIn(duration: 400.ms)
        .shimmer(delay: 500.ms, duration: 1.seconds, color: Colors.white24),
      ),
    );
  }

  // Easy access helpers
  static void success(BuildContext context, String message) => show(context, message: message, type: ToastType.success);
  static void error(BuildContext context, String message) => show(context, message: message, type: ToastType.error);
  static void info(BuildContext context, String message) => show(context, message: message, type: ToastType.info);
}
