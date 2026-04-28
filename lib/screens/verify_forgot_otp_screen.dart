import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_toasts.dart';
import 'reset_password_screen.dart';

class VerifyForgotOtpScreen extends StatefulWidget {
  final String email;

  const VerifyForgotOtpScreen({super.key, required this.email});

  @override
  State<VerifyForgotOtpScreen> createState() => _VerifyForgotOtpScreenState();
}

class _VerifyForgotOtpScreenState extends State<VerifyForgotOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final otpController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  void verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      String resetToken = await ApiService.verifyForgotPasswordOtp(
        email: widget.email,
        otp: otpController.text.trim(),
      );

      if (mounted) {
        AppToasts.success(context, "OTP verified successfully!");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(
              token: resetToken,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("OTP verification error: $e");
      if (mounted) {
        setState(() => isLoading = false);
        AppToasts.error(context, e.toString().replaceAll("Exception: ", ""));
      }
    }
  }

  void resendOtp() async {
     try {
      await ApiService.forgotPassword(email: widget.email);
      if (mounted) AppToasts.success(context, "OTP resent successfully!");
    } catch (e) {
      if (mounted) AppToasts.error(context, e.toString().replaceAll("Exception: ", ""));
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
                    const Icon(Icons.mark_email_unread_outlined, size: 80, color: Colors.white),
                    const SizedBox(height: 24),
                    const Text(
                      "Verify OTP",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Enter the 6-digit code sent to ${widget.email}",
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
                                  controller: otpController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  decoration: _modernInputStyle(context, "6-Digit Code", icon: Icons.lock_clock_outlined).copyWith(
                                    counterText: "",
                                  ),
                                  style: TextStyle(
                                    color: Theme.of(context).brightness == Brightness.dark 
                                        ? Colors.white 
                                        : Colors.black87,
                                    letterSpacing: 8,
                                  ),
                                  validator: (v) => v!.length < 6 ? "Enter 6 digits" : null,
                                ),
                                const SizedBox(height: 20),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: resendOtp,
                                    child: const Text(
                                      "Resend OTP",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
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
                                      onPressed: isLoading ? null : verifyOtp,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                      ),
                                      child: isLoading
                                          ? const CircularProgressIndicator(color: Colors.white)
                                          : const Text(
                                              "VERIFY",
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
