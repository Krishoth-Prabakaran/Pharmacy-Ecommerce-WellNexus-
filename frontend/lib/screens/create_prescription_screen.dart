import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class CreatePrescriptionScreen extends StatefulWidget {
  final Map<String, dynamic>? preSelectedPatient;

  const CreatePrescriptionScreen({super.key, this.preSelectedPatient});

  @override
  State<CreatePrescriptionScreen> createState() => _CreatePrescriptionScreenState();
}

class _CreatePrescriptionScreenState extends State<CreatePrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientIdController = TextEditingController();
  final _doctorNameController = TextEditingController();
  final _medicineNameController = TextEditingController();
  DateTime? _prescriptionDate;
  DateTime? _validUntilDate;
  String? _status = 'active';
  bool _isLoading = false;

  // Prescription items
  final List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadDoctorInfo();
    _preFillPatientData();
  }

  void _preFillPatientData() {
    if (widget.preSelectedPatient != null) {
      final patient = widget.preSelectedPatient!;
      _patientIdController.text = patient['user_id']?.toString() ?? '';
      // You could also pre-fill other patient-related fields if available
    }
  }

  @override
  void dispose() {
    _patientIdController.dispose();
    _doctorNameController.dispose();
    _medicineNameController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctorInfo() async {
    final userData = await AuthService.getUserData();
    if (userData != null) {
      // For now, we'll use a placeholder doctor name
      // In a real app, you'd fetch doctor details from the API
      setState(() {
        _doctorNameController.text = 'Dr. ${userData['username'] ?? 'Doctor'}';
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isPrescriptionDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isPrescriptionDate) {
          _prescriptionDate = picked;
        } else {
          _validUntilDate = picked;
        }
      });
    }
  }

  void _addItem() {
    setState(() {
      _items.add({
        'variant_id': '',
        'dosage': '',
        'duration_days': '',
      });
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _updateItem(int index, String field, String value) {
    setState(() {
      _items[index][field] = value;
    });
  }

  Future<void> _createPrescription() async {
    if (!_formKey.currentState!.validate()) return;

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one prescription item')),
      );
      return;
    }

    // Validate items
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item['variant_id'].isEmpty || item['dosage'].isEmpty || item['duration_days'].isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill all fields for item ${i + 1}')),
        );
        return;
      }
      final duration = int.tryParse(item['duration_days']);
      if (duration == null || duration <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Duration days must be a positive number for item ${i + 1}')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final userData = await AuthService.getUserData();
      if (userData == null) {
        throw 'User not logged in';
      }

      final prescriptionData = {
        'patient_id': int.parse(_patientIdController.text.trim()),
        'doctor_name': _doctorNameController.text.trim(),
        'prescription_date': _prescriptionDate?.toIso8601String().split('T')[0] ?? DateTime.now().toIso8601String().split('T')[0],
        'valid_until': _validUntilDate?.toIso8601String().split('T')[0],
        'status': _status,
        'medicine_name': _medicineNameController.text.trim(),
        'doctor_license': userData['user_id'], // Using user_id as doctor license for now
        'items': _items.map((item) => ({
          'variant_id': int.parse(item['variant_id']),
          'dosage': item['dosage'],
          'duration_days': int.parse(item['duration_days']),
        })).toList(),
      };

      final response = await AuthService.createPrescription(prescriptionData);

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prescription created successfully!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Failed to create prescription')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6366F1),
              Color(0xFF8B5CF6),
              Color(0xFFEC4899),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Create Prescription',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Prescription Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Patient ID
                          TextFormField(
                            controller: _patientIdController,
                            decoration: const InputDecoration(
                              labelText: 'Patient ID *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Patient ID is required';
                              }
                              final patientId = int.tryParse(value);
                              if (patientId == null || patientId <= 0) {
                                return 'Please enter a valid patient ID';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Doctor Name
                          TextFormField(
                            controller: _doctorNameController,
                            decoration: const InputDecoration(
                              labelText: 'Doctor Name *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.medical_services),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Doctor name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Medicine Name
                          TextFormField(
                            controller: _medicineNameController,
                            decoration: const InputDecoration(
                              labelText: 'Medicine Name',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.medication),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Prescription Date
                          InkWell(
                            onTap: () => _selectDate(context, true),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Prescription Date',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                _prescriptionDate != null
                                    ? '${_prescriptionDate!.day}/${_prescriptionDate!.month}/${_prescriptionDate!.year}'
                                    : DateTime.now().toString().split(' ')[0],
                                style: TextStyle(
                                  color: _prescriptionDate != null ? Colors.black : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Valid Until
                          InkWell(
                            onTap: () => _selectDate(context, false),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Valid Until (Optional)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                _validUntilDate != null
                                    ? '${_validUntilDate!.day}/${_validUntilDate!.month}/${_validUntilDate!.year}'
                                    : 'Select expiry date',
                                style: TextStyle(
                                  color: _validUntilDate != null ? Colors.black : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Status
                          DropdownButtonFormField<String>(
                            value: _status,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.info),
                            ),
                            items: ['active', 'inactive', 'expired']
                                .map((status) => DropdownMenuItem(
                                      value: status,
                                      child: Text(status.toUpperCase()),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() => _status = value);
                            },
                          ),
                          const SizedBox(height: 24),

                          // Prescription Items
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Prescription Items',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _addItem,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Item'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6366F1),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          ..._items.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text('Item ${index + 1}'),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _removeItem(index),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      initialValue: item['variant_id'],
                                      decoration: const InputDecoration(
                                        labelText: 'Medicine Variant ID *',
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (value) => _updateItem(index, 'variant_id', value),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      initialValue: item['dosage'],
                                      decoration: const InputDecoration(
                                        labelText: 'Dosage *',
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (value) => _updateItem(index, 'dosage', value),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      initialValue: item['duration_days'],
                                      decoration: const InputDecoration(
                                        labelText: 'Duration (Days) *',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) => _updateItem(index, 'duration_days', value),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),

                          const SizedBox(height: 32),

                          // Create Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _createPrescription,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      'Create Prescription',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}