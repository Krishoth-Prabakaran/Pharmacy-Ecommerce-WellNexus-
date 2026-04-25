import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class AdminService {
  static const String _baseUrl = 'http://localhost:5000/api/admin';

  // Get headers with authorization token
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/stats'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load dashboard stats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching dashboard stats: $e');
    }
  }

  // Get all users with pagination
  Future<Map<String, dynamic>> getAllUsers({
    int page = 1,
    int limit = 20,
    String? role,
    String? search,
  }) async {
    try {
      final params = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (role != null) params['role'] = role;
      if (search != null) params['search'] = search;

      final queryString = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await http.get(
        Uri.parse('$_baseUrl/users?$queryString'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }

  // Get all patients with pagination
  Future<Map<String, dynamic>> getAllPatients({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      final params = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (search != null) params['search'] = search;

      final queryString = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await http.get(
        Uri.parse('$_baseUrl/patients?$queryString'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load patients: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching patients: $e');
    }
  }

  // Get all doctors with pagination
  Future<Map<String, dynamic>> getAllDoctors({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      final params = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (search != null) params['search'] = search;

      final queryString = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await http.get(
        Uri.parse('$_baseUrl/doctors?$queryString'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load doctors: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching doctors: $e');
    }
  }

  // Get all pharmacies with pagination
  Future<Map<String, dynamic>> getAllPharmacies({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      final params = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (search != null) params['search'] = search;

      final queryString = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await http.get(
        Uri.parse('$_baseUrl/pharmacies?$queryString'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load pharmacies: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching pharmacies: $e');
    }
  }

  // Get all appointments with pagination
  Future<Map<String, dynamic>> getAllAppointments({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      final params = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (status != null) params['status'] = status;

      final queryString = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await http.get(
        Uri.parse('$_baseUrl/appointments?$queryString'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load appointments: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching appointments: $e');
    }
  }

  // Get all prescriptions with pagination
  Future<Map<String, dynamic>> getAllPrescriptions({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      final params = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (status != null) params['status'] = status;

      final queryString = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await http.get(
        Uri.parse('$_baseUrl/prescriptions?$queryString'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load prescriptions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching prescriptions: $e');
    }
  }

  // Get all orders with pagination
  Future<Map<String, dynamic>> getAllOrders({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      final params = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (status != null) params['status'] = status;

      final queryString = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await http.get(
        Uri.parse('$_baseUrl/orders?$queryString'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching orders: $e');
    }
  }

  // Update user role
  Future<Map<String, dynamic>> updateUserRole(int userId, String role) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/users/$userId/role'),
        headers: await _getHeaders(),
        body: json.encode({'role': role}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update user role: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating user role: $e');
    }
  }

  // Delete user
  Future<Map<String, dynamic>> deleteUser(int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/users/$userId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to delete user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }

  // Update appointment status
  Future<Map<String, dynamic>> updateAppointmentStatus(
    int appointmentId,
    String status,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/appointments/$appointmentId/status'),
        headers: await _getHeaders(),
        body: json.encode({'status': status}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update appointment status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating appointment status: $e');
    }
  }

  // Update prescription status
  Future<Map<String, dynamic>> updatePrescriptionStatus(
    int prescriptionId,
    String status,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/prescriptions/$prescriptionId/status'),
        headers: await _getHeaders(),
        body: json.encode({'status': status}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update prescription status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating prescription status: $e');
    }
  }

  // Verify doctor
  Future<Map<String, dynamic>> verifyDoctor(
    int doctorId,
    bool isVerified, {
    String? notes,
  }) async {
    try {
      final Map<String, dynamic> body = {'isVerified': isVerified};
      if (notes != null) body['notes'] = notes;

      final response = await http.put(
        Uri.parse('$_baseUrl/doctors/$doctorId/verify'),
        headers: await _getHeaders(),
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to verify doctor: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error verifying doctor: $e');
    }
  }

  // Verify pharmacy
  Future<Map<String, dynamic>> verifyPharmacy(
    int pharmacyId,
    bool isVerified, {
    String? notes,
  }) async {
    try {
      final Map<String, dynamic> body = {'isVerified': isVerified};
      if (notes != null) body['notes'] = notes;

      final response = await http.put(
        Uri.parse('$_baseUrl/pharmacies/$pharmacyId/verify'),
        headers: await _getHeaders(),
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to verify pharmacy: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error verifying pharmacy: $e');
    }
  }

  // Get analytics
  Future<Map<String, dynamic>> getAnalytics() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/analytics'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load analytics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching analytics: $e');
    }
  }

  // Get all disputes
  Future<Map<String, dynamic>> getAllDisputes({
    int page = 1,
    int limit = 20,
    String? status,
    String? type,
  }) async {
    try {
      final params = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (status != null) params['status'] = status;
      if (type != null) params['type'] = type;

      final queryString = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await http.get(
        Uri.parse('$_baseUrl/disputes?$queryString'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load disputes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching disputes: $e');
    }
  }

  // Create dispute
  Future<Map<String, dynamic>> createDispute({
    required String disputeType,
    required int relatedId,
    required String description,
    String priority = 'medium',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/disputes'),
        headers: await _getHeaders(),
        body: json.encode({
          'disputeType': disputeType,
          'relatedId': relatedId,
          'description': description,
          'priority': priority,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create dispute: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating dispute: $e');
    }
  }

  // Update dispute status
  Future<Map<String, dynamic>> updateDisputeStatus(
    int disputeId,
    String status, {
    String? resolutionNotes,
  }) async {
    try {
      final body = {'status': status};
      if (resolutionNotes != null) body['resolutionNotes'] = resolutionNotes;

      final response = await http.put(
        Uri.parse('$_baseUrl/disputes/$disputeId/status'),
        headers: await _getHeaders(),
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update dispute status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating dispute status: $e');
    }
  }
}