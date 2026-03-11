import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/user_register_model.dart';
import '../models/book_model.dart';
import '../models/login_model.dart';
import '../models/note_model.dart';
import '../models/notification_model.dart';
import '../utils/constants.dart';

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
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return UserModel.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? "Registration failed");
      }
    } catch (e) {
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
      final data = json.decode(response.body);
      return data['success'] == true;
    } catch (e) {
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
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data['data']['verificationToken'];
      } else {
        throw Exception(data['message'] ?? "Verification failed");
      }
    } catch (e) {
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

      final responseBody = json.decode(response.body);
      if (response.statusCode == 200 && responseBody['success'] == true) {
        // 1. Extract the nested data object
        Map<String, dynamic> userData = responseBody['data'] is Map
            ? Map<String, dynamic>.from(responseBody['data'])
            : {};

        // 2. Extract Token with multi-key support (matches Postman "accessToken")
        String? tokenValue = responseBody['token']?.toString() ??
            responseBody['accessToken']?.toString() ??
            userData['token']?.toString() ??
            userData['accessToken']?.toString();

        // 3. Ensure the 'token' key is populated for the LoginModel
        if (tokenValue != null && tokenValue.isNotEmpty) {
          userData['token'] = tokenValue;
        }

        // 4. Map user_id to id if necessary for model compatibility
        if (userData['id'] == null && userData['user_id'] != null) {
          userData['id'] = userData['user_id'];
        }

        return LoginModel.fromJson(userData);
      } else {
        throw Exception(responseBody['message'] ?? "Login failed");
      }
    } catch (e) {
      debugPrint("Login error: $e");
      rethrow;
    }
  }

  static Future<LoginModel> getUserProfile(String token) async {
    final uri = Uri.parse("$baseUrl/api/v1/users/profile");
    try {
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        Map<String, dynamic> userData = Map<String, dynamic>.from(data['data']);
        // Crucial: API might not return the token in profile response, so we re-inject it
        if (userData['token'] == null || userData['token'].toString().isEmpty) {
          userData['token'] = token;
        }
        return LoginModel.fromJson(userData);
      } else {
        throw Exception(data['message'] ?? "Failed to get profile");
      }
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
    final uri = Uri.parse("$baseUrl/api/v1/users/profile");
    var request = http.MultipartRequest('PUT', uri);
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['name'] = name;
    request.fields['email'] = email;
    request.fields['phone'] = phone;
    request.fields['additional_phone'] = additionalPhone;

    if (profileImage != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'profileImage',
        profileImage.path,
      ));
    }

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final data = json.decode(response.body);
      if (data['success'] == true) {
        Map<String, dynamic> userData = Map<String, dynamic>.from(data['data']);
        // Re-inject token as the update response might not include it
        if (userData['token'] == null || userData['token'].toString().isEmpty) {
          userData['token'] = token;
        }
        return LoginModel.fromJson(userData);
      } else {
        throw Exception(data['message'] ?? "Profile update failed");
      }
    } catch (e) {
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
      final data = json.decode(response.body);
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
        final data = json.decode(response.body);
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
    final uri = Uri.parse("$baseUrl/api/v1/users/bookmarks/toggle");
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
    final uri = Uri.parse("$baseUrl/api/v1/users/bookmarks");
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

        return booksList
            .map((item) => BookModel.fromMindGymJson(item))
            .toList();
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
      final headers = token != null ? {'Authorization': 'Bearer $token'} : null;
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        dynamic booksData = data['data'];
        List<dynamic> booksList = [];

        if (booksData is List) {
          booksList = booksData;
        } else if (booksData is Map) {
          // The API uses 'books' key for the list within the data object
          booksList = booksData['books'] ?? [];
        } else {
          debugPrint(
              "Unexpected book data structure: ${booksData.runtimeType}");
        }

        return booksList
            .map((item) => BookModel.fromMindGymJson(item))
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
      final headers = token != null ? {'Authorization': 'Bearer $token'} : null;
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return BookModel.fromMindGymJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      debugPrint("Get book by id error: $e");
      return null;
    }
  }

  // ================= NOTES =================

  static Future<List<NoteModel>> getAllNotes(String token) async {
    final uri = Uri.parse("$baseUrl/api/v1/note/all");
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
    final uri = Uri.parse("$baseUrl/api/v1/note/save");
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
    final uri = Uri.parse("$baseUrl/api/v1/note/$id");
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
    final uri = Uri.parse("$baseUrl/api/v1/note/$id");
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

  static Future<Map<String, dynamic>?> readBook(
      String bookId, String token) async {
    final uri = Uri.parse("$baseUrl/api/v1/book/readBook/$bookId");

    try {
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      debugPrint(
          "ApiService: Read Book Response: ${response.statusCode} - ${response.body}");
      final jsonData = json.decode(response.body);

      if (response.statusCode == 200 && jsonData['success'] == true) {
        return jsonData['data'];
      }
      debugPrint(
          "ApiService: Read Book failed - success is false or code != 200");
      return null;
    } catch (e) {
      debugPrint("Read Book Error: $e");
      return null;
    }
  }

  // ================= NOTIFICATIONS =================

  static Future<List<NotificationModel>> getNotifications(String token) async {
    final uri = Uri.parse("$baseUrl/api/v1/notification/all");
    try {
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> notifications = data['data'] ?? [];
        return notifications
            .map((item) => NotificationModel.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint("Get notifications error: $e");
      return [];
    }
  }

  // ================= SUBSCRIPTION =================

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
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode({
          "razorpay_order_id": razorpayOrderId,
          "razorpay_payment_id": razorpayPaymentId,
          "razorpay_signature": razorpaySignature,
        }),
      );

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
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

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
}
