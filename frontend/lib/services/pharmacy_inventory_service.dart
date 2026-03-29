import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class PharmacyInventoryService {
  static const String baseUrl = 'http://localhost:5000/api/inventory';
  // For Android emulator: http://10.0.2.2:5000/api/inventory
  // For iOS emulator: http://localhost:5000/api/inventory

  Future<String?> _getToken() async {
    return await AuthService.getToken();
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path,
    {
      Map<String, dynamic>? body,
    }
  ) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl$path');

    final headers = {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    http.Response response;
    final payload = body != null ? jsonEncode(body) : null;

    if (method == 'GET') {
      response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));
    } else if (method == 'POST') {
      response = await http.post(uri, headers: headers, body: payload).timeout(const Duration(seconds: 15));
    } else if (method == 'PUT') {
      response = await http.put(uri, headers: headers, body: payload).timeout(const Duration(seconds: 15));
    } else if (method == 'DELETE') {
      response = await http.delete(uri, headers: headers).timeout(const Duration(seconds: 15));
    } else {
      throw Exception('Unsupported method $method');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMedicines() async {
    return await _request('GET', '/medicines');
  }

  Future<Map<String, dynamic>> createMedicine(Map<String, dynamic> data) async {
    return await _request('POST', '/medicines', body: data);
  }

  Future<Map<String, dynamic>> updateMedicine(int medicineId, Map<String, dynamic> data) async {
    return await _request('PUT', '/medicines/$medicineId', body: data);
  }

  Future<Map<String, dynamic>> deleteMedicine(int medicineId) async {
    return await _request('DELETE', '/medicines/$medicineId');
  }

  Future<Map<String, dynamic>> getVariants(int medicineId) async {
    return await _request('GET', '/medicines/$medicineId/variants');
  }

  Future<Map<String, dynamic>> createVariant(Map<String, dynamic> data) async {
    return await _request('POST', '/variants', body: data);
  }

  Future<Map<String, dynamic>> updateVariant(int variantId, Map<String, dynamic> data) async {
    return await _request('PUT', '/variants/$variantId', body: data);
  }

  Future<Map<String, dynamic>> deleteVariant(int variantId) async {
    return await _request('DELETE', '/variants/$variantId');
  }

  Future<Map<String, dynamic>> getDealers() async {
    return await _request('GET', '/dealers');
  }

  Future<Map<String, dynamic>> createDealer(Map<String, dynamic> data) async {
    return await _request('POST', '/dealers', body: data);
  }

  Future<Map<String, dynamic>> updateDealer(int dealerId, Map<String, dynamic> data) async {
    return await _request('PUT', '/dealers/$dealerId', body: data);
  }

  Future<Map<String, dynamic>> deleteDealer(int dealerId) async {
    return await _request('DELETE', '/dealers/$dealerId');
  }

  Future<Map<String, dynamic>> getStock(int pharmacyId) async {
    return await _request('GET', '/pharmacy-stock/$pharmacyId');
  }

  Future<Map<String, dynamic>> createStock(Map<String, dynamic> data) async {
    return await _request('POST', '/pharmacy-stock', body: data);
  }

  Future<Map<String, dynamic>> updateStock(int stockId, Map<String, dynamic> data) async {
    return await _request('PUT', '/pharmacy-stock/$stockId', body: data);
  }

  Future<Map<String, dynamic>> deleteStock(int stockId) async {
    return await _request('DELETE', '/pharmacy-stock/$stockId');
  }
}
