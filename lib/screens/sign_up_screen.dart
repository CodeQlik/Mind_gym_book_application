import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../screens/login_screen.dart';

import '../services/api_service.dart';
import '../models/user_register_model.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final additionalPhoneController = TextEditingController();
  final otpController = TextEditingController();

  // State Variables
  Uint8List? webImage;
  File? profileImage;
  bool isLoading = false;
  bool isEmailFilled = false;
  bool showOtpField = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    additionalPhoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  // ================= ACTIONS =================

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          webImage = bytes;
          profileImage = null;
        });
      } else {
        setState(() {
          profileImage = File(picked.path);
          webImage = null;
        });
      }
    }
  }

  Future<void> verifyThenRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!showOtpField) {
      _showSnackBar("Please click 'Verify' to get an OTP first");
      return;
    }

    setState(() => isLoading = true);

    try {
      // 1. Verify Email
      await ApiService.verifyEmail(
        email: emailController.text.trim(),
        otp: otpController.text.trim(),
      );

      // 2. Register User
      UserModel user = await ApiService.registerUser(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        phone: phoneController.text.trim(),
        additionalPhone: additionalPhoneController.text.trim(),
        profileImage: profileImage,
        webImage: webImage,
      );

      setState(() => isLoading = false);
      
      if (mounted) {
        _showSnackBar("Welcome ${user.name}! Registration successful");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) _showSnackBar(e.toString());
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ================= UI BUILDERS =================

  InputDecoration _modernInputStyle(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 15),
      prefixIcon: icon != null ? Icon(icon, color: Colors.grey.shade600) : null,
      filled: true,
      fillColor: Colors.white.withOpacity(0.9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.white, width: 2),
      ),
    );
  }

  Widget _buildGradientBackground() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667EEA), // Soft Blue
            Color(0xFF764BA2), // Deep Purple
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return GestureDetector(
      onTap: pickImage,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 45,
              backgroundColor: Colors.grey.shade200,
              child: ClipOval(
                child: webImage != null
                    ? Image.memory(webImage!, width: 90, height: 90, fit: BoxFit.cover)
                    : profileImage != null
                        ? Image.file(profileImage!, width: 90, height: 90, fit: BoxFit.cover)
                        : Icon(Icons.person, size: 45, color: Colors.grey.shade400),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt, size: 18, color: Color(0xFF764BA2)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailVerificationRow() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: emailController,
              decoration: _modernInputStyle("Email Address", icon: Icons.email_outlined).copyWith(
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
                prefixIcon: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(Icons.email_outlined, color: Colors.grey),
                ),
              ),
              validator: (v) => v!.isEmpty ? "Enter email" : null,
              onChanged: (value) {
                setState(() {
                  isEmailFilled = value.trim().isNotEmpty;
                  showOtpField = false;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              onPressed: isEmailFilled
                  ? () async {
                      try {
                        bool success = await ApiService.sendOtp(email: emailController.text.trim());
                        if (success) {
                          setState(() => showOtpField = true);
                          if (mounted) _showSnackBar("OTP sent!");
                        }
                      } catch (e) {
                         if (mounted) _showSnackBar(e.toString());
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isEmailFilled ? const Color(0xFF764BA2) : Colors.grey.shade300,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: const Text("Verify", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF764BA2).withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : verifyThenRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                "CREATE ACCOUNT",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _buildGradientBackground(),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Create Account",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Join us and start your journey",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // GLASS CARD FORM
                    ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                spreadRadius: -5,
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                _buildProfileAvatar(),
                                const SizedBox(height: 25),

                                TextFormField(
                                  controller: nameController,
                                  decoration: _modernInputStyle("Full Name", icon: Icons.person_outline),
                                  validator: (v) => v!.isEmpty ? "Enter name" : null,
                                ),
                                const SizedBox(height: 16),

                                _buildEmailVerificationRow(),

                                if (showOtpField) ...[
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: otpController,
                                    keyboardType: TextInputType.number,
                                    maxLength: 6,
                                    decoration: _modernInputStyle("Enter 6-digit OTP", icon: Icons.lock_clock_outlined).copyWith(
                                      counterText: "",
                                      suffixIcon: TextButton(
                                        onPressed: () {
                                          ApiService.sendOtp(email: emailController.text.trim());
                                          _showSnackBar("OTP resent");
                                        },
                                        child: const Text("Resend", style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    validator: (v) => v!.isEmpty ? "Enter OTP" : null,
                                  ),
                                ],

                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: passwordController,
                                  obscureText: true,
                                  decoration: _modernInputStyle("Password", icon: Icons.lock_outline),
                                  validator: (v) => v!.length < 6 ? "Min 6 characters" : null,
                                ),
                                const SizedBox(height: 16),

                                TextFormField(
                                  controller: phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: _modernInputStyle("Phone Number", icon: Icons.phone_outlined),
                                  validator: (v) => v!.isEmpty ? "Enter phone" : null,
                                ),
                                const SizedBox(height: 16),

                                TextFormField(
                                  controller: additionalPhoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: _modernInputStyle("Additional Phone", icon: Icons.phone_android_outlined),
                                ),
                                const SizedBox(height: 30),

                                _buildSignUpButton(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account?",
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                            );
                          },
                          child: const Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}