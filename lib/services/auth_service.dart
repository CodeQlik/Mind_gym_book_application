import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/login_model.dart';
import 'package:flutter/material.dart';

class AuthService {
  static const String _userKey = 'user_data';

  // Save User
  static Future<void> saveUser(LoginModel user) async {
    if (user.token.isEmpty) {
      debugPrint(
          "AuthService: WARNING - Attempted to save user with empty token. Aborting save to prevent session loss.");
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    String userJson = jsonEncode(user.toJson());
    await prefs.setString(_userKey, userJson);
    debugPrint(
        "User saved to SharedPreferences (Token length: ${user.token.length})");
  }

  // Get User
  static Future<LoginModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString(_userKey);
    if (userJson == null) {
      debugPrint("AuthService: No user data found in SharedPreferences");
      return null;
    }

    debugPrint("AuthService: Raw user data from prefs: $userJson");

    try {
      Map<String, dynamic> userMap = jsonDecode(userJson);
      final user = LoginModel.fromJson(userMap);

      if (user.token.isEmpty) {
        debugPrint(
            "AuthService: Found user in prefs but token is empty. Treating as logged out.");
        return null;
      }

      debugPrint(
          "AuthService: Successfully parsed user: ${user.name}, Token length: ${user.token.length}");
      return user;
    } catch (e) {
      debugPrint("AuthService: Error parsing user data: $e");
      return null;
    }
  }

  // Logout (Clear User)
  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  // Update only token
  static Future<void> updateToken(String newToken) async {
    final user = await getUser();
    if (user != null) {
      await saveUser(user.copyWith(token: newToken));
      debugPrint("AuthService: Token updated in local storage");
    }
  }
}
