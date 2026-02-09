import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mind_gym_book/screens/login_screen.dart';
import '../models/login_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final LoginModel? user;

  const ProfileScreen({super.key, this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<LoginModel> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfile();
  }

  Future<LoginModel> _fetchProfile() async {
    String? token = widget.user?.token;
    if (token == null || token.isEmpty) {
      final savedUser = await AuthService.getUser();
      token = savedUser?.token;
    }

    if (token != null && token.isNotEmpty) {
      try {
        return await ApiService.getUserProfile(token);
      } catch (e) {
        if (widget.user != null) return widget.user!;
        throw Exception("Failed to load profile: $e");
      }
    } else {
      throw Exception("No authentication token found");
    }
  }

  Future<void> _logout() async {
    await AuthService.clearUser();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "My Profile",
          style: theme.appBarTheme.titleTextStyle,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: theme.iconTheme,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFFF5252)),
            onPressed: _logout,
          ),
        ],
      ),
      body: FutureBuilder<LoginModel>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: theme.primaryColor));
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    "Error loading profile",
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _profileFuture = _fetchProfile();
                      });
                    },
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasData) {
            final user = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Profile Image
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF667EEA).withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.white,
                              backgroundImage: user.profile.url.isNotEmpty
                                  ? NetworkImage(user.profile.url)
                                  : null,
                              onBackgroundImageError: user.profile.url.isNotEmpty
                                  ? (_, __) {}
                                  : null,
                              child: user.profile.url.isEmpty
                                  ? Text(
                                      user.profile.initials,
                                      style: const TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF667EEA),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),

                  const SizedBox(height: 24),

                  // Name
                  Text(
                    user.name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 8),
                  Text(
                    user.userType.toUpperCase(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 40),

                  // Info Cards
                  Column(
                    children: [
                      _buildInfoCard(Icons.email_outlined, "Email", user.email, theme),
                      const SizedBox(height: 16),
                      _buildInfoCard(Icons.phone_outlined, "Phone", user.phone, theme),
                      if (user.additionalPhone.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildInfoCard(Icons.phone_android_outlined, "Alt Phone", user.additionalPhone, theme),
                      ],
                    ].animate(interval: 100.ms).fadeIn().slideX(begin: 0.1, end: 0),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            );
          } else {
            return const Center(child: Text("No user data found"));
          }
        },
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor, // Slight contrast
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.primaryColor, size: 22),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
