import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/login_model.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'more_screen.dart';
import 'profile_screen.dart';
import 'notification_screen.dart';
import 'search_screen.dart';

class MainScreen extends StatefulWidget {
  final LoginModel user;
  const MainScreen({super.key, required this.user});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final bool _hasNotifications = false; // Mock notification state
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Initialize pages with user data where needed
    _pages = [
      HomeScreen(user: widget.user),
      const LibraryScreen(),
      MoreScreen(user: widget.user),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBody: true,
      body: Stack(
        children: [
          // Body Content (IndexedStack)
          Positioned.fill(
            child: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
          ),

          // Floating Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildFloatingTopBar(context, theme),
          ),
        ],
      ),

      // Modern Custom Bottom Navigation
      bottomNavigationBar: _buildModernBottomNav(theme),
    );
  }

  Widget _buildFloatingTopBar(BuildContext context, ThemeData theme) {
    // Determine glass color based on theme brightness
    final isDark = theme.brightness == Brightness.dark;
    final glassColor = isDark
        ? const Color(0xFF1E1E1E).withOpacity(0.85)
        : Colors.white.withOpacity(0.85);
    final borderColor =
        isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.5);
    final searchBgColor = isDark ? Colors.grey.shade800 : Colors.grey.shade100;
    final hintColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;
    final iconColor = theme.iconTheme.color;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            right: 20,
            bottom: 10,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: glassColor,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              // 1. Profile Image
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(user: widget.user),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.primaryColor, width: 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.scaffoldBackgroundColor,
                      backgroundImage: widget.user.profile.url.isNotEmpty
                          ? NetworkImage(widget.user.profile.url)
                          : null,
                      onBackgroundImageError: widget.user.profile.url.isNotEmpty
                          ? (_, __) {}
                          : null,
                      child: widget.user.profile.url.isEmpty
                          ? Text(
                              widget.user.profile.initials,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                                fontSize: 12,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),

              // 2. Search Bar
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SearchScreen()),
                    );
                  },
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: searchBgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: AbsorbPointer(
                      // Prevent keyboard from popping up
                      child: TextField(
                        enabled: false, // Visual only
                        decoration: InputDecoration(
                          hintText: "Search books...",
                          hintStyle: TextStyle(color: hintColor, fontSize: 14),
                          prefixIcon: Icon(Icons.search_rounded,
                              color: hintColor, size: 20),
                          //suffixIcon: Icon(Icons.mic_none_rounded, color: theme.primaryColor, size: 20),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 10),
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),

              // 3. Notification Bell
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const NotificationScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    children: [
                      Icon(Icons.notifications_outlined,
                          color: iconColor, size: 26),
                      if (_hasNotifications)
                        Positioned(
                          right: 2,
                          top: 2,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5252),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: theme.appBarTheme.backgroundColor ??
                                      Colors.white,
                                  width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernBottomNav(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final navBgColor = isDark
        ? const Color(0xFF1E1E1E).withOpacity(0.95)
        : Colors.white.withOpacity(0.95);

    return Container(
      color: Colors.transparent, // Make outer container transparent
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 0),
      child: SafeArea(
        // SafeArea ensures it respects bottom notches
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: navBgColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(0, Icons.home_rounded, "Home", theme),
              _buildNavItem(1, Icons.menu_book_rounded, "Library", theme),
              _buildNavItem(2, Icons.grid_view_rounded, "More", theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData icon, String label, ThemeData theme) {
    bool isSelected = _selectedIndex == index;
    final unselectedColor = theme.brightness == Brightness.dark
        ? Colors.grey.shade600
        : Colors.grey.shade400;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : unselectedColor,
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
