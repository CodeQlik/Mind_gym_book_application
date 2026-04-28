import 'dart:ui';
import 'package:flutter/material.dart';
import '../screens/sign_up_screen.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/login_model.dart';
import 'main_screen.dart';
import '../utils/app_toasts.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final LoginModel? user = await ApiService.loginUser(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (user == null) return;

      if (mounted) {
        debugPrint("Login success: ${user.name} (ID: ${user.id})");
        debugPrint(
            "Token extracted: ${user.token.substring(0, user.token.length > 10 ? 10 : user.token.length)}...");
        // Save user to shared preferences for persistence
        await AuthService.saveUser(user);
        debugPrint(
            "User saved with token length: ${user.token.length}. Navigating...");

        setState(() => isLoading = false);
        AppToasts.success(context, "Welcome back, ${user.name}!");

        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => MainScreen(user: user)),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      debugPrint("Login error: $e");
      if (mounted) {
        setState(() => isLoading = false);
        AppToasts.error(context, e.toString().replaceAll("Exception: ", ""));
      }
    }
  }



  // ================= UI BUILDERS =================

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
                const Color(0xFF0F2027), // Deep Space Black/Blue
                const Color(0xFF203A43),
                const Color(0xFF2C5364),
              ]
            : [
                const Color(0xFF667EEA), // Soft Blue
                const Color(0xFF764BA2), // Deep Purple
              ],
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
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
        onPressed: isLoading ? null : login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                "LOGIN",
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
          _buildGradientBackground(context),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Welcome Back",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 4)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Sign in to continue",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 40),

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
                            border: Border.all(
                                color: Colors.white.withOpacity(0.2)),
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
                                const SizedBox(height: 10),

                                TextFormField(
                                  controller: emailController,
                                  style: TextStyle(
                                    color: Theme.of(context).brightness == Brightness.dark 
                                        ? Colors.white 
                                        : Colors.black87
                                  ),
                                  decoration: _modernInputStyle(context, "Email Address",
                                      icon: Icons.email_outlined),
                                  validator: (v) =>
                                      v!.isEmpty ? "Enter email" : null,
                                ),
                                const SizedBox(height: 20),

                                TextFormField(
                                  controller: passwordController,
                                  obscureText: true,
                                  style: TextStyle(
                                    color: Theme.of(context).brightness == Brightness.dark 
                                        ? Colors.white 
                                        : Colors.black87
                                  ),
                                  decoration: _modernInputStyle(context, "Password",
                                      icon: Icons.lock_outline),
                                  validator: (v) =>
                                      v!.isEmpty ? "Enter password" : null,
                                ),

                                const SizedBox(height: 15),

                                // Forgot Password
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => const ForgotPasswordScreen()),
                                      );
                                    },
                                    child: Text(
                                      "Forgot Password?",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 30),

                                _buildLoginButton(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
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
                              MaterialPageRoute(
                                  builder: (context) => const SignUpScreen()),
                            );
                          },
                          child: const Text(
                            "Sign Up",
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
