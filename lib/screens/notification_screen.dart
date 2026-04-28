import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'notification_detail_screen.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationModel>? _notifications;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    final user = await AuthService.getUser();
    if (user != null && user.token.isNotEmpty) {
      final list = await ApiService.getNotifications(user.token);
      if (mounted) {
        setState(() {
          _notifications = list;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(int id, int index) async {
    final notification = _notifications![index];

    // Mark as read immediately and locally if it's currently unread
    if (!notification.isRead) {
      setState(() {
        _notifications![index] = notification.copyWith(isRead: true);
      });

      // Update server in background
      final user = await AuthService.getUser();
      if (user != null && user.token.isNotEmpty) {
        ApiService.markNotificationAsRead(user.token, id);
      }
    }

    // Navigate to detail screen
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationDetailScreen(notification: notification),
      ),
    );
  }

  Future<void> _markAllAsRead() async {
    final user = await AuthService.getUser();
    if (user != null && user.token.isNotEmpty) {
      final success = await ApiService.markAllNotificationsAsRead(user.token);
      if (success && mounted) {
        setState(() {
          _notifications = _notifications!
              .map((n) => n.copyWith(isRead: true))
              .toList();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("All notifications marked as read")),
        );
      }
    }
  }


  String _formatDate(String dateStr) {
    try {
      final dateTime = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 60) {
        return "${difference.inMinutes}m ago";
      } else if (difference.inHours < 24) {
        return "${difference.inHours}h ago";
      } else if (difference.inDays < 7) {
        return "${difference.inDays}d ago";
      } else {
        return DateFormat('MMM dd, yyyy').format(dateTime);
      }
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
        title: const Text("Notifications",
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_notifications != null && _notifications!.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllAsRead,
              child: Text("Mark all read",
                  style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchNotifications,
              child: _notifications == null || _notifications!.isEmpty
                  ? _buildEmptyState(theme)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _notifications!.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications![index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildNotificationCard(theme, notification, index),
                        ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.05, end: 0);
                      },
                    ),
            ),
    );
  }

  Widget _buildNotificationCard(ThemeData theme, NotificationModel notification, int index) {
    final isDark = theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => _markAsRead(notification.id, index),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: notification.isRead
                ? Colors.transparent
                : theme.primaryColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getIconColor(notification.type, theme).withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _getIconData(notification.type),
                color: _getIconColor(notification.type, theme),
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      Text(
                        _formatDate(notification.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.disabledColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  if (!notification.isRead) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "New",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
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

  Widget _buildEmptyState(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 80,
                color: theme.primaryColor.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "All Caught Up!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "No new notifications at the moment. We'll let you know when something exciting happens.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.disabledColor,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 160,
              height: 50,
              child: ElevatedButton(
                onPressed: _fetchNotifications,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 5,
                ),
                child: const Text("Refresh", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
