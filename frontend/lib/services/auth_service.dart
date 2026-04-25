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
      ).timeout(const Duration(seconds: 20));

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
    
    // Handle both response formats: {user: {...}, token: "..."} and {token: "...", role: "...", user_id: 123, ...}
    final userData = data['user'] ?? data;
    final token = data['token'] ?? '';
    
    print('💾 Storing user data:');
    print('   Token: [REDACTED for security]');
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

  // ==================== CREATE PATIENT ====================
  static Future<Map<String, dynamic>> createPatient(Map<String, dynamic> patientData) async {
    try {
      print('📡 Creating patient: ${patientData['first_name']} ${patientData['last_name']}');
      print('🔗 URL: http://localhost:5000/api/patients');

      final response = await http.post(
        Uri.parse('http://localhost:5000/api/patients'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(patientData),
      ).timeout(const Duration(seconds: 10));

      print('📥 Create patient response status: ${response.statusCode}');
      print('📥 Create patient response body: ${response.body}');

      final Map<String, dynamic> data = jsonDecode(response.body);
      return data;
    } catch (e) {
      print('❌ Create patient error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ==================== CREATE PRESCRIPTION ====================
  static Future<Map<String, dynamic>> createPrescription(Map<String, dynamic> prescriptionData) async {
    try {
      print('📡 Creating prescription for patient: ${prescriptionData['patient_id']}');
      print('🔗 URL: http://localhost:5000/api/prescriptions');

      final response = await http.post(
        Uri.parse('http://localhost:5000/api/prescriptions'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(prescriptionData),
      ).timeout(const Duration(seconds: 10));

      print('📥 Create prescription response status: ${response.statusCode}');
      print('📥 Create prescription response body: ${response.body}');

      final Map<String, dynamic> data = jsonDecode(response.body);
      return data;
    } catch (e) {
      print('❌ Create prescription error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ==================== APPOINTMENT METHODS ====================

  // Create appointment
  static Future<Map<String, dynamic>> createAppointment(Map<String, dynamic> appointmentData) async {
    try {
      // final token = await _getToken();
      // if (token == null) {
      //   return {'success': false, 'message': 'Not authenticated'};
      // }

      print('📡 Creating appointment');
      print('🔗 URL: http://localhost:5000/api/appointments');

      final response = await http.post(
        Uri.parse('http://localhost:5000/api/appointments'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(appointmentData),
      ).timeout(const Duration(seconds: 10));

      print('📥 Create appointment response status: ${response.statusCode}');
      print('📥 Create appointment response body: ${response.body}');

      final Map<String, dynamic> data = jsonDecode(response.body);
      return data;
    } catch (e) {
      print('❌ Create appointment error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get appointments by doctor
  static Future<Map<String, dynamic>> getAppointmentsByDoctor({String? status, int? limit}) async {
    try {
      // final token = await _getToken();
      // if (token == null) {
      //   return {'success': false, 'message': 'Not authenticated'};
      // }

      String url = 'http://localhost:5000/api/appointments/doctor';
      final params = <String, String>{};
      if (status != null) params['status'] = status;
      if (limit != null) params['limit'] = limit.toString();

      if (params.isNotEmpty) {
        url += '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
      }

      print('📡 Getting appointments by doctor');
      print('🔗 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      print('📥 Get appointments response status: ${response.statusCode}');
      print('📥 Get appointments response body: ${response.body}');

      final Map<String, dynamic> data = jsonDecode(response.body);
      return data;
    } catch (e) {
      print('❌ Get appointments error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Update appointment status
  static Future<Map<String, dynamic>> updateAppointmentStatus(int appointmentId, String status, {String? notes}) async {
    try {
      // final token = await _getToken();
      // if (token == null) {
      //   return {'success': false, 'message': 'Not authenticated'};
      // }

      final body = {'status': status};
      if (notes != null) body['notes'] = notes;

      print('📡 Updating appointment $appointmentId status to $status');
      print('🔗 URL: http://localhost:5000/api/appointments/$appointmentId/status');

      final response = await http.put(
        Uri.parse('http://localhost:5000/api/appointments/$appointmentId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      print('📥 Update appointment response status: ${response.statusCode}');
      print('📥 Update appointment response body: ${response.body}');

      final Map<String, dynamic> data = jsonDecode(response.body);
      return data;
    } catch (e) {
      print('❌ Update appointment error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ==================== PATIENT METHODS ====================

  // Get patients (for doctor's records)
  static Future<Map<String, dynamic>> getPatients({String? searchQuery}) async {
    try {
      // final token = await _getToken();
      // if (token == null) {
      //   return {'success': false, 'message': 'Not authenticated'};
      // }

      String url = 'http://localhost:5000/api/patients';
      if (searchQuery != null && searchQuery.isNotEmpty) {
        url += '?search=${Uri.encodeComponent(searchQuery)}';
      }

      print('📡 Getting patients');
      print('🔗 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      print('📥 Get patients response status: ${response.statusCode}');
      print('📥 Get patients response body: ${response.body}');

      final Map<String, dynamic> data = jsonDecode(response.body);
      return data;
    } catch (e) {
      print('❌ Get patients error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get prescription history for a patient
  static Future<Map<String, dynamic>> getPatientPrescriptionHistory(int patientId) async {
    try {
      // final token = await _getToken();
      // if (token == null) {
      //   return {'success': false, 'message': 'Not authenticated'};
      // }

      print('📡 Getting prescription history for patient $patientId');
      print('🔗 URL: http://localhost:5000/api/prescriptions/patient/$patientId');

      final response = await http.get(
        Uri.parse('http://localhost:5000/api/prescriptions/patient/$patientId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      print('📥 Get prescription history response status: ${response.statusCode}');
      print('📥 Get prescription history response body: ${response.body}');

      final Map<String, dynamic> data = jsonDecode(response.body);
      return data;
    } catch (e) {
      print('❌ Get prescription history error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ==================== FORGOT PASSWORD ====================
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      print('📡 Forgot password request for: $email');
      print('🔗 URL: $baseUrl/forgot-password');
      
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email.toLowerCase()}),
      ).timeout(const Duration(seconds: 10));

      print('📥 Forgot password response status: ${response.statusCode}');
      print('📥 Forgot password response body: ${response.body}');

      final Map<String, dynamic> data = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'If the email exists, a reset link has been sent',
      };
    } catch (e) {
      print('❌ Forgot password error: $e');
      if (e.toString().contains('SocketException')) {
        return {'success': false, 'message': 'Cannot connect to server. Make sure backend is running on port 5000'};
      }
      if (e.toString().contains('Timeout')) {
        return {'success': false, 'message': 'Connection timeout. Server is not responding'};
      }
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ==================== VERIFY PASSWORD RESET OTP ====================
  Future<Map<String, dynamic>> verifyPasswordResetOtp(String email, String otp) async {
    try {
      print('📡 Verifying password reset OTP for: $email with code: $otp');
      print('🔗 URL: $baseUrl/verify-password-reset-otp');
      
      final response = await http.post(
        Uri.parse('$baseUrl/verify-password-reset-otp'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email.toLowerCase(),
          'otp': otp,
        }),
      ).timeout(const Duration(seconds: 30));

      print('📥 Verify password reset OTP response status: ${response.statusCode}');
      print('📥 Verify password reset OTP response body: ${response.body}');

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true, 
          'reset_token': data['reset_token'],
          'user': data['user']
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

  // ==================== VERIFY RESET TOKEN ====================
  Future<Map<String, dynamic>> verifyResetToken(String token) async {
    try {
      print('📡 Verifying reset token');
      print('🔗 URL: $baseUrl/verify-reset-token');
      
      final response = await http.post(
        Uri.parse('$baseUrl/verify-reset-token'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'token': token}),
      ).timeout(const Duration(seconds: 10));

      print('📥 Verify reset token response status: ${response.statusCode}');
      print('📥 Verify reset token response body: ${response.body}');

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'user': data['user'],
          'message': data['message'] ?? 'Token is valid',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Invalid or expired token',
        };
      }
    } catch (e) {
      print('❌ Verify reset token error: $e');
      if (e.toString().contains('SocketException')) {
        return {'success': false, 'message': 'Cannot connect to server. Make sure backend is running on port 5000'};
      }
      if (e.toString().contains('Timeout')) {
        return {'success': false, 'message': 'Connection timeout. Server is not responding'};
      }
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ==================== RESET PASSWORD ====================
  Future<Map<String, dynamic>> resetPassword(String token, String newPassword) async {
    try {
      print('📡 Resetting password');
      print('🔗 URL: $baseUrl/reset-password');
      
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'token': token,
          'newPassword': newPassword,
        }),
      ).timeout(const Duration(seconds: 10));

      print('📥 Reset password response status: ${response.statusCode}');
      print('📥 Reset password response body: ${response.body}');

      final Map<String, dynamic> data = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Password reset successful',
      };
    } catch (e) {
      print('❌ Reset password error: $e');
      if (e.toString().contains('SocketException')) {
        return {'success': false, 'message': 'Cannot connect to server. Make sure backend is running on port 5000'};
      }
      if (e.toString().contains('Timeout')) {
        return {'success': false, 'message': 'Connection timeout. Server is not responding'};
      }
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ==================== HELPER METHODS ====================

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}
