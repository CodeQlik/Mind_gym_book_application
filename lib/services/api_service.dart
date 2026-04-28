import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/user_register_model.dart';
import '../models/book_model.dart';
import '../models/login_model.dart';
import '../models/note_model.dart';
import '../models/notification_model.dart';
import '../models/subscription_plan_model.dart';
import '../models/highlight_model.dart';
import '../utils/constants.dart';
import 'auth_service.dart';

class ApiService {
  static const String baseUrl = "https://mindgymbook.ductfabrication.in";

  // ================= FETCH BOOKS (Google Books API) =================
  static Future<List<BookModel>> fetchBooks(String category,
      {int startIndex = 0, int maxResults = 20}) async {
    final uri = Uri.parse(
        "https://www.googleapis.com/books/v1/volumes?q=subject:$category&startIndex=$startIndex&maxResults=$maxResults&key=${Constants.googleBooksApiKey}");

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'] ?? [];
        return items.map((item) => BookModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching books: $e");
      return [];
    }
  }

  static Future<List<BookModel>> searchBooks(String query,
      {int startIndex = 0, int maxResults = 20}) async {
    final uri = Uri.parse(
        "https://www.googleapis.com/books/v1/volumes?q=$query&startIndex=$startIndex&maxResults=$maxResults&key=${Constants.googleBooksApiKey}");

    return _getBooksFromUri(uri);
  }

  static Future<List<BookModel>> _getBooksFromUri(Uri uri) async {
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'] ?? [];
        return items.map((item) => BookModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Error: $e");
      return [];
    }
  }

  // ================= AUTHENTICATION & PROFILE =================

