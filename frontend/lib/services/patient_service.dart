// lib/services/patient_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

// ==================== DATA MODELS ====================

/// Patient Dashboard Data Model
class PatientDashboardData {
  final UserInfo user;
  final PatientProfile? profile;
  final List<HealthMetric> healthMetrics;
  final List<Appointment> recentAppointments;
  final List<Prescription> recentPrescriptions;
  final List<MedicalRecord> medicalRecords;
  final PatientStats stats;

  PatientDashboardData({
    required this.user,
    this.profile,
    required this.healthMetrics,
    required this.recentAppointments,
    required this.recentPrescriptions,
    required this.medicalRecords,
    required this.stats,
  });

  factory PatientDashboardData.fromJson(Map<String, dynamic> json) {
    return PatientDashboardData(
      user: UserInfo.fromJson(json['user']),
      profile: json['profile'] != null ? PatientProfile.fromJson(json['profile']) : null,
      healthMetrics: (json['health_metrics'] as List?)
          ?.map((e) => HealthMetric.fromJson(e))
          .toList() ?? [],
      recentAppointments: (json['recent_appointments'] as List?)
          ?.map((e) => Appointment.fromJson(e))
          .toList() ?? [],
      recentPrescriptions: (json['recent_prescriptions'] as List?)
          ?.map((e) => Prescription.fromJson(e))
          .toList() ?? [],
      medicalRecords: (json['medical_records'] as List?)
          ?.map((e) => MedicalRecord.fromJson(e))
          .toList() ?? [],
      stats: PatientStats.fromJson(json['stats']),
    );
  }
}

/// User Information
class UserInfo {
  final int id;
  final String username;
  final String email;
  final String role;
  final DateTime memberSince;

  UserInfo({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.memberSince,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      role: json['role'],
      memberSince: DateTime.parse(json['member_since']),
    );
  }
}

/// Patient Profile
class PatientProfile {
  final String fullName;
  final String firstName;
  final String lastName;
  final String phone;
  final DateTime? dateOfBirth;
  final int? age;
  final String? gender;
  final int patientId;

  PatientProfile({
    required this.fullName,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.dateOfBirth,
    this.age,
    this.gender,
    required this.patientId,
  });

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    return PatientProfile(
      fullName: json['full_name'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      phone: json['phone'],
      dateOfBirth: json['date_of_birth'] != null 
          ? DateTime.parse(json['date_of_birth']) 
          : null,
      age: json['age'],
      gender: json['gender'],
      patientId: json['patient_id'],
    );
  }
}

/// Health Metric
class HealthMetric {
  final double? weight;
  final double? height;
  final int? bloodPressureSystolic;
  final int? bloodPressureDiastolic;
  final int? heartRate;
  final DateTime recordedAt;

  HealthMetric({
    this.weight,
    this.height,
    this.bloodPressureSystolic,
    this.bloodPressureDiastolic,
    this.heartRate,
    required this.recordedAt,
  });

  factory HealthMetric.fromJson(Map<String, dynamic> json) {
    return HealthMetric(
      weight: json['weight']?.toDouble(),
      height: json['height']?.toDouble(),
      bloodPressureSystolic: json['blood_pressure_systolic'],
      bloodPressureDiastolic: json['blood_pressure_diastolic'],
      heartRate: json['heart_rate'],
      recordedAt: DateTime.parse(json['recorded_at']),
    );
  }
}

/// Appointment
class Appointment {
  final int appointmentId;
  final String doctorName;
  final DateTime appointmentDate;
  final String appointmentTime;
  final String status;
  final String? reason;

  Appointment({
    required this.appointmentId,
    required this.doctorName,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.status,
    this.reason,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      appointmentId: json['appointment_id'],
      doctorName: json['doctor_name'],
      appointmentDate: DateTime.parse(json['appointment_date']),
      appointmentTime: json['appointment_time'],
      status: json['status'],
      reason: json['reason'],
    );
  }
}

/// Prescription
class Prescription {
  final int prescriptionId;
  final String medicationName;
  final String dosage;
  final String frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final String prescribedBy;

  Prescription({
    required this.prescriptionId,
    required this.medicationName,
    required this.dosage,
    required this.frequency,
    required this.startDate,
    this.endDate,
    required this.prescribedBy,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      prescriptionId: json['prescription_id'],
      medicationName: json['medication_name'],
      dosage: json['dosage'],
      frequency: json['frequency'],
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      prescribedBy: json['prescribed_by'],
    );
  }
}

/// Medical Record
class MedicalRecord {
  final int recordId;
  final String recordType;
  final DateTime recordDate;
  final String description;
  final String? doctorName;
  final String? fileUrl;

  MedicalRecord({
    required this.recordId,
    required this.recordType,
    required this.recordDate,
    required this.description,
    this.doctorName,
    this.fileUrl,
  });

  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    return MedicalRecord(
      recordId: json['record_id'],
      recordType: json['record_type'],
      recordDate: DateTime.parse(json['record_date']),
      description: json['description'],
      doctorName: json['doctor_name'],
      fileUrl: json['file_url'],
    );
  }
}

/// Patient Stats
class PatientStats {
  final int totalAppointments;
  final int totalPrescriptions;
  final bool hasCompleteProfile;

  PatientStats({
    required this.totalAppointments,
    required this.totalPrescriptions,
    required this.hasCompleteProfile,
  });

  factory PatientStats.fromJson(Map<String, dynamic> json) {
    return PatientStats(
      totalAppointments: json['total_appointments'],
      totalPrescriptions: json['total_prescriptions'],
      hasCompleteProfile: json['has_complete_profile'],
    );
  }
}

// ==================== PATIENT SERVICE ====================

class PatientService {
  // ==================== CONFIGURATION ====================
  static const String baseUrl = 'http://localhost:5000/api/patients';
  // For Android emulator: 'http://10.0.2.2:5000/api/patients'
  // For iOS emulator: 'http://localhost:5000/api/patients'

  // ==================== GET DASHBOARD DATA ====================
  Future<PatientDashboardData> getDashboardData(int userId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      print('📊 Fetching dashboard data for user_id: $userId');

      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('📥 Dashboard response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return PatientDashboardData.fromJson(data);
      } else {
        throw Exception('Failed to load dashboard data');
      }
    } catch (e) {
      print('❌ Dashboard error: $e');
      throw Exception('Error loading dashboard: $e');
    }
  }

  Future<Map<String, dynamic>> getAvailablePharmacyStock({String search = ''}) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      print('📊 Fetching available pharmacy stock, search=$search');

      final uri = Uri.parse('http://localhost:5000/api/inventory/pharmacy-stock').replace(
        queryParameters: search.isNotEmpty ? {'q': search} : null,
      );
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('📥 Stock response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data as Map<String, dynamic>;
      }

      return {'success': false, 'message': 'Failed to load available stock'};
    } catch (e) {
      print('❌ Fetch available stock error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ==================== SAVE PATIENT DETAILS ====================
  Future<Map<String, dynamic>> savePatientDetails(Map<String, dynamic> patientData) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      print('📡 Saving patient details: $patientData');

      final response = await http.post(
        Uri.parse('$baseUrl/details'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(patientData),
      ).timeout(const Duration(seconds: 10));

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
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
  Future<bool> hasPatientDetails(int userId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      print('🔍 Checking patient details for user_id: $userId');

      final response = await http.get(
        Uri.parse('$baseUrl/$userId/check'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

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