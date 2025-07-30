import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use the correct base URL for your emulator or device
  static const String baseUrl = 'http://10.0.2.2/project1msyamar/';

  // Helper: Get user ID from SharedPreferences
  static Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id') ?? '';
  }

  // Helper: Handle API responses
  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final data = json.decode(response.body);
      return {
        'status': data['status'] ?? (response.statusCode == 200 ? 'success' : 'error'),
        'message': data['message'] ?? 'Unknown error',
        'data': data['data'] ?? data,
        'httpStatus': response.statusCode,
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Failed to parse response: $e',
        'data': null,
        'httpStatus': response.statusCode,
      };
    }
  }

  // ==================== PROFILE MANAGEMENT ====================

  /// Get user profile by user_id
  static Future<Map<String, dynamic>> getProfile(String userId) async {
    try {
      final url = Uri.parse('$baseUrl?action=get_profile&user_id=$userId');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Network error: $e',
        'data': null,
        'httpStatus': 0,
      };
    }
  }

  /// Update user profile
  static Future<Map<String, dynamic>> updateProfile({
    required String userId,
    String? fullname,
    String? username,
    String? email,
  }) async {
    try {
      final url = Uri.parse('$baseUrl?action=update_profile');
      final body = {
        'user_id': userId,
        if (fullname != null) 'fullname': fullname,
        if (username != null) 'username': username,
        if (email != null) 'email': email,
      };
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Network error: $e',
        'data': null,
        'httpStatus': 0,
      };
    }
  }

  /// Delete user profile
  static Future<Map<String, dynamic>> deleteProfile(String userId) async {
    try {
      final url = Uri.parse('$baseUrl?action=delete_profile&user_id=$userId');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Network error: $e',
        'data': null,
        'httpStatus': 0,
      };
    }
  }

  // ==================== NOTES MANAGEMENT ====================

  /// Get notes for specific user
  static Future<Map<String, dynamic>> getUserNotes(String userId) async {
    try {
      final url = Uri.parse('$baseUrl?action=get_notes&user_id=$userId');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Network error: $e',
        'data': null,
        'httpStatus': 0,
      };
    }
  }

  /// Get all notes (for admin purposes)
  static Future<Map<String, dynamic>> getAllNotes() async {
    try {
      final url = Uri.parse('$baseUrl?action=get_all_notes');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Network error: $e',
        'data': null,
        'httpStatus': 0,
      };
    }
  }

  /// Add new note
  static Future<Map<String, dynamic>> addNote({
    required String userId,
    required String title,
    required String date,
    String? category,
    String? time,
    List<String>? pets,
    String? priority,
    List<String>? tags,
    String? content,
  }) async {
    try {
      final url = Uri.parse('$baseUrl?action=add_note');
      final body = {
        'user_id': userId,
        'title': title,
        'date': date,
        if (category != null) 'category': category,
        if (time != null) 'time': time,
        // Your PHP expects pets as a string (e.g. '["cat","dog"]'), so encode as JSON string
        if (pets != null) 'pets': json.encode(pets),
        if (priority != null) 'priority': priority,
        if (tags != null) 'tags': json.encode(tags),
        if (content != null) 'content': content,
      };
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Network error: $e',
        'data': null,
        'httpStatus': 0,
      };
    }
  }

  /// Update existing note
  static Future<Map<String, dynamic>> updateNote({
    required String id,
    String? title,
    String? category,
    String? date,
    String? time,
    List<String>? pets,
    String? priority,
    List<String>? tags,
    String? content,
  }) async {
    try {
      final url = Uri.parse('$baseUrl?action=update_note');
      final body = {
        'id': id,
        if (title != null) 'title': title,
        if (category != null) 'category': category,
        if (date != null) 'date': date,
        if (time != null) 'time': time,
        if (pets != null) 'pets': json.encode(pets),
        if (priority != null) 'priority': priority,
        if (tags != null) 'tags': json.encode(tags),
        if (content != null) 'content': content,
      };
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Network error: $e',
        'data': null,
        'httpStatus': 0,
      };
    }
  }

  /// Delete note
  static Future<Map<String, dynamic>> deleteNote(String noteId) async {
    try {
      final url = Uri.parse('$baseUrl?action=delete_note&id=$noteId');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Network error: $e',
        'data': null,
        'httpStatus': 0,
      };
    }
  }

  // ==================== CONVENIENCE METHODS ====================

  /// Get current user's profile
  static Future<Map<String, dynamic>> getCurrentUserProfile() async {
    final userId = await _getUserId();
    if (userId.isEmpty) {
      return {
        'status': 'error',
        'message': 'User ID not found',
        'data': null,
        'httpStatus': 0,
      };
    }
    return getProfile(userId);
  }

  /// Get current user's notes
  static Future<Map<String, dynamic>> getCurrentUserNotes() async {
    final userId = await _getUserId();
    if (userId.isEmpty) {
      return {
        'status': 'error',
        'message': 'User ID not found',
        'data': null,
        'httpStatus': 0,
      };
    }
    return getUserNotes(userId);
  }

  /// Update current user's profile
  static Future<Map<String, dynamic>> updateCurrentUserProfile({
    String? fullname,
    String? username,
    String? email,
  }) async {
    final userId = await _getUserId();
    if (userId.isEmpty) {
      return {
        'status': 'error',
        'message': 'User ID not found',
        'data': null,
        'httpStatus': 0,
      };
    }
    return updateProfile(
      userId: userId,
      fullname: fullname,
      username: username,
      email: email,
    );
  }

  /// Delete current user's profile
  static Future<Map<String, dynamic>> deleteCurrentUserProfile() async {
    final userId = await _getUserId();
    if (userId.isEmpty) {
      return {
        'status': 'error',
        'message': 'User ID not found',
        'data': null,
        'httpStatus': 0,
      };
    }
    return deleteProfile(userId);
  }

  // ==================== PETS MANAGEMENT ====================

  /// Get all pets (for admin purposes)
  static Future<Map<String, dynamic>> getAllPets() async {
    try {
      final url = Uri.parse('$baseUrl?action=get_all_pets');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Network error: $e',
        'data': null,
        'httpStatus': 0,
      };
    }
  }

  /// Get pets for specific user
  static Future<Map<String, dynamic>> getUserPets(String userId) async {
    try {
      final url = Uri.parse('$baseUrl?action=get_user_pets&user_id=$userId');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Network error: $e',
        'data': null,
        'httpStatus': 0,
      };
    }
  }

  // ==================== EVENTS & FUN FACTS ====================

  /// Get all events
  static Future<Map<String, dynamic>> getAllEvents() async {
    try {
      final url = Uri.parse('$baseUrl?action=get_all_events');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Network error: $e',
        'data': null,
        'httpStatus': 0,
      };
    }
  }

  /// Get all fun facts
  static Future<Map<String, dynamic>> getAllFunFacts() async {
    try {
      final url = Uri.parse('$baseUrl?action=get_all_fun_facts');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Network error: $e',
        'data': null,
        'httpStatus': 0,
      };
    }
  }

  // ==================== SYSTEM INFO ====================

  /// Get system information
  static Future<Map<String, dynamic>> getSystemInfo() async {
    try {
      final url = Uri.parse('$baseUrl?action=get_system_info');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Network error: $e',
        'data': null,
        'httpStatus': 0,
      };
    }
  }

  // ==================== USER MANAGEMENT ====================

  /// Get all users (for admin purposes)
  static Future<Map<String, dynamic>> getAllUsers() async {
    try {
      final url = Uri.parse('$baseUrl?action=get_all_users');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Network error: $e',
        'data': null,
        'httpStatus': 0,
      };
    }
  }
}