  static Future<UserModel> registerUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String additionalPhone,
    required String verificationToken,
    File? profileImage,
    Uint8List? webImage,
  }) async {
    final uri = Uri.parse("$baseUrl/api/v1/users/register");
    var request = http.MultipartRequest('POST', uri);

    request.fields['name'] = name;
    request.fields['email'] = email;
    request.fields['password'] = password;
    request.fields['phone'] = phone;
    request.fields['additional_phone'] = additionalPhone;
    request.fields['verificationToken'] = verificationToken;

    if (kIsWeb && webImage != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'profileImage',
        webImage,
        filename: 'profile.jpg',
      ));
    } else if (profileImage != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'profileImage',
        profileImage.path,
      ));
    }

      try {
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);
        final data = _processResponse(response);
        return UserModel.fromJson(data['data']);
      } catch (e) {
        debugPrint("Registration error: $e");
        rethrow;
      }
  }

  static Future<bool> sendOtp({required String email}) async {
    final uri = Uri.parse("$baseUrl/api/v1/users/send-registration-otp");
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );
      final data = _processResponse(response);
      return data['success'] == true;
    } catch (e) {
      debugPrint("sendOtp error: $e");
      return false;
    }
  }

  static Future<String> verifyEmail({
    required String email,
    required String otp,
  }) async {
    final uri = Uri.parse("$baseUrl/api/v1/users/verify-registration-otp");
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'otp': otp}),
      );
      final data = _processResponse(response);
      return data['data']['verificationToken'];
    } catch (e) {
      debugPrint("verifyEmail error: $e");
      rethrow;
    }
  }

  // ================= FORGOT PASSWORD =================

  static Future<bool> forgotPassword({required String email}) async {
    final uri = Uri.parse("$baseUrl/api/v1/users/forgot-password");
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );
      final data = _processResponse(response);
      return data['success'] == true;
    } catch (e) {
      debugPrint("forgotPassword error: $e");
      rethrow;
    }
  }

  static Future<String> verifyForgotPasswordOtp({
    required String email,
    required String otp,
  }) async {
    final uri = Uri.parse("$baseUrl/api/v1/users/verify-forgot-password-otp");
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'otp': otp}),
      );
      final data = _processResponse(response);
      return data['data']['resetToken'];
    } catch (e) {
      debugPrint("verifyForgotPasswordOtp error: $e");
      rethrow;
    }
  }

  static Future<bool> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final uri = Uri.parse("$baseUrl/api/v1/users/reset-password");
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': token,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        }),
      );
      final data = _processResponse(response);
      return data['success'] == true;
    } catch (e) {
      debugPrint("resetPassword error: $e");
      rethrow;
    }
  }

  static Future<LoginModel?> loginUser({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse("$baseUrl/api/v1/users/login");
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      final responseBody = _processResponse(response);
      if (response.statusCode == 200) {
        // 1. Extract the nested data object
        Map<String, dynamic> userData = responseBody['data'] is Map
            ? Map<String, dynamic>.from(responseBody['data'])
            : {};

        // 2. Extract Token with multi-key support
        String? tokenValue = responseBody['token']?.toString() ??
            responseBody['accessToken']?.toString() ??
            responseBody['access_token']?.toString() ??
            responseBody['auth_token']?.toString() ??
            userData['token']?.toString() ??
            userData['accessToken']?.toString() ??
            userData['access_token']?.toString() ??
            userData['auth_token']?.toString();

        String? refreshTokenValue = responseBody['refreshToken']?.toString() ??
            responseBody['refresh_token']?.toString() ??
            userData['refreshToken']?.toString() ??
            userData['refresh_token']?.toString();

        // 3. Ensure keys are populated for the LoginModel
        if (tokenValue != null && tokenValue.isNotEmpty) {
          userData['token'] = tokenValue;
        } else {
          debugPrint("ApiService: FAILURE - No token found in response keys");
          throw Exception("Authentication token missing from server response");
        }

        if (refreshTokenValue != null) {
          userData['refreshToken'] = refreshTokenValue;
        }

        // 4. Map user_id to id if necessary for model compatibility
        if (userData['id'] == null && userData['user_id'] != null) {
          userData['id'] = userData['user_id'];
        }

        final user = LoginModel.fromJson(userData);
        if (user.token.isEmpty) {
          throw Exception("Internal Error: Failed to map token to model");
        }
        return user;
      } else {
        throw Exception(responseBody['message'] ?? "Login failed");
      }
    } catch (e) {
      debugPrint("Login error: $e");
      rethrow;
    }
  }

  static Future<bool> changePassword({
    required String token,
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final uri = Uri.parse("$baseUrl/api/v1/users/change-password");
    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'old_password': oldPassword,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        }),
      );
      final data = _processResponse(response);
      return data['success'] == true;
    } catch (e) {
      debugPrint("changePassword error: $e");
      rethrow;
    }
  }

  static Future<http.Response> _handleAuthenticatedRequest(
    Future<http.Response> Function(String currentToken) requestFn,
  ) async {
    final user = await AuthService.getUser();
    if (user == null) throw Exception("Please login to continue");

    var response = await requestFn(user.token);

    if (response.statusCode == 401 && user.refreshToken.isNotEmpty) {
      debugPrint("ApiService: 401 Detected. Attempting token refresh...");
      final newToken = await refreshAccessToken(user.refreshToken);
      if (newToken != null) {
        await AuthService.updateToken(newToken);
        debugPrint("ApiService: Retrying request with new token...");
        response = await requestFn(newToken);
      }
    }
    return response;
  }

  static dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 500) {
      throw Exception(
          "Server is currently unavailable (${response.statusCode}). Please try again later.");
    }

    dynamic data;
    try {
      data = json.decode(response.body);
    } catch (e) {
      debugPrint("ApiService: Failed to decode JSON. Status: ${response.statusCode}");
      if (response.body.startsWith('<!DOCTYPE html>')) {
        if (response.statusCode == 413) {
          throw Exception(
              "The image you selected is too large for the server. Please try a smaller file.");
        }
        if (response.statusCode == 404) {
          throw Exception("The requested service was not found (404).");
        }
        throw Exception("Server returned an invalid response (${response.statusCode}).");
      }
      throw Exception("Unexpected response format from server.");
    }

    if (data is Map<String, dynamic> && data['success'] == false) {
      throw Exception(data['message'] ?? "Request failed");
    }

    return data;
  }

  static Future<LoginModel> getUserProfile(String token) async {
    final uri = Uri.parse("$baseUrl/api/v1/users/profile");
    try {
      final response = await _handleAuthenticatedRequest((currentToken) =>
          http.get(uri, headers: {'Authorization': 'Bearer $currentToken'}));

      final data = _processResponse(response);
      Map<String, dynamic> userData = Map<String, dynamic>.from(data['data']);

      // Crucial: API might not return the token in profile response, so we re-inject it
      // We use the potentially NEW token from the refreshed request
      String activeToken = token;
      final authHeader = response.request?.headers['Authorization'];
      if (authHeader != null && authHeader.startsWith('Bearer ')) {
        activeToken = authHeader.substring(7);
      }

      if (userData['token'] == null || userData['token'].toString().isEmpty) {
        userData['token'] = activeToken;
      }
      final user = LoginModel.fromJson(userData);
      if (user.token.isEmpty) {
        throw Exception("Internal Error: Token lost during profile refresh");
      }
      return user;
    } catch (e) {
      debugPrint("Get profile error: $e");
      rethrow;
    }
  }

  static Future<LoginModel> updateProfile({
    required String token,
    required String name,
    required String email,
    required String phone,
    required String additionalPhone,
    File? profileImage,
  }) async {
    final uri = Uri.parse("$baseUrl/api/v1/users/update-profile");
    
    // The server expects a PUT or PATCH to /profile to update it
    var request = http.MultipartRequest('PUT', uri);
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['name'] = name;
    request.fields['email'] = email;
    request.fields['phone'] = phone;
    request.fields['additional_phone'] = additionalPhone;

    if (profileImage != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'profile_image', // Changed to profileImage to match registration
        profileImage.path,
      ));
    }

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      final data = _processResponse(response);
      Map<String, dynamic> userData = Map<String, dynamic>.from(data['data']);
      
      // Re-inject token as the update response might not include it
      if (userData['token'] == null || userData['token'].toString().isEmpty) {
        userData['token'] = token;
      }
      
      final user = LoginModel.fromJson(userData);
      if (user.token.isEmpty) {
        throw Exception("Internal Error: Token lost during profile update");
      }
      return user;
    } catch (e) {
      debugPrint("Update profile error: $e");
      rethrow;
    }
  }

  static Future<bool> logoutUser(String token) async {
    final uri = Uri.parse("$baseUrl/api/v1/users/logout");
    try {
      final response = await http.post(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = _processResponse(response);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      debugPrint("Logout error: $e");
      return false;
    }
  }

  // ================= BOOK OPERATIONS =================

  static Future<List<BookModel>> fetchGutenbergBooks() async {
    final uri = Uri.parse("https://gutendex.com/books/");
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = _processResponse(response);
        final List<dynamic> results = data['results'] ?? [];
        return results
            .map((item) => BookModel.fromGutenbergJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint("Gutenberg fetch error: $e");
      return [];
    }
  }

  static Future<bool> toggleBookmark(String bookId, String token) async {
    final uri = Uri.parse("$baseUrl/api/v1/book/bookmark/toggle");
    try {
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'bookId': bookId}),
      );
      final data = json.decode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      debugPrint("Toggle bookmark error: $e");
      return false;
    }
  }

  static Future<List<BookModel>> getBookmarks(String token) async {
    final uri = Uri.parse("$baseUrl/api/v1/book/bookmark/all");
    try {
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        dynamic booksData = data['data'];
        List<dynamic> booksList = [];

        if (booksData is List) {
          booksList = booksData;
        } else if (booksData is Map) {
          booksList =
              (booksData['books'] ?? booksData['data'] ?? []) as List<dynamic>;
        }

        return booksList.map((item) {
          if (item is Map && item['book'] != null) {
            return BookModel.fromMindGymJson(item['book']).copyWith(isBookmarked: true);
          }
          return BookModel.fromMindGymJson(item).copyWith(isBookmarked: true);
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Get bookmarks error: $e");
      return [];
    }
  }

  static Future<List<BookModel>> fetchMindGymBooks({String? token}) async {
    final uri = Uri.parse("$baseUrl/api/v1/book/all");
    try {
      http.Response response;

      // Use the injected token or try to get it from AuthService
      String? activeToken = token;
      if (activeToken == null || activeToken.isEmpty) {
        final user = await AuthService.getUser();
        activeToken = user?.token;
      }

      if (activeToken != null && activeToken.isNotEmpty) {
        // Authenticated request with auto-refresh on 401
        response = await _handleAuthenticatedRequest((currentToken) =>
            http.get(uri, headers: {'Authorization': 'Bearer $currentToken'}));
      } else {
        // Public request fallback
        response = await http.get(uri);
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        dynamic booksData = data['data'];
        List<dynamic> booksList = [];

        if (booksData is List) {
          booksList = booksData;
        } else if (booksData is Map) {
          final booksField = booksData['books'];
          if (booksField is List) {
            booksList = booksField;
          } else if (booksField is Map) {
            for (var categoryList in booksField.values) {
              if (categoryList is List) {
                booksList.addAll(categoryList);
              }
            }
          }
        } else {
          debugPrint(
              "Unexpected book data structure: ${booksData.runtimeType}");
        }

        return booksList
            .map((item) =>
                BookModel.fromMindGymJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint("MindGym fetch error: $e");
      return [];
    }
  }

  static Future<BookModel?> getBookById(String id, {String? token}) async {
    final uri = Uri.parse("$baseUrl/api/v1/book/$id");
    try {
      http.Response response;

      String? activeToken = token;
      if (activeToken == null || activeToken.isEmpty) {
        final user = await AuthService.getUser();
        activeToken = user?.token;
      }

      if (activeToken != null && activeToken.isNotEmpty) {
        response = await _handleAuthenticatedRequest((currentToken) =>
            http.get(uri, headers: {'Authorization': 'Bearer $currentToken'}));
      } else {
        response = await http.get(uri);
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BookModel.fromMindGymJson(data['data']);
      }
      return null;
    } catch (e) {
      debugPrint("Get book by id error: $e");
      return null;
    }
  }

  // ================= NOTES =================

  static Future<List<NoteModel>> getAllNotes(String token) async {
    final uri = Uri.parse("$baseUrl/api/v1/note/getAllNotes");
    try {
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> notes = data['data'] ?? [];
        return notes.map((item) => NoteModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Get notes error: $e");
      return [];
    }
  }

  static Future<bool> saveNote({
    required String token,
    required String title,
    required String chapterName,
    required String content,
  }) async {
    final uri = Uri.parse("$baseUrl/api/v1/note/saveNote");
    try {
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'title': title,
          'chapter_name': chapterName,
          'content': content,
        }),
      );
      final data = json.decode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      debugPrint("Save note error: $e");
      return false;
    }
  }

  static Future<bool> deleteNote(int id, String token) async {
    final uri = Uri.parse("$baseUrl/api/v1/note/deleteNote/$id");
    try {
      final response = await http.delete(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = json.decode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      debugPrint("Delete note error: $e");
      return false;
    }
  }

  static Future<bool> updateNote({
    required int id,
    required String token,
    required String title,
    required String chapterName,
    required String content,
  }) async {
    final uri = Uri.parse("$baseUrl/api/v1/note/updateNote/$id");
    try {
      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'title': title,
          'chapter_name': chapterName,
          'content': content,
        }),
      );
      final data = json.decode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      debugPrint("Update note error: $e");
      return false;
    }
  }

  // ================= READING =================

  static Future<Map<String, dynamic>?> getBookContent(
      String bookId, String token) async {
    final uri = Uri.parse("$baseUrl/api/v1/book/content/$bookId");

    try {
      final response = await _handleAuthenticatedRequest((currentToken) =>
          http.get(uri, headers: {'Authorization': 'Bearer $currentToken'}));

      final jsonData = json.decode(response.body);

      if (response.statusCode == 200 && jsonData['success'] == true) {
        return jsonData['data'];
      }
      return null;
    } catch (e) {
      debugPrint("Get Book Content Error: $e");
      return null;
    }
  }

  // ================= NOTIFICATIONS =================

  static Future<List<NotificationModel>> getNotifications(String token) async {
    final uri = Uri.parse("$baseUrl/api/v1/notifications/");
    try {
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> notifications = data['data']['notifications'] ?? [];
        return notifications
            .map((item) => NotificationModel.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint("ApiService: getNotifications error: $e");
      return [];
    }
  }

  static Future<int> getUnreadNotificationCount(String token) async {
    final uri = Uri.parse("$baseUrl/api/v1/notifications/unread-count");
    try {
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['count'] ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint("ApiService: getUnreadNotificationCount error: $e");
      return 0;
    }
  }

  static Future<bool> markNotificationAsRead(String token, int id) async {
    final uri = Uri.parse("$baseUrl/api/v1/notifications/$id/read");
    try {
      debugPrint("ApiService: PATCH to $uri");
      final response = await http.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({}), // Some backends require a body for PUT
      );
      debugPrint("ApiService: Mark read response: ${response.statusCode} - ${response.body}");
      final data = json.decode(response.body);
      return (response.statusCode == 200 || response.statusCode == 201) && 
             (data['success'] == true || data['message']?.toString().contains('success') == true);
    } catch (e) {
      debugPrint("ApiService: markNotificationAsRead error: $e");
      return false;
    }
  }

  static Future<bool> markAllNotificationsAsRead(String token) async {
    final uri = Uri.parse("$baseUrl/api/v1/notifications/mark-all-read");
    try {
      debugPrint("ApiService: PATCH to $uri");
      final response = await http.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({}),
      );
      debugPrint("ApiService: Mark all read response: ${response.statusCode} - ${response.body}");
      final data = json.decode(response.body);
      return (response.statusCode == 200 || response.statusCode == 201) && 
             (data['success'] == true || data['message']?.toString().contains('success') == true);
    } catch (e) {
      debugPrint("ApiService: markAllNotificationsAsRead error: $e");
      return false;
    }
  }


  // ================= SUBSCRIPTION =================

  static Future<List<SubscriptionPlanModel>> getSubscriptionPlans() async {
    final uri = Uri.parse("$baseUrl/api/v1/plans/");
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> plansJson = data['data'] ?? [];
          return plansJson
              .map((plan) => SubscriptionPlanModel.fromJson(plan))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint("ApiService: Error fetching plans: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>?> createSubscriptionOrder({
    required String token,
    required String planType,
  }) async {
    final uri = Uri.parse("$baseUrl/api/v1/payment/create-subscription-order");
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      debugPrint("ApiService: Posting to $uri with plan_type: $planType");
      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode({"plan_type": planType}),
      );

      debugPrint(
          "ApiService: Order Response: ${response.statusCode} - ${response.body}");
      final jsonData = json.decode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          jsonData['success'] == true) {
        return jsonData['data'];
      } else {
        throw Exception(
            jsonData['message'] ?? "Server error (${response.statusCode})");
      }
    } catch (e) {
      debugPrint("ApiService: Error creating order: $e");
      rethrow;
    }
  }

  static Future<bool> verifySubscriptionPayment({
    required String token,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final uri = Uri.parse("$baseUrl/api/v1/payment/verify");

    try {
      final response =
          await _handleAuthenticatedRequest((currentToken) => http.post(
                uri,
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $currentToken',
                },
                body: json.encode({
                  "razorpay_order_id": razorpayOrderId,
                  "razorpay_payment_id": razorpayPaymentId,
                  "razorpay_signature": razorpaySignature,
                }),
              ));

      debugPrint(
          "Verify Payment Response: ${response.statusCode} - ${response.body}");
      final jsonData = json.decode(response.body);

      return (response.statusCode == 200 && jsonData['success'] == true);
    } catch (e) {
      debugPrint("Error verifying payment: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>?> readBookText(
      String bookId, int pageNumber, String token) async {
    final uri =
        Uri.parse("$baseUrl/api/v1/book/readText/$bookId/page/$pageNumber");

    try {
      final response = await _handleAuthenticatedRequest((currentToken) =>
          http.get(uri, headers: {'Authorization': 'Bearer $currentToken'}));

      final jsonData = json.decode(response.body);
      if (response.statusCode == 200 && jsonData['success'] == true) {
        return jsonData['data'];
      }
      return null;
    } catch (e) {
      debugPrint("ApiService: readBookText error: $e");
      return null;
    }
  }

  // ================= HIGHLIGHTS =================

  static Future<List<HighlightModel>> fetchHighlights(
      String bookId, String token) async {
    final uri = Uri.parse("$baseUrl/api/v1/reading-sync/highlights/$bookId");
    try {
      final response = await _handleAuthenticatedRequest((currentToken) =>
          http.get(uri, headers: {'Authorization': 'Bearer $currentToken'}));

      final jsonData = json.decode(response.body);
      if (response.statusCode == 200 && jsonData['success'] == true) {
        final List<dynamic> highlightsJson = jsonData['data'] ?? [];
        return highlightsJson.map((h) => HighlightModel.fromJson(h)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("ApiService: fetchHighlights error: $e");
      return [];
    }
  }

  static Future<HighlightModel?> saveHighlight(
      String bookId, String token, HighlightModel highlight) async {
    final uri = Uri.parse("$baseUrl/api/v1/reading-sync/highlights/$bookId");
    try {
      final response = await _handleAuthenticatedRequest((currentToken) =>
          http.post(
            uri,
            headers: {
              'Authorization': 'Bearer $currentToken',
              'Content-Type': 'application/json',
            },
            body: json.encode(highlight.toJson()),
          ));

      final jsonData = json.decode(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          jsonData['success'] == true) {
        return HighlightModel.fromJson(jsonData['data']);
      }
      return null;
    } catch (e) {
      debugPrint("ApiService: saveHighlight error: $e");
      return null;
    }
  }

  static Future<bool> deleteHighlight(int highlightId, String token) async {
    final uri =
        Uri.parse("$baseUrl/api/v1/reading-sync/highlights/$highlightId");
    try {
      final response = await _handleAuthenticatedRequest((currentToken) =>
          http.delete(uri, headers: {'Authorization': 'Bearer $currentToken'}));

      final jsonData = json.decode(response.body);
      return (response.statusCode == 200 || response.statusCode == 201) &&
          jsonData['success'] == true;
    } catch (e) {
      debugPrint("ApiService: deleteHighlight error: $e");
      return false;
    }
  }

  static Future<String?> refreshAccessToken(String refreshToken) async {
    final uri = Uri.parse("$baseUrl/api/v1/users/refresh");
    try {
      debugPrint("ApiService: Attempting to refresh access token...");
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refreshToken': refreshToken}),
      );

      final responseBody = json.decode(response.body);
      if (response.statusCode == 200 && responseBody['success'] == true) {
        String? newToken = responseBody['accessToken']?.toString() ??
            responseBody['data']?['accessToken']?.toString();
        debugPrint(
            "ApiService: Successfully refreshed token. New length: ${newToken?.length}");
        return newToken;
      } else {
        debugPrint(
            "ApiService: Refresh token failed: ${responseBody['message']}");
        return null;
      }
    } catch (e) {
      debugPrint("ApiService: Refresh token error: $e");
      return null;
    }
  }
}