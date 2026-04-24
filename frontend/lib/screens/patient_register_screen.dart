// screens/patient_register_screen.dart
import 'package:flutter/material.dart';
import '../services/patient_service.dart';
import '../utils/validators.dart';
import 'doctor_dashboard_screen.dart';

/// PatientRegisterScreen - Collects additional patient information
/// This screen appears after registration ONLY for patients who haven't
/// completed their profile (first_name, last_name, phone, etc.)
class PatientRegisterScreen extends StatefulWidget {
  // User data passed from registration screen – contains:
  // - user_id (int) - Primary key from users table
  // - username (String) - User's chosen username
  // - email (String) - User's email (lowercase)
  // - token (String) - JWT token for authentication
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

  DateTime? _selectedDate; // Selected date of birth
  String? _selectedGender; // Selected gender from dropdown
  bool _isLoading = false;

  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    // Debug log to verify received user data
    print('📱 PatientRegisterScreen received user data: ${widget.userData}');
  }

  /// Show date picker and set selected date
  /// Uses showDatePicker with custom theme to match app colors
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)), // ~18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue, // Header color
              onPrimary: Colors.white, // Header text color
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
  /// Sends data to /api/patients/details endpoint
  /// IMPORTANT: Uses user_id to link patient record with users table
  void _savePatientDetails() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Extract user_id from passed userData (handle both flat and nested structures)
      final userId = widget.userData['user_id'] ?? widget.userData['user']?['user_id'];
      final email = widget.userData['email'] ?? widget.userData['user']?['email'];

      // Prepare data for backend
      // Format date as YYYY-MM-DD for PostgreSQL DATE field
      final patientData = {
        'user_id': userId,                    // PRIMARY LINK: Links to users table
        'email': email,                        // Fallback for backward compatibility
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'date_of_birth': _selectedDate?.toIso8601String().split('T').first, // Format: YYYY-MM-DD
        'gender': _selectedGender?.toLowerCase(), // Store as lowercase in DB
      };

      print('📤 Sending patient data: $patientData'); // Debug log

      // Call patient service to save details
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

  /// Show snackbar message with custom color
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
  /// Useful for testing or if user wants to complete later
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Header with Skip button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Colors.white, Color(0xFFE0E7FF)],
                        ).createShader(bounds),
                        child: const Text(
                          'Complete Profile',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _skipForNow,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: const Text(
                            'Skip',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Add your details to unlock full access',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFFE0E7FF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Welcome Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFFFFF), Color(0xFFF0F4FF)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.health_and_safety,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Welcome, ${widget.userData['username']}!',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F2937),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Complete your health profile',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Form Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // First Name
                        TextFormField(
                          controller: _firstNameController,
                          decoration: InputDecoration(
                            labelText: 'First Name',
                            labelStyle: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontWeight: FontWeight.w600,
                            ),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 16, right: 12),
                              child: Icon(Icons.person_outline, color: Colors.grey[400]),
                            ),
                            prefixIconConstraints: const BoxConstraints(minWidth: 0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                          ),
                          validator: (value) {
                            return Validators.validateName(value, fieldName: 'First name');
                          },
                        ),
                        const SizedBox(height: 16),

                        // Last Name
                        TextFormField(
                          controller: _lastNameController,
                          decoration: InputDecoration(
                            labelText: 'Last Name',
                            labelStyle: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontWeight: FontWeight.w600,
                            ),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 16, right: 12),
                              child: Icon(Icons.person_outline, color: Colors.grey[400]),
                            ),
                            prefixIconConstraints: const BoxConstraints(minWidth: 0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[3]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[3]!, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                          ),
                          validator: (value) {
                            return Validators.validateName(value, fieldName: 'Last name');
                          },
                        ),
                        const SizedBox(height: 16),

                        // Phone Number
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            labelStyle: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontWeight: FontWeight.w600,
                            ),
                            hintText: '0XXXXXXXXX or +94XXXXXXXXX',
                            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 16, right: 12),
                              child: Icon(Icons.phone_outlined, color: Colors.grey[400]),
                            ),
                            prefixIconConstraints: const BoxConstraints(minWidth: 0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                          ),
                          validator: (value) {
                            return Validators.validatePhoneNumber(value);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Date of Birth
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                              color: const Color(0xFFF9FAFB),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, color: Colors.grey[400], size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _selectedDate == null
                                        ? 'Date of Birth (Optional)'
                                        : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                    style: TextStyle(
                                      color: _selectedDate == null ? Colors.grey[500] : Colors.grey[800],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Gender Dropdown
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!, width: 1.5),
                            color: const Color(0xFFF9FAFB),
                          ),
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Gender (Optional)',
                              labelStyle: const TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontWeight: FontWeight.w600,
                              ),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(left: 16, right: 12),
                                child: Icon(Icons.wc_outlined, color: Colors.grey[400]),
                              ),
                              prefixIconConstraints: const BoxConstraints(minWidth: 0),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            hint: const Text('Select gender'),
                            initialValue: _selectedGender,
                            items: _genders.map((String gender) {
                              return DropdownMenuItem<String>(
                                value: gender,
                                child: Text(gender, style: const TextStyle(fontWeight: FontWeight.w600)),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedGender = newValue;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Save Button
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF6366F1),
                                Color(0xFF8B5CF6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isLoading ? null : _savePatientDetails,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: _isLoading
                                    ? const Center(
                                        child: SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            strokeWidth: 2.5,
                                          ),
                                        ),
                                      )
                                    : const Text(
                                        'Save & Continue',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
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