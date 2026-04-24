import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    try {
      final response = await AuthService.getAppointmentsByDoctor();
      
      if (response['success'] == true && response['appointments'] != null) {
        List<dynamic> appointmentsList = response['appointments'];
        setState(() {
          _appointments = appointmentsList.map<Map<String, dynamic>>((a) {
            return {
              'id': a['appointment_id'] ?? 0,
              'patient_name': '${a['patient_first_name'] ?? 'N/A'} ${a['patient_last_name'] ?? 'N/A'}'.trim(),
              'date': a['appointment_date'] ?? 'N/A',
              'time': a['appointment_time'] ?? 'N/A',
              'type': a['appointment_type'] ?? 'consultation',
              'status': a['status'] ?? 'scheduled',
              'notes': a['notes'] ?? '',
            };
          }).toList();
        });
      } else {
        // Use mock data if API fails
        setState(() {
          _appointments = [
            {
              'id': 1,
              'patient_name': 'John Doe',
              'date': '2024-01-15',
              'time': '10:00',
              'type': 'consultation',
              'status': 'scheduled',
              'notes': 'Regular checkup'
            },
            {
              'id': 2,
              'patient_name': 'Jane Smith',
              'date': '2024-01-15',
              'time': '14:30',
              'type': 'follow-up',
              'status': 'confirmed',
              'notes': 'Blood test results review'
            },
            {
              'id': 3,
              'patient_name': 'Mike Johnson',
              'date': '2024-01-16',
              'time': '11:00',
              'type': 'consultation',
              'status': 'completed',
              'notes': 'Initial consultation'
            },
          ];
        });
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load appointments: $error')),
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
          'Appointments',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6366F1),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF6366F1),
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF6366F1)),
            onPressed: _showCreateAppointmentDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAppointmentsList('today'),
                _buildAppointmentsList('upcoming'),
                _buildAppointmentsList('past'),
              ],
            ),
    );
  }

  Widget _buildAppointmentsList(String filter) {
    final filteredAppointments = _appointments.where((appointment) {
      final status = appointment['status'];
      switch (filter) {
        case 'today':
          return status == 'scheduled' || status == 'confirmed';
        case 'upcoming':
          return status == 'scheduled' || status == 'confirmed';
        case 'past':
          return status == 'completed' || status == 'cancelled';
        default:
          return true;
      }
    }).toList();

    if (filteredAppointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No $filter appointments',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredAppointments.length,
      itemBuilder: (context, index) {
        final appointment = filteredAppointments[index];
        return _buildAppointmentCard(appointment);
      },
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final statusColor = _getStatusColor(appointment['status']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                        appointment['patient_name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        '${appointment['date']} at ${appointment['time']}',
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
                    appointment['status'].toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (appointment['notes'] != null && appointment['notes'].isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                appointment['notes'],
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showAppointmentDetails(appointment),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF6366F1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(color: Color(0xFF6366F1)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (appointment['status'] == 'scheduled')
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateAppointmentStatus(appointment['id'], 'confirmed'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Confirm'),
                    ),
                  ),
                if (appointment['status'] == 'confirmed')
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateAppointmentStatus(appointment['id'], 'completed'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Complete'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return const Color(0xFFF59E0B);
      case 'confirmed':
        return const Color(0xFF10B981);
      case 'completed':
        return const Color(0xFF6366F1);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  void _showCreateAppointmentDialog() {
    // TODO: Implement create appointment dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create appointment feature coming soon!')),
    );
  }

  void _showAppointmentDetails(Map<String, dynamic> appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appointment Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Patient: ${appointment['patient_name']}'),
            Text('Date: ${appointment['date']}'),
            Text('Time: ${appointment['time']}'),
            Text('Type: ${appointment['appointment_type']}'),
            Text('Status: ${appointment['status']}'),
            if (appointment['notes'] != null) Text('Notes: ${appointment['notes']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _updateAppointmentStatus(int appointmentId, String newStatus) {
    // TODO: Implement API call to update status
    setState(() {
      final index = _appointments.indexWhere((a) => a['id'] == appointmentId);
      if (index != -1) {
        _appointments[index]['status'] = newStatus;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Appointment marked as $newStatus')),
    );
  }
}