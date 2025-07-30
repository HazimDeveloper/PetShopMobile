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

  // Helper: Handle API responses with better error handling
  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      // Check if response is HTML (error page)
      if (response.body.trim().startsWith('<!DOCTYPE') || 
          response.body.trim().startsWith('<html')) {
        return {
          'status': 'error',
          'message': 'Server returned HTML instead of JSON. Check PHP endpoint for errors.',
          'data': null,
          'httpStatus': response.statusCode,
          'debug_response': response.body.substring(0, 200) + '...',
        };
      }

      // Try to parse JSON
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
        'debug_response': response.body.length > 200 
            ? response.body.substring(0, 200) + '...'
            : response.body,
      };
    }
  }

  // Helper: Make HTTP request with better error handling
  static Future<Map<String, dynamic>> _makeRequest(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      
      print('🔍 Making $method request to: $url');
      if (body != null) {
        print('📤 Request body: ${json.encode(body)}');
      }

      late http.Response response;
      final defaultHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...?headers,
      };

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: defaultHeaders)
              .timeout(const Duration(seconds: 15));
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: defaultHeaders,
            body: body != null ? json.encode(body) : null,
          ).timeout(const Duration(seconds: 15));
          break;
        case 'PUT':
          response = await http.put(
            url,
            headers: defaultHeaders,
            body: body != null ? json.encode(body) : null,
          ).timeout(const Duration(seconds: 15));
          break;
        case 'DELETE':
          response = await http.delete(url, headers: defaultHeaders)
              .timeout(const Duration(seconds: 15));
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body preview: ${response.body.substring(0, 
          response.body.length > 100 ? 100 : response.body.length)}...');

      return _handleResponse(response);
    } catch (e) {
      print('❌ API Request failed: $e');
      return {
        'status': 'error',
        'message': 'Network error: $e',
        'data': null,
        'httpStatus': 0,
      };
    }
  }

  // ==================== NOTES MANAGEMENT ====================

  /// Get current user's notes with better error handling
  static Future<Map<String, dynamic>> getCurrentUserNotes() async {
    final userId = await _getUserId();
    print('🔍 Getting notes for user ID: $userId');
    
    if (userId.isEmpty) {
      return {
        'status': 'error',
        'message': 'User ID not found. Please login again.',
        'data': null,
        'httpStatus': 0,
      };
    }
    
    return getUserNotes(userId);
  }

  /// Get notes for specific user
  static Future<Map<String, dynamic>> getUserNotes(String userId) async {
    return _makeRequest('getnotes.php?user_id=$userId');
  }

  /// Get all notes (for admin purposes)
  static Future<Map<String, dynamic>> getAllNotes() async {
    return _makeRequest('getnotes.php?action=get_all');
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
    final body = {
      'user_id': userId,
      'title': title,
      'date': date,
      if (category != null) 'category': category,
      if (time != null) 'time': time,
      if (pets != null) 'pets': pets,
      if (priority != null) 'priority': priority,
      if (tags != null) 'tags': tags,
      if (content != null) 'content': content,
    };

    return _makeRequest('getnotes.php', method: 'POST', body: body);
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
    final body = {
      'id': id,
      if (title != null) 'title': title,
      if (category != null) 'category': category,
      if (date != null) 'date': date,
      if (time != null) 'time': time,
      if (pets != null) 'pets': pets,
      if (priority != null) 'priority': priority,
      if (tags != null) 'tags': tags,
      if (content != null) 'content': content,
    };

    return _makeRequest('getnotes.php?action=update', method: 'POST', body: body);
  }

  /// Delete note
  static Future<Map<String, dynamic>> deleteNote(String noteId) async {
    return _makeRequest('getnotes.php?action=delete&id=$noteId', method: 'DELETE');
  }
// ==================== PROFILE MANAGEMENT ====================

/// Get user profile by user_id
static Future<Map<String, dynamic>> getProfile(String userId) async {
  return _makeRequest('profile_api.php?action=get_profile&user_id=$userId');
}

/// Update user profile
static Future<Map<String, dynamic>> updateProfile({
  required String userId,
  required String fullname,
  required String username,
  required String email,
}) async {
  final body = {
    'user_id': userId,
    'fullname': fullname,
    'username': username,
    'email': email,
  };

  return _makeRequest('profile_api.php?action=update_profile', method: 'POST', body: body);
}

/// Delete user profile
static Future<Map<String, dynamic>> deleteProfile(String userId) async {
  final body = {
    'user_id': userId,
  };

  return _makeRequest('profile_api.php?action=delete_profile', method: 'POST', body: body);
}

/// Change password
static Future<Map<String, dynamic>> changePassword({
  required String userId,
  required String currentPassword,
  required String newPassword,
}) async {
  final body = {
    'user_id': userId,
    'current_password': currentPassword,
    'new_password': newPassword,
  };

  return _makeRequest('profile_api.php?action=change_password', method: 'POST', body: body);
}

/// Get current user's profile
static Future<Map<String, dynamic>> getCurrentUserProfile() async {
  final userId = await _getUserId();
  if (userId.isEmpty) {
    return {
      'status': 'error',
      'message': 'User ID not found. Please login again.',
      'data': null,
      'httpStatus': 0,
    };
  }
  return getProfile(userId);
}

/// Update current user's profile
static Future<Map<String, dynamic>> updateCurrentUserProfile({
  required String fullname,
  required String username,
  required String email,
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

/// Change current user's password
static Future<Map<String, dynamic>> changeCurrentUserPassword({
  required String currentPassword,
  required String newPassword,
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
  return changePassword(
    userId: userId,
    currentPassword: currentPassword,
    newPassword: newPassword,
  );
}

  // ==================== TESTING METHOD ====================
  
  /// Test API connection
  static Future<Map<String, dynamic>> testConnection() async {
    return _makeRequest('db_config.php');
  }

  
}