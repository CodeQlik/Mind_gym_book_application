import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/login_model.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'more_screen.dart';
import 'profile_screen.dart';
import 'notification_screen.dart';
import 'search_screen.dart';
import '../services/auth_service.dart';

class MainScreen extends StatefulWidget {
  final LoginModel user;
  const MainScreen({super.key, required this.user});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  int _unreadCount = 0;
  late LoginModel _currentUser;
  
  // Keys to trigger refresh methods across tabs
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  final GlobalKey<LibraryScreenState> _libraryKey = GlobalKey<LibraryScreenState>();

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _pages = [
      HomeScreen(key: _homeKey, user: _currentUser, onRefresh: _fetchUnreadCount),
      LibraryScreen(key: _libraryKey),
      MoreScreen(user: _currentUser),
    ];
    _fetchUnreadCount();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final updatedUser = await ApiService.getUserProfile(_currentUser.token);
      if (mounted) {
        setState(() {
          _currentUser = updatedUser;
          // Update pages to use the new user data
          _pages[0] = HomeScreen(key: _homeKey, user: _currentUser, onRefresh: _fetchUnreadCount);
          _pages[2] = MoreScreen(user: _currentUser);
        });
        // Persist the updated user data
        await AuthService.saveUser(_currentUser);
      }
    } catch (e) {
      debugPrint("Error fetching user profile: $e");
    }
  }

  Future<void> _fetchUnreadCount() async {
    final count = await ApiService.getUnreadNotificationCount(_currentUser.token);
    if (mounted) {
      setState(() {
        _unreadCount = count;
      });
    }
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });

    // Auto-refresh logic when switching tabs
    if (index == 0) {
      // Refresh Home
      _homeKey.currentState?.loadInitialData();
      _fetchUnreadCount();
    } else if (index == 1) {
      // Refresh Library
      _libraryKey.currentState?.loadBookmarks();
    }
  }

  void _goToNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationScreen()),
    );
    _fetchUnreadCount(); // Refresh count when coming back
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
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(user: _currentUser),
                    ),
                  );
                  // Refresh user from local storage after profile update
                  final updatedUser = await AuthService.getUser();
                  if (updatedUser != null && mounted) {
                    setState(() {
                      _currentUser = updatedUser;
                      // Update pages to use the new user data
                      _pages[0] = HomeScreen(key: _homeKey, user: _currentUser);
                      _pages[2] = MoreScreen(user: _currentUser);
                    });
                    // Refresh home screen data
                    _homeKey.currentState?.loadInitialData();
                  }
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
                      backgroundColor: theme.primaryColor, // Use primary as background for initials
                      backgroundImage: _currentUser.profile.url.isNotEmpty
                          ? NetworkImage(_currentUser.profile.url)
                          : null,
                      onBackgroundImageError: _currentUser.profile.url.isNotEmpty
                          ? (e, s) => debugPrint("Profile image load error: $e")
                          : null,
                      child: _currentUser.profile.url.isEmpty
                          ? Text(
                              _currentUser.profile.initials.isNotEmpty 
                                  ? _currentUser.profile.initials 
                                  : _currentUser.name.isNotEmpty 
                                      ? _currentUser.name[0].toUpperCase() 
                                      : "?",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white, // White text on primary background
                                fontSize: 13,
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
                onTap: _goToNotifications,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(Icons.notifications_outlined,
                          color: iconColor, size: 26),
                      if (_unreadCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5252),
                              shape: BoxShape.circle,
                              border: Border.all(color: glassColor, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF5252).withOpacity(0.3),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                )
                              ],
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Center(
                              child: Text(
                                _unreadCount > 9 ? "9+" : "$_unreadCount",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
