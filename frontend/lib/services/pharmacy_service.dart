// services/pharmacy_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class PharmacyService {
  // ==================== CONFIGURATION ====================
  static const String baseUrl = 'http://localhost:5000/api/pharmacies';
  // For Android emulator:
  // static const String baseUrl = 'http://10.0.2.2:5000/api/pharmacies';
  // For iOS emulator:
  // static const String baseUrl = 'http://localhost:5000/api/pharmacies';
  // For physical device (use your computer's IP):
  // static const String baseUrl = 'http://192.168.x.x:5000/api/pharmacies';

  // ==================== REGISTER PHARMACY ====================
  /// Registers a new pharmacy with all required fields
  /// Expects pharmacyData to contain: pharmacy_name, address, phone,
  /// latitude, longitude, open_time, close_time, username, email, password
  Future<Map<String, dynamic>> registerPharmacy(Map<String, dynamic> pharmacyData) async {
    try {
      print('📡 Registering pharmacy: ${pharmacyData['pharmacy_name']}');

      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(pharmacyData),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // Registration successful – optionally store user data if token were returned
        // (Backend currently does not return token, so we'll just return success)
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed (${response.statusCode})',
        };
      }
    } catch (e) {
      print('❌ Pharmacy registration error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ==================== GET PHARMACY BY ID ====================
  /// Fetches pharmacy details by ID (requires authentication)
  Future<Map<String, dynamic>> getPharmacyById(int pharmacyId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/id/$pharmacyId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'pharmacy': data['pharmacy']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to fetch'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ==================== GET PHARMACY BY EMAIL ====================
  Future<Map<String, dynamic>> getPharmacyByEmail(String email) async {
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
        return {'success': true, 'pharmacy': data['pharmacy']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to fetch'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ==================== GET ALL PHARMACIES ====================
  Future<Map<String, dynamic>> getAllPharmacies() async {
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
        return {'success': true, 'pharmacies': data['pharmacies']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to fetch'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}