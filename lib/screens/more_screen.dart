import 'package:flutter/material.dart';
import '../models/login_model.dart';
import 'settings_screen.dart';

class MoreScreen extends StatefulWidget {
  final LoginModel user;
  const MoreScreen({super.key, required this.user});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  String _lastSyncedTime = "2/8/26, 5:42 PM"; // Placeholder, can be dynamic later

  @override
  void initState() {
    super.initState();
    // Simulate updating sync time on init or use a real service
    _updateSyncTime();
  }

  void _updateSyncTime() {
    final now = DateTime.now();
    // Simple formatting for demo: MO/DAY/YR, H:MM AM/PM
    // In a real app, use intl package
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final amPm = now.hour >= 12 ? 'PM' : 'AM';
    final minute = now.minute.toString().padLeft(2, '0');
    setState(() {
      _lastSyncedTime = "${now.month}/${now.day}/${now.year % 100}, $hour:$minute $amPm";
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Adjust top padding to account for the floating header in MainScreen
    // MainScreen top bar is roughly ~60-70px + safe area
    final topPadding = MediaQuery.of(context).padding.top + 80;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ListView(
        padding: EdgeInsets.only(top: topPadding, bottom: 100), // Bottom padding for nav bar
        children: [
          _buildSectionHeader(theme, "Reading Insights", Icons.insights_rounded, Colors.blueAccent),
          _buildSectionHeader(theme, "Notebooks", Icons.book_rounded, Colors.teal),
          
          Divider(height: 32, thickness: 0.5, color: theme.dividerColor.withOpacity(0.3)),

          _buildSyncItem(theme),
          _buildMenuItem(theme, "Settings", Icons.settings_outlined),
          _buildMenuItem(theme, "Help & Feedback", Icons.help_outline),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon, Color iconColor) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 28),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: theme.disabledColor),
      onTap: () {
        // TODO: Navigate to respective screen
      },
    );
  }

  Widget _buildMenuItem(ThemeData theme, String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: theme.iconTheme.color, size: 24),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: theme.disabledColor),
      onTap: () {
        if (title == "Settings") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SettingsScreen(user: widget.user),
            ),
          );
        }
      },
    );
  }

  Widget _buildSyncItem(ThemeData theme) {
    return ListTile(
      leading: Icon(Icons.sync, color: theme.iconTheme.color, size: 24),
      title: Text(
        "Sync",
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        "Last synced on $_lastSyncedTime",
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.disabledColor,
        ),
      ),
      onTap: () {
        // Trigger generic sync animation/logic
        setState(() {
           _updateSyncTime();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Syncing content..."),
            backgroundColor: theme.cardColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            /*action: SnackBarAction(
              label: 'Undo',
              textColor: theme.primaryColor,
              onPressed: () {},
            ),*/
          ),
        );
      },
    );
  }
}
