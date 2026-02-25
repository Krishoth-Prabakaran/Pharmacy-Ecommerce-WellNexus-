// services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // ==================== CONFIGURATION ====================
  // For Chrome/web:
  static const String baseUrl = 'http://localhost:5000/api/auth';
  // For Android emulator:
  // static const String baseUrl = 'http://10.0.2.2:5000/api/auth';
  // For iOS emulator:
  // static const String baseUrl = 'http://localhost:5000/api/auth';
  // For physical device (use your computer's IP):
  // static const String baseUrl = 'http://192.168.x.x:5000/api/auth';

  // ==================== LOGIN ====================
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('📡 Login attempt for email: $email');

      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      // Parse JSON safely
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Validate required fields (your backend sends flat structure)
        if (data['token'] == null) {
          return {'success': false, 'message': 'Server response missing token'};
        }

        // Store user data
        await _storeUserData(data);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Login failed (${response.statusCode})',
        };
      }
    } catch (e) {
      print('❌ Login error: $e');
      return {'success': false, 'message': 'Network error. Check backend connection.'};
    }
  }

  // ==================== REGISTER ====================
  Future<Map<String, dynamic>> register(
      String username, String email, String password, String role) async {
    try {
      print('📡 Registration attempt for email: $email');

      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'role': role,
        }),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        if (data['token'] == null) {
          return {'success': false, 'message': 'Server response missing token'};
        }

        await _storeUserData(data);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed (${response.statusCode})',
        };
      }
    } catch (e) {
      print('❌ Registration error: $e');
      return {'success': false, 'message': 'Network error. Check backend connection.'};
    }
  }

  // ==================== STORE USER DATA LOCALLY ====================
  Future<void> _storeUserData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    // Extract values safely – handle both flat and nested structures
    String token = data['token']?.toString() ?? '';

    // Default empty values
    String role = '';
    int userId = 0;
    String username = '';
    String email = '';

    // Check if response has nested 'user' (register endpoint) or flat (login endpoint)
    if (data['user'] != null && data['user'] is Map) {
      // Register response structure: { token, user: { ... } }
      final user = data['user'] as Map;
      role = user['role']?.toString() ?? '';
      userId = user['user_id'] ?? 0;
      username = user['username']?.toString() ?? '';
      email = user['email']?.toString() ?? '';
    } else {
      // Login response structure: { token, role, user_id, username, email }
      role = data['role']?.toString() ?? '';
      userId = data['user_id'] ?? 0;
      username = data['username']?.toString() ?? '';
      email = data['email']?.toString() ?? '';
    }

    // Store with fallback defaults to avoid null errors later
    await prefs.setString('token', token);
    await prefs.setString('role', role.isNotEmpty ? role : 'unknown');
    await prefs.setInt('user_id', userId);
    await prefs.setString('username', username.isNotEmpty ? username : 'User');
    await prefs.setString('email', email.isNotEmpty ? email : '');

    print('✅ User data stored:');
    print('   Role: $role');
    print('   User ID: $userId');
    print('   Username: $username');
    print('   Email: $email');
  }

  // ==================== CHECK LOGIN STATUS ====================
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  // ==================== GET TOKEN ====================
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ==================== GET USER ROLE ====================
  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  // ==================== GET COMPLETE USER DATA ====================
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) return null;

    return {
      'token': token,
      'role': prefs.getString('role') ?? '',
      'user_id': prefs.getInt('user_id') ?? 0,
      'username': prefs.getString('username') ?? '',
      'email': prefs.getString('email') ?? '',
    };
  }

  // ==================== LOGOUT ====================
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print('👋 User logged out');
  }
}