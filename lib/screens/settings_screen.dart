import 'package:flutter/material.dart';
import '../models/login_model.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  final LoginModel user;
  const SettingsScreen({super.key, required this.user});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Toggle states

  bool _wifiOnly = false;
  bool _syncEnabled = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Kindle style colors
    final backgroundColor = isDark ? Colors.black : Colors.white;
    final headerColor = isDark ? Colors.grey.shade400 : Colors.grey.shade700;
    final subTitleColor = isDark ? Colors.grey.shade500 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
        backgroundColor: backgroundColor,
        foregroundColor: theme.textTheme.bodyMedium?.color,
        elevation: 0,
        leading: Container(), // Hide back button if using clear/close logic on right
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: Colors.blueAccent),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: ListView(
        children: [
          // GENERAL
          _buildSectionHeader("GENERAL", headerColor),
          _buildNavItem(theme, "Push Notifications"),
          _buildNavItem(theme, "Manage Additional Fonts"),


          // DOWNLOAD AND SYNC
          _buildSectionHeader("DOWNLOAD AND SYNC", headerColor),
          _buildSwitchItem(
            theme,
            "Wi-fi Only for Large Downloads",
            "Tap for explanation",
            _wifiOnly,
            (val) => setState(() => _wifiOnly = val),
            subTitleColor,
          ),
          _buildSwitchItem(
            theme,
            "Sync",
            "Tap for explanation",
            _syncEnabled,
            (val) => setState(() => _syncEnabled = val),
            subTitleColor,
            activeColor: Colors.blueAccent,
          ),

          // SEND-TO-KINDLE EMAIL
          _buildSectionHeader("SEND-TO-KINDLE EMAIL ADDRESS", headerColor),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
            child: Text(
              "${widget.user.name.trim().toLowerCase().replaceAll(' ', '')}@kindle.com", // Mock email
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 16,
              ),
            ),
          ),

          // ABOUT
          _buildSectionHeader("ABOUT", headerColor),
          _buildNavItem(theme, "Version"),
          _buildNavItem(theme, "Terms of Use"),
          _buildNavItem(theme, "Legal Notices"),
          _buildNavItem(theme, "Privacy Notice"),

          const SizedBox(height: 30),

          // FOOTER: REGISTERED TO & SIGN OUT
          Center(
            child: Column(
              children: [
                Text(
                  "Registered to: ${widget.user.name}",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "(${widget.user.name}'s Device)", 
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: subTitleColor,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _handleSignOut,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    side: BorderSide(color: subTitleColor),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: Text(
                    "Sign Out",
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildNavItem(ThemeData theme, String title) {
    return ListTile(
      title: Text(title, style: theme.textTheme.bodyLarge),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade600, size: 20),
      onTap: () {},
    );
  }

  Widget _buildSwitchItem(
    ThemeData theme,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    Color subTitleColor, {
    Color? activeColor,
  }) {
    return ListTile(
      title: Text(title, style: theme.textTheme.bodyLarge),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: subTitleColor, fontSize: 13),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: activeColor, // Uses theme accent if null
      ),
      onTap: () => onChanged(!value),
    );
  }

  Future<void> _handleSignOut() async {
    // Show confirmation dialog before signing out
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sign Out"),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Sign Out", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      await AuthService.clearUser();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}
