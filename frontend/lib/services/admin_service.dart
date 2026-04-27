// services/admin_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class AdminService {
  static const String _baseUrl = 'http://localhost:5000/api/admin';

  // Get headers with authorization token
  Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ==================== DASHBOARD STATS ====================
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

  // ==================== USER MANAGEMENT ====================
  Future<Map<String, dynamic>> getAllUsers({
    int page = 1,
    int limit = 20,
    String? role,
    String? search,
    String sortBy = 'created_at',
    String sortOrder = 'DESC',
  }) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      };
      if (role != null && role.isNotEmpty) params['role'] = role;
      if (search != null && search.isNotEmpty) params['search'] = search;

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

  Future<Map<String, dynamic>> deactivateUser(int userId, bool isActive) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/users/$userId/deactivate'),
        headers: await _getHeaders(),
        body: json.encode({'isActive': isActive}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update user status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating user status: $e');
    }
  }

  Future<Map<String, dynamic>> adminResetPassword(int userId, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/users/$userId/reset-password'),
        headers: await _getHeaders(),
        body: json.encode({'newPassword': newPassword}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to reset password: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error resetting password: $e');
    }
  }

  // ==================== PATIENT MANAGEMENT ====================
  Future<Map<String, dynamic>> getAllPatients({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (search != null && search.isNotEmpty) params['search'] = search;

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

  Future<Map<String, dynamic>> getPatientDetails(int patientId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/patients/$patientId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load patient details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching patient details: $e');
    }
  }

  // ==================== DOCTOR MANAGEMENT ====================
  Future<Map<String, dynamic>> getAllDoctors({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (search != null && search.isNotEmpty) params['search'] = search;

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

  Future<Map<String, dynamic>> verifyDoctor(
    int doctorId,
    bool isVerified, {
    String? notes,
  }) async {
    try {
      final Map<String, dynamic> body = {'isVerified': isVerified};
      if (notes != null && notes.isNotEmpty) body['notes'] = notes;

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

  Future<Map<String, dynamic>> getDoctorDetails(int doctorId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/doctors/$doctorId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load doctor details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching doctor details: $e');
    }
  }

  // ==================== PHARMACY MANAGEMENT ====================
  Future<Map<String, dynamic>> getAllPharmacies({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (search != null && search.isNotEmpty) params['search'] = search;

      final queryString = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await http.get(
        Uri.parse('$_baseUrl/pharmacies?$queryString'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Transform the response to ensure consistent field names
        if (data['pharmacies'] != null) {
          final transformedPharmacies = (data['pharmacies'] as List).map((pharmacy) {
            return {
              ...pharmacy,
              'name': pharmacy['name'] ?? pharmacy['pharmacy_name'] ?? 'Unknown',
              'location': pharmacy['location'] ?? pharmacy['address'] ?? 'No address',
            };
          }).toList();
          data['pharmacies'] = transformedPharmacies;
        }
        return data;
      } else {
        throw Exception('Failed to load pharmacies: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching pharmacies: $e');
    }
  }

  Future<Map<String, dynamic>> verifyPharmacy(
    int pharmacyId,
    bool isVerified, {
    String? notes,
  }) async {
    try {
      final Map<String, dynamic> body = {'isVerified': isVerified};
      if (notes != null && notes.isNotEmpty) body['notes'] = notes;

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

  Future<Map<String, dynamic>> getPharmacyDetails(int pharmacyId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/pharmacies/$pharmacyId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load pharmacy details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching pharmacy details: $e');
    }
  }

  // ==================== APPOINTMENT MANAGEMENT ====================
  Future<Map<String, dynamic>> getAllAppointments({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (status != null && status.isNotEmpty) params['status'] = status;

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

  // ==================== PRESCRIPTION MANAGEMENT ====================
  Future<Map<String, dynamic>> getAllPrescriptions({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (status != null && status.isNotEmpty) params['status'] = status;

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

  // ==================== ORDER MANAGEMENT ====================
  Future<Map<String, dynamic>> getAllOrders({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (status != null && status.isNotEmpty) params['status'] = status;

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

  Future<Map<String, dynamic>> updateOrderStatus(
    int orderId,
    String status,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/orders/$orderId/status'),
        headers: await _getHeaders(),
        body: json.encode({'status': status}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update order status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating order status: $e');
    }
  }

  Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/orders/$orderId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load order details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching order details: $e');
    }
  }

  // ==================== ANALYTICS ====================
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

  Future<Map<String, dynamic>> getRevenueReport({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final params = <String, String>{};
      if (startDate != null && startDate.isNotEmpty) params['startDate'] = startDate;
      if (endDate != null && endDate.isNotEmpty) params['endDate'] = endDate;

      final queryString = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await http.get(
        Uri.parse('$_baseUrl/reports/revenue?$queryString'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load revenue report: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching revenue report: $e');
    }
  }

  // ==================== DISPUTE MANAGEMENT ====================
  Future<Map<String, dynamic>> getAllDisputes({
    int page = 1,
    int limit = 20,
    String? status,
    String? type,
  }) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (status != null && status.isNotEmpty) params['status'] = status;
      if (type != null && type.isNotEmpty) params['type'] = type;

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

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create dispute: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating dispute: $e');
    }
  }

  Future<Map<String, dynamic>> updateDisputeStatus(
    int disputeId,
    String status, {
    String? resolutionNotes,
  }) async {
    try {
      final body = <String, dynamic>{'status': status};
      if (resolutionNotes != null && resolutionNotes.isNotEmpty) {
        body['resolutionNotes'] = resolutionNotes;
      }

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

  Future<Map<String, dynamic>> getDisputeDetails(int disputeId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/disputes/$disputeId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load dispute details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching dispute details: $e');
    }
  }

  // ==================== BULK ACTIONS ====================
  Future<Map<String, dynamic>> bulkDeleteUsers(List<int> userIds) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/users/bulk-delete'),
        headers: await _getHeaders(),
        body: json.encode({'userIds': userIds}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to bulk delete users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error bulk deleting users: $e');
    }
  }

  Future<Map<String, dynamic>> bulkVerifyPharmacies(List<int> pharmacyIds) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/pharmacies/bulk-verify'),
        headers: await _getHeaders(),
        body: json.encode({'pharmacyIds': pharmacyIds, 'isVerified': true}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to bulk verify pharmacies: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error bulk verifying pharmacies: $e');
    }
  }

  // ==================== EXPORT REPORTS ====================
  Future<http.Response> exportUsersReport({String? role, String format = 'csv'}) async {
    try {
      final params = <String, String>{'format': format};
      if (role != null && role.isNotEmpty) params['role'] = role;

      final queryString = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await http.get(
        Uri.parse('$_baseUrl/export/users?$queryString'),
        headers: await _getHeaders(),
      );

      return response;
    } catch (e) {
      throw Exception('Error exporting users report: $e');
    }
  }

  Future<http.Response> exportOrdersReport({String? status, String format = 'csv'}) async {
    try {
      final params = <String, String>{'format': format};
      if (status != null && status.isNotEmpty) params['status'] = status;

      final queryString = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await http.get(
        Uri.parse('$_baseUrl/export/orders?$queryString'),
        headers: await _getHeaders(),
      );

      return response;
    } catch (e) {
      throw Exception('Error exporting orders report: $e');
    }
  }
}