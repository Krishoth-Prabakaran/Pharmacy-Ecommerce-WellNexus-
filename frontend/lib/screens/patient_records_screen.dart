import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'create_prescription_screen.dart';
import 'patient_detail_screen.dart';
import 'prescription_history_screen.dart';

class PatientRecordsScreen extends StatefulWidget {
  const PatientRecordsScreen({super.key});

  @override
  State<PatientRecordsScreen> createState() => _PatientRecordsScreenState();
}

class _PatientRecordsScreenState extends State<PatientRecordsScreen> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _patients = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() => _isLoading = true);
    try {
      final response = await AuthService.getPatients();
      
      if (response['success'] == true && response['patients'] != null) {
        List<dynamic> patientsList = response['patients'];
        setState(() {
          _patients = patientsList.map<Map<String, dynamic>>((p) {
            return {
              'id': p['patient_id'] ?? 0,
              'user_id': p['user_id'],
              'name': '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim(),
              'phone': p['phone'] ?? 'N/A',
              'email': p['email'] ?? 'N/A',
              'last_visit': 'N/A', // Would need data from appointments table
              'prescription_count': p['prescription_count'] ?? 0,
              'status': 'active',
              'date_of_birth': p['date_of_birth'],
              'gender': p['gender'],
            };
          }).toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Failed to load patients')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading patients: $error')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchPatients(String query) async {
    if (query.isEmpty) {
      _loadPatients();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await AuthService.getPatients(searchQuery: query);
      
      if (response['success'] == true && response['patients'] != null) {
        List<dynamic> patientsList = response['patients'];
        setState(() {
          _patients = patientsList.map<Map<String, dynamic>>((p) {
            return {
              'id': p['patient_id'] ?? 0,
              'user_id': p['user_id'],
              'name': '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim(),
              'phone': p['phone'] ?? 'N/A',
              'email': p['email'] ?? 'N/A',
              'last_visit': 'N/A',
              'prescription_count': p['prescription_count'] ?? 0,
              'status': 'active',
              'date_of_birth': p['date_of_birth'],
              'gender': p['gender'],
            };
          }).toList();
        });
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search error: $error')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Patient Records',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF6366F1)),
            onPressed: () {
              showSearch(
                context: context,
                delegate: PatientSearchDelegate(_patients, _viewPatientDetails),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _searchPatients(value);
              },
              decoration: InputDecoration(
                hintText: 'Search patients...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                ),
              ),
            ),
          ),

          // Patient list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _patients.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty ? 'No patients found' : 'No patients match your search',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _patients.length,
                        itemBuilder: (context, index) {
                          final patient = _patients[index];
                          return _buildPatientCard(patient);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    final statusColor = patient['status'] == 'active' ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _viewPatientDetails(patient),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.person,
                      color: statusColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          patient['phone'],
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      patient['status'].toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      '${patient['prescription_count']}',
                      'Prescriptions',
                      const Color(0xFF6366F1),
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      patient['last_visit'],
                      'Last Visit',
                      const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _viewPrescriptionHistory(patient),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF6366F1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'View History',
                        style: TextStyle(color: Color(0xFF6366F1)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _createNewPrescription(patient),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('New Rx'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _viewPatientDetails(Map<String, dynamic> patient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientDetailScreen(patient: patient),
      ),
    );
  }

  void _viewPrescriptionHistory(Map<String, dynamic> patient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrescriptionHistoryScreen(patient: patient),
      ),
    );
  }

  void _createNewPrescription(Map<String, dynamic> patient) {
    // Navigate to create prescription screen with pre-selected patient
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePrescriptionScreen(preSelectedPatient: patient),
      ),
    );
  }
}

class PatientSearchDelegate extends SearchDelegate<String> {
  final List<Map<String, dynamic>> patients;
  final Function(Map<String, dynamic>) onPatientSelected;

  PatientSearchDelegate(this.patients, this.onPatientSelected);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = patients.where((patient) {
      final name = patient['name'].toString().toLowerCase();
      final phone = patient['phone'].toString().toLowerCase();
      final email = patient['email'].toString().toLowerCase();
      final searchQuery = query.toLowerCase();
      return name.contains(searchQuery) || phone.contains(searchQuery) || email.contains(searchQuery);
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final patient = results[index];
        return ListTile(
          title: Text(patient['name']),
          subtitle: Text(patient['phone']),
          onTap: () {
            onPatientSelected(patient);
            close(context, patient['name']);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}