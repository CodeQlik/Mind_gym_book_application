import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_toasts.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;

  const ResetPasswordScreen({super.key, required this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (passwordController.text != confirmPasswordController.text) {
      AppToasts.error(context, "Passwords do not match");
      return;
    }

    setState(() => isLoading = true);

    try {
      bool success = await ApiService.resetPassword(
        token: widget.token,
        newPassword: passwordController.text.trim(),
        confirmPassword: confirmPasswordController.text.trim(),
      );

      if (success && mounted) {
        AppToasts.success(context, "Password reset successfully! Please login.");
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
      setState(() => isLoading = false);
    } catch (e) {
      debugPrint("Reset password error: $e");
      if (mounted) {
        setState(() => isLoading = false);
        AppToasts.error(context, e.toString().replaceAll("Exception: ", ""));
      }
    }
  }

  InputDecoration _modernInputStyle(BuildContext context, String hint, {IconData? icon}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? Colors.white70 : Colors.grey.shade600, 
        fontSize: 15
      ),
      prefixIcon: icon != null 
          ? Icon(icon, color: isDark ? Colors.white70 : Colors.grey.shade600) 
          : null,
      filled: true,
      fillColor: isDark 
          ? Colors.white.withOpacity(0.1) 
          : Colors.white.withOpacity(0.9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(
          color: isDark ? Colors.white12 : Colors.transparent, 
          width: 1
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(
          color: isDark ? colorScheme.primary : Colors.white, 
          width: 2
        ),
      ),
    );
  }

  Widget _buildGradientBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark 
            ? [
                const Color(0xFF0F2027), 
                const Color(0xFF203A43),
                const Color(0xFF2C5364),
              ]
            : [
                const Color(0xFF667EEA), 
                const Color(0xFF764BA2), 
              ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.white),
      ),
      body: Stack(
        children: [
          _buildGradientBackground(context),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const Icon(Icons.password_rounded, size: 80, color: Colors.white),
                    const SizedBox(height: 24),
                    const Text(
                      "Set New Password",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Enter your new password below",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 40),
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
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: passwordController,
                                  obscureText: true,
                                  style: TextStyle(
                                    color: Theme.of(context).brightness == Brightness.dark 
                                        ? Colors.white 
                                        : Colors.black87
                                  ),
                                  decoration: _modernInputStyle(context, "New Password", icon: Icons.lock_outline),
                                  validator: (v) => v!.length < 6 ? "Minimum 6 characters" : null,
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: confirmPasswordController,
                                  obscureText: true,
                                  style: TextStyle(
                                    color: Theme.of(context).brightness == Brightness.dark 
                                        ? Colors.white 
                                        : Colors.black87
                                  ),
                                  decoration: _modernInputStyle(context, "Confirm Password", icon: Icons.lock_reset),
                                  validator: (v) => v!.isEmpty ? "Confirm your password" : null,
                                ),
                                const SizedBox(height: 30),
                                SizedBox(
                                  width: double.infinity,
                                  height: 55,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                                      ),
                                    ),
                                    child: ElevatedButton(
                                      onPressed: isLoading ? null : resetPassword,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                      ),
                                      child: isLoading
                                          ? const CircularProgressIndicator(color: Colors.white)
                                          : const Text(
                                              "RESET PASSWORD",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.1,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
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
