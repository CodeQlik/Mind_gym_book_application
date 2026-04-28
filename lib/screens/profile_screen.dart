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
    LoginModel? savedUser;
    if (token == null || token.isEmpty) {
      savedUser = await AuthService.getUser();
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
            token: token, // Keep the token used for request
            refreshToken: savedUser?.refreshToken ?? user.refreshToken);

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
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // Compresses image to avoid server-side size limits
    );

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
        Navigator.pop(context, updatedUser);
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

  Future<void> _changePassword(String oldPass, String newPass, String confirmPass) async {
    if (_currentUser == null) return;
    
    try {
      final success = await ApiService.changePassword(
        token: _currentUser!.token,
        oldPassword: oldPass,
        newPassword: newPass,
        confirmPassword: confirmPass,
      );
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password changed successfully")),
        );
        Navigator.pop(context); // Close dialog
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showChangePasswordDialog() {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();
    bool dialCodeIsLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Change Password", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Form(
              key: dialogFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogTextField("Old Password", oldPassController, true),
                  const SizedBox(height: 16),
                  _buildDialogTextField("New Password", newPassController, true),
                  const SizedBox(height: 16),
                  _buildDialogTextField("Confirm Password", confirmPassController, true),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: dialCodeIsLoading ? null : () async {
                if (dialogFormKey.currentState!.validate()) {
                  if (newPassController.text != confirmPassController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("New passwords do not match")),
                    );
                    return;
                  }
                  
                  setDialogState(() => dialCodeIsLoading = true);
                  await _changePassword(
                    oldPassController.text,
                    newPassController.text,
                    confirmPassController.text,
                  );
                  if (mounted) setDialogState(() => dialCodeIsLoading = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF764BA2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: dialCodeIsLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Change"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogTextField(String label, TextEditingController controller, bool isPassword) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: (v) => v!.isEmpty ? "Required" : (isPassword && v.length < 6 ? "Min 6 chars" : null),
    );
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
              icon: Icon(_isEditing ? Icons.close_rounded : Icons.edit_rounded),
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
                    const SizedBox(height: 20),
                  ],

                  if (_isEditing)
                    _buildTextField(
                        "Name", _nameController, Icons.person_outline),

                  if (_isEditing) const SizedBox(height: 20),

                  // Fields
                  _isEditing
                      ? Column(
                          children: [
                            _buildTextField("Email", _emailController,
                                Icons.email_outlined),
                            const SizedBox(height: 20),
                            _buildTextField("Phone", _phoneController,
                                Icons.phone_outlined),
                            const SizedBox(height: 20),
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
                    Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF667EEA).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text("Update Profile",
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5)),
                      ),
                    ),
                  
                  if (!_isEditing) ...[
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _showChangePasswordDialog,
                      icon: const Icon(Icons.lock_reset_rounded, color: Color(0xFF764BA2)),
                      label: const Text(
                        "Change Password",
                        style: TextStyle(
                          color: Color(0xFF764BA2),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: const BorderSide(color: Color(0xFF764BA2), width: 1.5),
                        ),
                      ),
                    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2, end: 0),
                  ],
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF2D3142),
              fontWeight: FontWeight.w600,
              fontSize: 14,
              letterSpacing: 0.3,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF2D3142),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF667EEA), size: 22),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: isDark
                  ? BorderSide.none
                  : BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: isDark
                  ? BorderSide.none
                  : BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFF667EEA), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            hintText: "Enter your $label",
            hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey.withOpacity(0.5)),
          ),
          validator: (value) {
            if (label == "Name" || label == "Email" || label == "Phone") {
              if (value == null || value.isEmpty) return "$label is required";
            }
            if (label == "Email" && value != null && value.isNotEmpty) {
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value)) {
                return "Enter a valid email address";
              }
            }
            return null;
          },
        ),
      ],
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
