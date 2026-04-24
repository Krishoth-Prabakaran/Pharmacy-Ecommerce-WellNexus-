// =====================================================
// DOCTOR REGISTER SCREEN
// =====================================================
// This screen appears after a doctor registers their account
// Collects professional details: specialization, license, etc.
// =====================================================

import 'package:flutter/material.dart';
import '../services/doctor_service.dart';
import '../utils/validators.dart';
import 'login_screen.dart';

class DoctorRegisterScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const DoctorRegisterScreen({
    Key? key,
    required this.userData,
  }) : super(key: key);

  @override
  State<DoctorRegisterScreen> createState() => _DoctorRegisterScreenState();
}

class _DoctorRegisterScreenState extends State<DoctorRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _specializationController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _phoneController = TextEditingController();
  final _consultationFeeController = TextEditingController();
  final _experienceYearsController = TextEditingController();
  final _educationController = TextEditingController();
  final _clinicAddressController = TextEditingController();

  TimeOfDay? _availableFrom;
  TimeOfDay? _availableTo;

  bool _isLoading = false;

  final List<String> _specializations = [
    'Cardiologist',
    'Dermatologist',
    'Pediatrician',
    'Orthopedic',
    'Neurologist',
    'Gynecologist',
    'Ophthalmologist',
    'Psychiatrist',
    'Dentist',
    'General Physician',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    print('📱 DoctorRegisterScreen received: ${widget.userData}');
  }

  Future<void> _selectTime(BuildContext context, bool isFromTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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
        if (isFromTime) {
          _availableFrom = picked;
        } else {
          _availableTo = picked;
        }
      });
    }
  }

  String? _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return null;
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:00';
  }

  void _registerDoctor() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      if (widget.userData['user_id'] == null) {
        _showSnackBar('Unable to complete registration without verified user_id', Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      final doctorData = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'specialization': _specializationController.text.trim(),
        'license_number': _licenseNumberController.text.trim(),
        'phone': _phoneController.text.trim(),
        'consultation_fee': _consultationFeeController.text.isNotEmpty
            ? double.tryParse(_consultationFeeController.text.trim())
            : null,
        'experience_years': _experienceYearsController.text.isNotEmpty
            ? int.tryParse(_experienceYearsController.text.trim())
            : null,
        'available_from': _formatTimeOfDay(_availableFrom),
        'available_to': _formatTimeOfDay(_availableTo),
        'education': _educationController.text.trim(),
        'clinic_address': _clinicAddressController.text.trim(),
        'user_id': widget.userData['user_id'],
      };

      final result = await DoctorService().registerDoctor(doctorData);

      setState(() => _isLoading = false);

      if (result['success']) {
        _showSnackBar('Doctor registered successfully! Please log in.', Colors.green);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        });
      } else {
        _showSnackBar(result['message'], Colors.red);
      }
    }
  }

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

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.white, Color(0xFFE0E7FF)],
                    ).createShader(bounds),
                    child: const Text(
                      'Professional Details',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Share your expertise with patients',
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
                          Icons.medical_services,
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
                        'Complete your professional profile',
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

                        // Specialization
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!, width: 1.5),
                            color: const Color(0xFFF9FAFB),
                          ),
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Specialization',
                              labelStyle: const TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontWeight: FontWeight.w600,
                              ),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(left: 16, right: 12),
                                child: Icon(Icons.medical_services_outlined, color: Colors.grey[400]),
                              ),
                              prefixIconConstraints: const BoxConstraints(minWidth: 0),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            hint: const Text('Select specialization'),
                            initialValue: _specializationController.text.isNotEmpty 
                                ? _specializationController.text 
                                : null,
                            items: _specializations.map((spec) {
                              return DropdownMenuItem<String>(
                                value: spec,
                                child: Text(spec, style: const TextStyle(fontWeight: FontWeight.w600)),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _specializationController.text = newValue ?? '';
                              });
                            },
                            validator: (value) {
                              return Validators.validateSpecialization(value);
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // License Number
                        TextFormField(
                          controller: _licenseNumberController,
                          decoration: InputDecoration(
                            labelText: 'License Number',
                            labelStyle: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontWeight: FontWeight.w600,
                            ),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 16, right: 12),
                              child: Icon(Icons.badge_outlined, color: Colors.grey[400]),
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
                            return Validators.validateLicenseNumber(value);
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
                            return Validators.validatePhoneNumber(value);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Consultation Fee
                        TextFormField(
                          controller: _consultationFeeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Consultation Fee (₹)',
                            labelStyle: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontWeight: FontWeight.w600,
                            ),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 16, right: 12),
                              child: Icon(Icons.currency_rupee_rounded, color: Colors.grey[400]),
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
                            return Validators.validateConsultationFee(value);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Experience Years
                        TextFormField(
                          controller: _experienceYearsController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Experience (Years)',
                            labelStyle: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontWeight: FontWeight.w600,
                            ),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 16, right: 12),
                              child: Icon(Icons.work_history_outlined, color: Colors.grey[400]),
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
                        ),
                        const SizedBox(height: 16),

                        // Available Time Slots
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _selectTime(context, true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[3]!, width: 1.5),
                                    borderRadius: BorderRadius.circular(12),
                                    color: const Color(0xFFF9FAFB),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.access_time_outlined, color: Colors.grey[400], size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _availableFrom == null
                                              ? 'From'
                                              : _availableFrom!.format(context),
                                          style: TextStyle(
                                            color: _availableFrom == null ? Colors.grey[500] : Colors.grey[800],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _selectTime(context, false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[3]!, width: 1.5),
                                    borderRadius: BorderRadius.circular(12),
                                    color: const Color(0xFFF9FAFB),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.access_time_outlined, color: Colors.grey[400], size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _availableTo == null
                                              ? 'To'
                                              : _availableTo!.format(context),
                                          style: TextStyle(
                                            color: _availableTo == null ? Colors.grey[500] : Colors.grey[800],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Education
                        TextFormField(
                          controller: _educationController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Education (Optional)',
                            labelStyle: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontWeight: FontWeight.w600,
                            ),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 16, right: 12),
                              child: Icon(Icons.school_outlined, color: Colors.grey[400]),
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
                        ),
                        const SizedBox(height: 16),

                        // Clinic Address
                        TextFormField(
                          controller: _clinicAddressController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Clinic Address (Optional)',
                            labelStyle: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontWeight: FontWeight.w600,
                            ),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 16, right: 12),
                              child: Icon(Icons.location_on_outlined, color: Colors.grey[400]),
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
                        ),
                        const SizedBox(height: 28),

                        // Register Button
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
                              onTap: _isLoading ? null : _registerDoctor,
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
                                        'Register Doctor',
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
    _specializationController.dispose();
    _licenseNumberController.dispose();
    _phoneController.dispose();
    _consultationFeeController.dispose();
    _experienceYearsController.dispose();
    _educationController.dispose();
    _clinicAddressController.dispose();
    super.dispose();
  }
}