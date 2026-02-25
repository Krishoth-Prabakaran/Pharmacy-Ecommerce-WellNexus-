// screens/patient_register_screen.dart
import 'package:flutter/material.dart';
import '../services/patient_service.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';

class PatientRegisterScreen extends StatefulWidget {
  // User data passed from registration screen – contains at least:
  // - user_id (int)
  // - username (String)
  // - email (String)
  // - token (String)
  final Map<String, dynamic> userData;

  const PatientRegisterScreen({
    Key? key,
    required this.userData,
  }) : super(key: key);

  @override
  State<PatientRegisterScreen> createState() => _PatientRegisterScreenState();
}

class _PatientRegisterScreenState extends State<PatientRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedGender;
  bool _isLoading = false;

  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    // Debug: log received user data
    print('📱 PatientRegisterScreen received user data: ${widget.userData}');
  }

  /// Show date picker and set selected date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)), // ~18 years
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// Save patient details to backend
  void _savePatientDetails() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Extract user_id and email from passed userData
      final userId = widget.userData['user_id'] ?? widget.userData['user']?['user_id'];
      final email = widget.userData['email'] ?? widget.userData['user']?['email'];

      // Prepare data for backend
      final patientData = {
        'user_id': userId,                    // Link to users table (primary)
        'email': email,                        // Fallback for backward compatibility
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'date_of_birth': _selectedDate?.toIso8601String().split('T').first,
        'gender': _selectedGender?.toLowerCase(),
      };

      // Call patient service
      final result = await PatientService().savePatientDetails(patientData);

      setState(() => _isLoading = false);

      if (result['success']) {
        _showSnackBar('Patient details saved successfully!', Colors.green);
        if (mounted) {
          // Navigate to dashboard after successful save
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const DashboardScreen(),
            ),
          );
        }
      } else {
        _showSnackBar(result['message'], Colors.red);
      }
    }
  }

  /// Show snackbar message
  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Skip patient details for now (go to dashboard)
  void _skipForNow() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const DashboardScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Patient Profile'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _skipForNow,
            child: const Text(
              'Skip',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),

              // Welcome card with user info
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.person_add,
                      size: 60,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Welcome, ${widget.userData['username']}!',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Please complete your profile information',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // First Name
                    TextFormField(
                      controller: _firstNameController,
                      decoration: InputDecoration(
                        labelText: 'First Name *',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your first name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Last Name
                    TextFormField(
                      controller: _lastNameController,
                      decoration: InputDecoration(
                        labelText: 'Last Name *',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your last name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Phone Number
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number *',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        if (value.length < 10) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date of Birth (optional)
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date of Birth',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedDate == null
                                  ? 'Select your date of birth'
                                  : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                              style: TextStyle(
                                color: _selectedDate == null
                                    ? Colors.grey.shade600
                                    : Colors.black,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Gender dropdown (optional)
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        prefixIcon: const Icon(Icons.wc),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                      ),
                      hint: const Text('Select your gender'),
                      value: _selectedGender,
                      items: _genders.map((String gender) {
                        return DropdownMenuItem<String>(
                          value: gender,
                          child: Text(gender),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedGender = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Submit button or loading indicator
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _savePatientDetails,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Save & Continue',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}