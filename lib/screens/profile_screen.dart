import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';

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

  // Editing State
  bool _isEditing = false;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _additionalPhoneController;

  File? _selectedImage;
  LoginModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _additionalPhoneController = TextEditingController();
    _profileFuture = _fetchProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _additionalPhoneController.dispose();
    super.dispose();
  }

  Future<LoginModel> _fetchProfile() async {
    String? token = widget.user?.token;
    if (token == null || token.isEmpty) {
      final savedUser = await AuthService.getUser();
      token = savedUser?.token;
    }

    if (token != null && token.isNotEmpty) {
      try {
        final LoginModel user = await ApiService.getUserProfile(token);
        // If we have a stored token, but fetched profile doesn't have it (likely), reuse the stored one
        final userWithToken = LoginModel(
            id: user.id,
            userType: user.userType,
            name: user.name,
            email: user.email,
            phone: user.phone,
            additionalPhone: user.additionalPhone,
            profile: user.profile,
            isActive: user.isActive,
            isVerified: user.isVerified,
            createdAt: user.createdAt,
            updatedAt: user.updatedAt,
            subscriptionStatus: user.subscriptionStatus,
            subscriptionPlan: user.subscriptionPlan,
            subscriptionEndDate: user.subscriptionEndDate,
            token: token // Keep the token used for request
            );

        setState(() {
          _currentUser = userWithToken;
        });
        return userWithToken;
      } catch (e) {
        if (widget.user != null) {
          setState(() => _currentUser = widget.user!);
          return widget.user!;
        }
        throw Exception("Failed to load profile: $e");
      }
    } else {
      throw Exception("No authentication token found");
    }
  }

  void _toggleEdit() {
    if (_isEditing) {
      // Cancel Editing
      setState(() {
        _isEditing = false;
        _selectedImage = null;
      });
    } else {
      // Start Editing
      if (_currentUser != null) {
        _nameController.text = _currentUser!.name;
        _emailController.text = _currentUser!.email;
        _phoneController.text = _currentUser!.phone;
        _additionalPhoneController.text = _currentUser!.additionalPhone;
        setState(() {
          _isEditing = true;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      final LoginModel updatedUser = await ApiService.updateProfile(
        token: _currentUser!.token,
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        additionalPhone: _additionalPhoneController.text,
        profileImage: _selectedImage,
      );

      // Save to local storage
      await AuthService.saveUser(updatedUser);

      setState(() {
        _currentUser = updatedUser;
        _profileFuture = Future.value(updatedUser);
        _isEditing = false;
        _selectedImage = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("My Profile", style: theme.appBarTheme.titleTextStyle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: theme.iconTheme,
        actions: [
          if (_currentUser != null)
            IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit),
              onPressed: _isLoading ? null : _toggleEdit,
              tooltip: _isEditing ? "Cancel" : "Edit Profile",
            ),
        ],
      ),
      body: FutureBuilder<LoginModel>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _currentUser == null) {
            return Center(
                child: CircularProgressIndicator(color: theme.primaryColor));
          } else if (snapshot.hasError && _currentUser == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text("Error: ${snapshot.error}",
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center),
                  TextButton(
                    onPressed: () =>
                        setState(() => _profileFuture = _fetchProfile()),
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          }

          final user = _currentUser ?? snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Profile Image
                  GestureDetector(
                    onTap: _isEditing ? _pickImage : null,
                    child: Center(
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
                                  color:
                                      const Color(0xFF667EEA).withOpacity(0.4),
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
                                backgroundImage: _selectedImage != null
                                    ? FileImage(_selectedImage!)
                                        as ImageProvider
                                    : (user.profile.url.isNotEmpty
                                        ? NetworkImage(user.profile.url)
                                        : null),
                                child: (_selectedImage == null &&
                                        user.profile.url.isEmpty)
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
                          if (_isEditing)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                        blurRadius: 5, color: Colors.black26)
                                  ],
                                ),
                                child: const Icon(Icons.camera_alt,
                                    color: Color(0xFF667EEA), size: 20),
                              ),
                            ),
                        ],
                      ),
                    )
                        .animate()
                        .scale(duration: 500.ms, curve: Curves.easeOutBack),
                  ),

                  const SizedBox(height: 24),

                  // Name Display (when not editing) or Field
                  if (!_isEditing) ...[
                    Text(
                      user.name,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    )
                        .animate(delay: 100.ms)
                        .fadeIn()
                        .slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 8),
                    Text(
                      user.userType.toUpperCase(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    )
                        .animate(delay: 150.ms)
                        .fadeIn()
                        .slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 40),
                  ],

                  if (_isEditing)
                    _buildTextField(
                        "Name", _nameController, Icons.person_outline),

                  if (_isEditing) const SizedBox(height: 16),

                  // Fields
                  _isEditing
                      ? Column(
                          children: [
                            _buildTextField("Email", _emailController,
                                Icons.email_outlined),
                            const SizedBox(height: 16),
                            _buildTextField("Phone", _phoneController,
                                Icons.phone_outlined),
                            const SizedBox(height: 16),
                            _buildTextField(
                                "Additional Phone",
                                _additionalPhoneController,
                                Icons.phone_android_outlined),
                          ],
                        )
                      : Column(
                          children: [
                            _buildInfoCard(Icons.email_outlined, "Email",
                                user.email, theme),
                            const SizedBox(height: 16),
                            _buildInfoCard(Icons.phone_outlined, "Phone",
                                user.phone, theme),
                            if (user.additionalPhone.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _buildInfoCard(Icons.phone_android_outlined,
                                  "Alt Phone", user.additionalPhone, theme),
                            ],
                          ]
                              .animate(interval: 100.ms)
                              .fadeIn()
                              .slideX(begin: 0.1, end: 0),
                        ),

                  const SizedBox(height: 30),

                  if (_isEditing)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF667EEA),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text("Update",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      validator: (value) {
        if (label == "Name" || label == "Email" || label == "Phone") {
          if (value == null || value.isEmpty) return "$label is required";
        }
        return null;
      },
    );
  }

  Widget _buildInfoCard(
      IconData icon, String title, String value, ThemeData theme) {
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
              color: theme.scaffoldBackgroundColor,
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
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
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
