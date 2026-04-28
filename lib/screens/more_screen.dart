import 'package:flutter/material.dart';
import '../models/login_model.dart';
import 'notes_screen.dart';
import 'settings_screen.dart';

class MoreScreen extends StatefulWidget {
  final LoginModel user;
  const MoreScreen({super.key, required this.user});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Adjust top padding to account for the floating header in MainScreen
    // MainScreen top bar is roughly ~60-70px + safe area
    final topPadding = MediaQuery.of(context).padding.top + 80;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ListView(
        padding: EdgeInsets.only(
            top: topPadding, bottom: 100), // Bottom padding for nav bar
        children: [
          _buildSectionHeader(
              theme, "Notebooks", Icons.book_rounded, Colors.teal),
          Divider(
              height: 32,
              thickness: 0.5,
              color: theme.dividerColor.withOpacity(0.3)),
          _buildMenuItem(theme, "Settings", Icons.settings_outlined),
          _buildMenuItem(theme, "Help & Feedback", Icons.help_outline),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
      ThemeData theme, String title, IconData icon, Color iconColor) {
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
        if (title == "Notebooks") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NotesScreen(user: widget.user),
            ),
          );
        }
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
}
