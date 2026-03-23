// lib/services/doctor_service.dart
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
      print('📡 Email: ${doctorData['email']}');
      print('📡 Specialization: ${doctorData['specialization']}');
      print('📡 License: ${doctorData['license_number']}');

      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(doctorData),
      ).timeout(const Duration(seconds: 10));

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      final Map<String, dynamic> data = jsonDecode(response.body);

      // Handle both 200 and 201 status codes
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true, 
          'message': data['message'] ?? 'Doctor registered successfully',
          'data': data
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed (${response.statusCode})',
        };
      }
    } catch (e) {
      print('❌ Doctor registration error: $e');
      if (e.toString().contains('SocketException')) {
        return {'success': false, 'message': 'Cannot connect to server. Make sure backend is running on port 5000'};
      }
      if (e.toString().contains('Timeout')) {
        return {'success': false, 'message': 'Connection timeout. Server is not responding'};
      }
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

      print('🔍 Fetching doctor by ID: $doctorId');

      final response = await http.get(
        Uri.parse('$baseUrl/id/$doctorId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'doctor': data['doctor']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to fetch doctor'};
      }
    } catch (e) {
      print('❌ Get doctor by ID error: $e');
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

      print('🔍 Fetching doctor by email: $email');

      final response = await http.get(
        Uri.parse('$baseUrl/email/$email'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'doctor': data['doctor']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to fetch doctor'};
      }
    } catch (e) {
      print('❌ Get doctor by email error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ==================== GET DOCTORS BY SPECIALIZATION ====================
  Future<Map<String, dynamic>> getDoctorsBySpecialization(String specialization) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      print('🔍 Fetching doctors by specialization: $specialization');

      final response = await http.get(
        Uri.parse('$baseUrl/specialization/$specialization'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true, 
          'doctors': data['doctors'],
          'count': data['count']
        };
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to fetch doctors'};
      }
    } catch (e) {
      print('❌ Get doctors by specialization error: $e');
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

      print('🔍 Fetching all doctors');

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true, 
          'doctors': data['doctors'],
          'count': data['count']
        };
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to fetch doctors'};
      }
    } catch (e) {
      print('❌ Get all doctors error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ==================== UPDATE DOCTOR ====================
  Future<Map<String, dynamic>> updateDoctor(int doctorId, Map<String, dynamic> updateData) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      print('✏️ Updating doctor ID: $doctorId');

      final response = await http.put(
        Uri.parse('$baseUrl/$doctorId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updateData),
      ).timeout(const Duration(seconds: 10));

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'doctor': data['doctor']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to update doctor'};
      }
    } catch (e) {
      print('❌ Update doctor error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ==================== DELETE DOCTOR ====================
  Future<Map<String, dynamic>> deleteDoctor(int doctorId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      print('🗑️ Deleting doctor ID: $doctorId');

      final response = await http.delete(
        Uri.parse('$baseUrl/$doctorId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to delete doctor'};
      }
    } catch (e) {
      print('❌ Delete doctor error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}