// services/pharmacy_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class PharmacyService {
  // ==================== CONFIGURATION ====================
  // For Chrome/web:
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

  // ==================== MEDICINES AND DEALERS ====================
  Future<Map<String, dynamic>> createMedicine(String name, {String? manufacturer, String? brand}) async {
    final token = await AuthService.getToken();
    if (token == null) return {'success': false, 'message': 'Not authenticated'};

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/medicines'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': name, 'manufacturer': manufacturer, 'brand': brand}),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) return {'success': true, 'medicine': data['medicine']};
      return {'success': false, 'message': data['message'] ?? 'Failed to create medicine'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<List<dynamic>> getMedicines() async {
    final token = await AuthService.getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/medicines'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['medicines'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> updateMedicine(int medicineId, Map<String, dynamic> updateData) async {
    final token = await AuthService.getToken();
    if (token == null) return {'success': false, 'message': 'Not authenticated'};

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/medicines/$medicineId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updateData),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'success': true, 'medicine': data['medicine']};
      return {'success': false, 'message': data['message'] ?? 'Failed to update medicine'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteMedicine(int medicineId) async {
    final token = await AuthService.getToken();
    if (token == null) return {'success': false, 'message': 'Not authenticated'};

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/medicines/$medicineId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'success': true, 'message': data['message']};
      return {'success': false, 'message': data['message'] ?? 'Failed to delete medicine'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> createDealer(String dealerName, {String? phone, String? email}) async {
    final token = await AuthService.getToken();
    if (token == null) return {'success': false, 'message': 'Not authenticated'};

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/dealers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'dealer_name': dealerName, 'phone': phone, 'email': email}),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) return {'success': true, 'dealer': data['dealer']};
      return {'success': false, 'message': data['message'] ?? 'Failed to create dealer'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<List<dynamic>> getDealers() async {
    final token = await AuthService.getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dealers'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['dealers'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> addStock(Map<String, dynamic> stockData) async {
    final token = await AuthService.getToken();
    if (token == null) return {'success': false, 'message': 'Not authenticated'};

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/stock'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(stockData),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) return {'success': true, 'stock': data['stock']};
      return {'success': false, 'message': data['message'] ?? 'Failed to add stock'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<List<dynamic>> getStockByPharmacy(int pharmacyId) async {
    final token = await AuthService.getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$pharmacyId/stock'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['stock'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getSalesByPharmacy(int pharmacyId) async {
    final token = await AuthService.getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$pharmacyId/sales'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['sales'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
