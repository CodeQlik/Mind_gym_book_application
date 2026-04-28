import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models/notification_model.dart';

class NotificationDetailScreen extends StatelessWidget {
  final NotificationModel notification;

  const NotificationDetailScreen({super.key, required this.notification});

  String _formatDate(String dateStr) {
    try {
      final dateTime = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Update",
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon and Type
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _getIconColor(notification.type, theme).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIconData(notification.type),
                  color: _getIconColor(notification.type, theme),
                  size: 48,
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
            ),
            const SizedBox(height: 32),

            // Date
            Center(
              child: Text(
                _formatDate(notification.createdAt),
                style: TextStyle(
                  color: theme.disabledColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 16),

            // Title
            Center(
              child: Text(
                notification.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black87,
                  height: 1.2,
                ),
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 24),

            // Divider
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ).animate().scaleX(delay: 400.ms),
            const SizedBox(height: 32),

            // Rich Message Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Text(
                notification.message,
                style: TextStyle(
                  fontSize: 18,
                  height: 1.6,
                  color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87.withOpacity(0.8),
                ),
              ),
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.05, end: 0),

            const SizedBox(height: 40),

            // Action Button (Back)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor.withOpacity(0.1),
                  foregroundColor: theme.primaryColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Dismiss",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ).animate().fadeIn(delay: 600.ms),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String type) {
    switch (type) {
      case 'SUBSCRIPTION_ACTIVATED':
        return Icons.auto_awesome_rounded;
      case 'REFUND_REQUEST':
        return Icons.currency_exchange_rounded;
      case 'ORDER_CREATED':
        return Icons.shopping_bag_rounded;
      case 'SALE':
        return Icons.flash_on_rounded;
      case 'NEW_RELEASE':
        return Icons.library_add_check_rounded;
      case 'OFFER':
        return Icons.local_offer_rounded;
      case 'REMINDER':
        return Icons.alarm_rounded;
      case 'SYSTEM':
        return Icons.settings_suggest_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getIconColor(String type, ThemeData theme) {
    switch (type) {
      case 'SUBSCRIPTION_ACTIVATED':
        return const Color(0xFFFBBF24);
      case 'REFUND_REQUEST':
        return Colors.redAccent;
      case 'ORDER_CREATED':
        return Colors.blueAccent;
      case 'SALE':
        return Colors.orangeAccent;
      case 'NEW_RELEASE':
        return Colors.greenAccent;
      case 'OFFER':
        return Colors.pinkAccent;
      case 'REMINDER':
        return Colors.cyanAccent;
      default:
        return theme.primaryColor;
    }
  }
}
