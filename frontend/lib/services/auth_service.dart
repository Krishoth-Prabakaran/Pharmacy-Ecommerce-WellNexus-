// frontend/lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // ==================== CONFIGURATION ====================
  // For web development
  static const String baseUrl = 'http://localhost:5000/api/auth';
  
  // For Android Emulator (uncomment if using emulator)
  // static const String baseUrl = 'http://10.0.2.2:5000/api/auth';
  
  // For iOS Simulator (uncomment if using simulator)
  // static const String baseUrl = 'http://localhost:5000/api/auth';

  // ==================== LOGIN ====================
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('📡 Login attempt for email: $email');
      print('🔗 URL: $baseUrl/login');
      
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      print('📥 Login response status: ${response.statusCode}');
      print('📥 Login response body: ${response.body}');

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
      if (e.toString().contains('SocketException')) {
        return {'success': false, 'message': 'Cannot connect to server. Make sure backend is running on port 5000'};
      }
      if (e.toString().contains('Timeout')) {
        return {'success': false, 'message': 'Connection timeout. Server is not responding'};
      }
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ==================== REGISTER ====================
  Future<Map<String, dynamic>> register(
      String username, String email, String password, String role) async {
    try {
      print('📡 Registration attempt for email: $email');
      print('🔗 URL: $baseUrl/register');
      
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'role': role,
        }),
      ).timeout(const Duration(seconds: 10));

      print('📥 Register response status: ${response.statusCode}');
      print('📥 Register response body: ${response.body}');

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
      if (e.toString().contains('SocketException')) {
        return {'success': false, 'message': 'Cannot connect to server. Make sure backend is running on port 5000'};
      }
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ==================== VERIFY OTP ====================
  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    try {
      print('📡 Verifying OTP for: $email with code: $otp');
      print('🔗 URL: $baseUrl/verify-email');
      
      final response = await http.post(
        Uri.parse('$baseUrl/verify-email'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email.toLowerCase(),
          'otp': otp,
        }),
      ).timeout(const Duration(seconds: 10));

      print('📥 Verify OTP response status: ${response.statusCode}');
      print('📥 Verify OTP response body: ${response.body}');

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _storeUserData(data);
        return {
          'success': true, 
          'user': data['user'],
          'token': data['token']
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Invalid or expired OTP',
        };
      }
    } catch (e) {
      print('❌ Verification error: $e');
      if (e.toString().contains('SocketException')) {
        return {'success': false, 'message': 'Cannot connect to server. Make sure backend is running on port 5000'};
      }
      if (e.toString().contains('Timeout')) {
        return {'success': false, 'message': 'Connection timeout. Server is not responding'};
      }
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ==================== RESEND OTP ====================
  Future<Map<String, dynamic>> resendVerificationEmail(String email) async {
    try {
      print('📡 Resending verification email to: $email');
      print('🔗 URL: $baseUrl/resend-verification');
      
      final response = await http.post(
        Uri.parse('$baseUrl/resend-verification'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email.toLowerCase()}),
      ).timeout(const Duration(seconds: 10));
      
      print('📥 Resend response status: ${response.statusCode}');
      print('📥 Resend response body: ${response.body}');
      
      final Map<String, dynamic> data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200, 
        'message': data['message'],
        'email_preview': data['email_preview']
      };
    } catch (e) {
      print('❌ Resend error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ==================== STORE USER DATA ====================
  Future<void> _storeUserData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    
    final userData = data['user'] ?? data;
    final token = data['token'] ?? '';
    
    print('💾 Storing user data:');
    print('   Token: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
    print('   User ID: ${userData['user_id']}');
    print('   Username: ${userData['username']}');
    print('   Email: ${userData['email']}');
    print('   Role: ${userData['role']}');
    
    await prefs.setString('token', token);
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