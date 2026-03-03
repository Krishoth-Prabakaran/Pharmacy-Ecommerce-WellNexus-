// =====================================================
// DOCTOR SERVICE
// =====================================================
// Handles all API communications for doctor operations
// =====================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class DoctorService {
  // ==================== CONFIGURATION ====================
  static const String baseUrl = 'http://localhost:5000/api/doctors';

  // ==================== REGISTER DOCTOR ====================
  Future<Map<String, dynamic>> registerDoctor(Map<String, dynamic> doctorData) async {
    try {
      print('📡 Registering doctor: ${doctorData['first_name']} ${doctorData['last_name']}');

      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(doctorData),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed (${response.statusCode})',
        };
      }
    } catch (e) {
      print('❌ Doctor registration error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ==================== GET DOCTOR BY ID ====================
  Future<Map<String, dynamic>> getDoctorById(int doctorId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/id/$doctorId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'doctor': data['doctor']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to fetch'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ==================== GET DOCTOR BY EMAIL ====================
  Future<Map<String, dynamic>> getDoctorByEmail(String email) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/email/$email'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'doctor': data['doctor']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to fetch'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ==================== GET ALL DOCTORS ====================
  Future<Map<String, dynamic>> getAllDoctors() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'doctors': data['doctors']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to fetch'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}