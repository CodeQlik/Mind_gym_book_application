import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/login_model.dart';
import 'package:flutter/material.dart';

class AuthService {
  static const String _userKey = 'user_data';

  // Save User
  static Future<void> saveUser(LoginModel user) async {
    final prefs = await SharedPreferences.getInstance();
    String userJson = jsonEncode(user.toJson());
    await prefs.setString(_userKey, userJson);
    debugPrint("User saved to SharedPreferences");
  }

  // Get User
  static Future<LoginModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString(_userKey);
    if (userJson == null) return null;

    try {
      Map<String, dynamic> userMap = jsonDecode(userJson);
      return LoginModel.fromJson(userMap);
    } catch (e) {
      debugPrint("Error parsing user data: $e");
      return null;
    }
  }

  // Logout (Clear User)
  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
}
