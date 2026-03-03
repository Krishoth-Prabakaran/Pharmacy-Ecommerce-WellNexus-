// frontend/lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // ==================== CONFIGURATION ====================
  // Use 10.0.2.2 for Android Emulator to connect to your computer's localhost
  static const String baseUrl = 'http://10.0.2.2:5000/api/auth';
  
  // If you are testing on Web/Chrome, use:
  // static const String baseUrl = 'http://localhost:5000/api/auth';

  // ==================== LOGIN ====================
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('📡 Login attempt for email: $email');
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _storeUserData(data);
        return {'success': true, 'data': data};
      } else {
        if (data['needs_verification'] == true) {
          return {
            'success': false,
            'needs_verification': true,
            'email': data['email'],
            'message': data['message'] ?? 'Please verify your email first',
          };
        }
        return {'success': false, 'message': data['message'] ?? 'Login failed'};
      }
    } catch (e) {
      print('❌ Login error: $e');
      return {'success': false, 'message': 'Network error'};
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

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'OTP sent successfully',
          'email': email,
          'username': username,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      print('❌ Registration error: $e');
      return {'success': false, 'message': 'Network error'};
    }
  }

  // ==================== VERIFY OTP ====================
  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    try {
      print('📡 Verifying OTP for: $email');
      final response = await http.post(
        Uri.parse('$baseUrl/verify-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _storeUserData(data);
        return {'success': true, 'user': data['user']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Verification failed',
        };
      }
    } catch (e) {
      print('❌ Verification error: $e');
      return {'success': false, 'message': 'Network error'};
    }
  }

  // ==================== RESEND OTP ====================
  Future<Map<String, dynamic>> resendVerificationEmail(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/resend-verification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      final Map<String, dynamic> data = jsonDecode(response.body);
      return {'success': response.statusCode == 200, 'message': data['message']};
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  // ==================== STORE USER DATA ====================
  Future<void> _storeUserData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    
    final userData = data['user'] ?? data;
    
    await prefs.setString('token', data['token'] ?? '');
    await prefs.setString('role', userData['role'] ?? '');
    await prefs.setInt('user_id', userData['user_id'] ?? 0);
    await prefs.setString('username', userData['username'] ?? '');
    await prefs.setString('email', userData['email'] ?? '');
    await prefs.setBool('email_verified', true);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return null;
    return {
      'token': token,
      'role': prefs.getString('role') ?? '',
      'user_id': prefs.getInt('user_id') ?? 0,
      'username': prefs.getString('username') ?? '',
      'email': prefs.getString('email') ?? '',
    };
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
