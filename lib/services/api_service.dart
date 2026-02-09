import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/user_register_model.dart';
import '../models/book_model.dart';
import '../models/login_model.dart';
import '../utils/constants.dart';

class ApiService {
  static const String baseUrl = "https://mindgymbook.ductfabrication.in";

  // ================= FETCH BOOKS (Google Books API) =================
  static Future<List<BookModel>> fetchBooks(String category, {int startIndex = 0, int maxResults = 20}) async {
    // Queries: subject:fiction, subject:history, etc.
    final uri = Uri.parse(
        "https://www.googleapis.com/books/v1/volumes?q=subject:$category&startIndex=$startIndex&maxResults=$maxResults&key=${Constants.googleBooksApiKey}");
    
    return _getBooksFromUri(uri);
  }

  // ================= SEARCH BOOKS =================
  static Future<List<BookModel>> searchBooks(String query, {int startIndex = 0, int maxResults = 20}) async {
    final uri = Uri.parse(
        "https://www.googleapis.com/books/v1/volumes?q=$query&startIndex=$startIndex&maxResults=$maxResults&key=${Constants.googleBooksApiKey}");
    
    return _getBooksFromUri(uri);
  }

  static Future<List<BookModel>> _getBooksFromUri(Uri uri) async {
    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['items'] == null) return [];
        
        List<dynamic> items = jsonData['items'];
        return items.map((item) => BookModel.fromJson(item)).toList();
      } else {
        log("API Error: ${response.statusCode} - ${response.body}");
        throw Exception('Failed to load books');
      }
    } catch (e) {
      log("Error fetching books: $e");
      return [];
    }
  }

  // ================= REGISTER USER =================
  static Future<UserModel> registerUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String additionalPhone,
    File? profileImage,
    Uint8List? webImage,
  }) async {
    final uri = Uri.parse("$baseUrl/api/v1/users/register");
    final request = http.MultipartRequest('POST', uri);

    request.fields['name'] = name;
    request.fields['email'] = email;
    request.fields['password'] = password;
    request.fields['phone'] = phone;
    request.fields['additional_phone'] = additionalPhone;

    if (kIsWeb && webImage != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'profile_image',
          webImage,
          filename: 'profile.jpg',
        ),
      );
    } else if (!kIsWeb && profileImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath('profile_image', profileImage.path),
      );
    }

    final response = await request.send();
    final body = await response.stream.bytesToString();
    final jsonData = json.decode(body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (jsonData['success'] == true) {
        return UserModel.fromJson(jsonData['data']);
      } else {
        throw Exception(jsonData['message'] ?? 'Registration failed');
      }
    } else {
      throw Exception(jsonData['message'] ?? 'Server error');
    }
  }

  // ================= SEND OTP =================
  static Future<bool> sendOtp({required String email}) async {
    final uri = Uri.parse("$baseUrl/api/v1/users/send-otp");
    String apiUrl = "$baseUrl/api/v1/users/send-otp";
    log("Sending OTP to ${apiUrl}");
    print("Sending OTP to $uri");
    log("Request body: $email");
    var headers = {'Content-Type': 'application/json'};

    final response = await http.post(
      uri,
      body: json.encode({"email": "khushjalwal15@gmail.com"}),
      headers: headers,
    );

    response.headers.addAll(headers);

    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");
    final jsonData = jsonDecode(response.body);

    if (response.statusCode == 200 && jsonData["success"] == true) {
      return true;
    } else {
      throw Exception(jsonData["message"] ?? "Failed to send OTP");
    }
  }

  // ================= VERIFY EMAIL =================
  static Future<void> verifyEmail({
    required String email,
    required String otp,
  }) async {
    final uri = Uri.parse("$baseUrl/api/v1/users/verify-email");
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request(
      'POST',
      uri,
    );
    request.body = json.encode({
      "email": email,
      "otp": otp,
    });
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());
    } else {
      print(response.reasonPhrase);
    }
  }

  // ================= LOGIN USER =================
  static Future<LoginModel> loginUser({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse("$baseUrl/api/v1/users/login");
    var headers = {'Content-Type': 'application/json'};

    final response = await http.post(
      uri,
      body: json.encode({
        "email": email,
        "password": password,
      }),
      headers: headers,
    );

    print("Login Response: ${response.body}");
    final jsonData = jsonDecode(response.body);

    if (response.statusCode == 200 && jsonData['success'] == true) {
      // The 'data' field contains user info including token
      return LoginModel.fromJson(jsonData['data']);
    } else {
      throw Exception(jsonData['message'] ?? 'Login failed');
    }
  }

  // ================= GET USER PROFILE =================
  static Future<LoginModel> getUserProfile(String token) async {
    final uri = Uri.parse("$baseUrl/api/v1/users/profile");
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http.get(uri, headers: headers);

    log("Profile Response: ${response.body}");
    final jsonData = jsonDecode(response.body);

    if (response.statusCode == 200 && jsonData['success'] == true) {
      return LoginModel.fromJson(jsonData['data']);
    } else {
      throw Exception(jsonData['message'] ?? 'Failed to fetch profile');
    }
  }

  // ================= FETCH GUTENBERG BOOKS (Public Domain) =================
  static Future<List<BookModel>> fetchGutenbergBooks() async {
    final uri = Uri.parse("https://gutendex.com/books");
    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['results'] == null) return [];
        
        List<dynamic> items = jsonData['results'];
        return items.map((item) => BookModel.fromGutenbergJson(item)).toList();
      } else {
        log("Gutendex Error: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      log("Error fetching Gutenberg books: $e");
      return [];
    }
  }
}
