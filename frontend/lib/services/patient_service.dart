// services/patient_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class PatientService {
  // ==================== CONFIGURATION ====================
  static const String baseUrl = 'http://localhost:5000/api/patients';
  // Adjust for emulator/device as in auth_service

  // ==================== SAVE PATIENT DETAILS ====================
  Future<Map<String, dynamic>> savePatientDetails(Map<String, dynamic> patientData) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      // Get user_id from stored data
      final userData = await AuthService.getUserData();
      final userId = userData?['user_id'];

      // Add user_id to the request if available (backend should expect it)
      if (userId != null) {
        patientData['user_id'] = userId;
      }

      print('📡 Saving patient details: $patientData');

      final response = await http.post(
        Uri.parse('$baseUrl/details'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(patientData),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Mark that patient details are completed
        await _setPatientDetailsCompleted(true);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to save details',
        };
      }
    } catch (e) {
      print('❌ Save patient details error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ==================== CHECK IF PATIENT HAS DETAILS ====================
  Future<bool> hasPatientDetails(String email) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final response = await http.get(
        Uri.parse('$baseUrl/$email/check'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['has_details'] == true;
      }
      return false;
    } catch (e) {
      print('❌ Check patient details error: $e');
      return false;
    }
  }

  // ==================== LOCAL FLAG FOR DETAILS COMPLETION ====================
  Future<void> _setPatientDetailsCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('patient_details_completed', completed);
  }

  static Future<bool> isPatientDetailsCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('patient_details_completed') ?? false;
  }

  static Future<void> clearPatientData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('patient_details_completed');
  }
}