import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';
import '../services/pharmacy_service.dart';
import '../utils/validators.dart';
import '../widgets/map_location_picker.dart';
import 'login_screen.dart';

class PharmacyRegisterScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const PharmacyRegisterScreen({
    Key? key,
    required this.userData,
  }) : super(key: key);

  @override
  State<PharmacyRegisterScreen> createState() => _PharmacyRegisterScreenState();
}

class _PharmacyRegisterScreenState extends State<PharmacyRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pharmacyNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  TimeOfDay? _openTime;
  TimeOfDay? _closeTime;

  bool _isLoading = false;

  final List<Map<String, dynamic>> _branches = [
    {
      'branch_name': 'Main Branch',
      'address': '',
      'phone': '',
      'latitude': null,
      'longitude': null,
      'open_time': null,
      'close_time': null,
      'is_main_branch': true,
    }
  ];

  final LatLng _defaultLocation = const LatLng(6.9271, 79.8612);

  @override
  void initState() {
    super.initState();
    print('📱 PharmacyRegisterScreen received: ');
  }

  Future<void> _selectTime(BuildContext context, bool isOpenTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isOpenTime ? (_openTime ?? TimeOfDay.now()) : (_closeTime ?? TimeOfDay.now()),
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
        if (isOpenTime) {
          _openTime = picked;
        } else {
          _closeTime = picked;
        }
      });
    }
  }

  void _setMainBranch(int index) {
    setState(() {
      for (var i = 0; i < _branches.length; i++) {
        _branches[i]['is_main_branch'] = i == index;
      }
    });
  }

  void _removeBranch(int index) {
    if (_branches.length <= 1) return;
    setState(() {
      _branches.removeAt(index);
    });
  }

  Future<void> _useCurrentLocation(int index) async {
    try {
      final position = await LocationService.getCurrentLocation();
      setState(() {
        _branches[index]['latitude'] = position.latitude;
        _branches[index]['longitude'] = position.longitude;
      });
    } catch (error) {
      _showSnackBar('Failed to get current location: $error', Colors.red);
    }
  }

  void _updateSelectedLocation(LatLng location, int index) {
    setState(() {
      _branches[index]['latitude'] = location.latitude;
      _branches[index]['longitude'] = location.longitude;
    });
  }

  void _addBranch() {
    setState(() {
      _branches.add({
        'branch_name': 'Branch ${_branches.length + 1}',
        'address': '',
        'phone': '',
        'latitude': null,
        'longitude': null,
        'open_time': null,
        'close_time': null,
        'is_main_branch': false,
      });
    });
  }

  String? _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return null;
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm:ss').format(dt);
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

  Future<void> _registerPharmacy() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final pharmacyData = {
        'pharmacy_name': _pharmacyNameController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'latitude': _latitudeController.text.isNotEmpty
            ? double.tryParse(_latitudeController.text.trim())
            : null,
        'longitude': _longitudeController.text.isNotEmpty
            ? double.tryParse(_longitudeController.text.trim())
            : null,
        'open_time': _formatTimeOfDay(_openTime),
        'close_time': _formatTimeOfDay(_closeTime),
        'username': widget.userData['username'],
        'email': widget.userData['email'],
        'user_id': widget.userData['user_id'],
      };

      final result = await PharmacyService().registerPharmacy(pharmacyData);

      setState(() => _isLoading = false);

      if (result['success']) {
        _showSnackBar('Pharmacy registered successfully! Please log in.', Colors.green);
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

  Widget _buildBranchCard(int index) {
    final branch = _branches[index];
    final isMainBranch = branch['is_main_branch'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Branch Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      branch['branch_name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    if (isMainBranch) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Main',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    if (!isMainBranch)
                      IconButton(
                        onPressed: () => _setMainBranch(index),
                        icon: const Icon(Icons.star_border, color: Color(0xFF6366F1)),
                        tooltip: 'Set as Main Branch',
                      ),
                    if (_branches.length > 1)
                      IconButton(
                        onPressed: () => _removeBranch(index),
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Remove Branch',
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Branch Name
            TextFormField(
              initialValue: branch['branch_name'],
              decoration: InputDecoration(
                labelText: 'Branch Name',
                labelStyle: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w600,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 12),
                  child: Icon(Icons.store_outlined, color: Colors.grey[400]),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
              ),
              onChanged: (value) {
                _branches[index]['branch_name'] = value;
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Branch name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Address
            TextFormField(
              initialValue: branch['address'],
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Address',
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
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
              ),
              onChanged: (value) {
                _branches[index]['address'] = value;
              },
              validator: (value) {
                return Validators.validateTextField(value, fieldName: 'Address', minLength: 5, maxLength: 255);
              },
            ),
            const SizedBox(height: 12),

            // Phone Number
            TextFormField(
              initialValue: branch['phone'],
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
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
              ),
              onChanged: (value) {
                _branches[index]['phone'] = value;
              },
              validator: (value) {
                return Validators.validatePhoneNumber(value);
              },
            ),
            const SizedBox(height: 12),

            // Location selector
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _useCurrentLocation(index),
                    icon: const Icon(Icons.my_location),
                    label: const Text('Use Current Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Map Location Picker
            MapLocationPicker(
              selectedLocation: branch['latitude'] != null && branch['longitude'] != null
                  ? LatLng(branch['latitude'] as double, branch['longitude'] as double)
                  : _defaultLocation,
              onLocationSelected: (location) => _updateSelectedLocation(location, index),
            ),

            // Open & Close Time
            const SizedBox(height: 12),
            const Text(
              'Operating Hours',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectTimeForBranch(context, index, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFF9FAFB),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time_outlined, color: Colors.grey[400], size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              branch['open_time'] == null
                                  ? 'Open Time'
                                  : (branch['open_time'] as TimeOfDay).format(context),
                              style: TextStyle(
                                color: branch['open_time'] == null ? Colors.grey[500] : Colors.grey[800],
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
                    onTap: () => _selectTimeForBranch(context, index, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFF9FAFB),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time_outlined, color: Colors.grey[400], size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              branch['close_time'] == null
                                  ? 'Close Time'
                                  : (branch['close_time'] as TimeOfDay).format(context),
                              style: TextStyle(
                                color: branch['close_time'] == null ? Colors.grey[500] : Colors.grey[800],
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
          ],
        ),
      ),
    );
  }

  Future<void> _selectTimeForBranch(BuildContext context, int branchIndex, bool isOpenTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _branches[branchIndex][isOpenTime ? 'open_time' : 'close_time'] ?? TimeOfDay.now(),
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
        _branches[branchIndex][isOpenTime ? 'open_time' : 'close_time'] = picked;
      });
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.white, Color(0xFFE0E7FF)],
                    ).createShader(bounds),
                    child: const Text(
                      'Pharmacy Details',
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
                    'Help patients find your pharmacy',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFFE0E7FF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
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
                          Icons.local_pharmacy,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Welcome, !',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F2937),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Complete your pharmacy information',
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
                        TextFormField(
                          controller: _pharmacyNameController,
                          decoration: InputDecoration(
                            labelText: 'Pharmacy Name',
                            labelStyle: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontWeight: FontWeight.w600,
                            ),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 16, right: 12),
                              child: Icon(Icons.store_outlined, color: Colors.grey[400]),
                            ),
                            prefixIconConstraints: const BoxConstraints(minWidth: 0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                          ),
                          validator: (value) {
                            return Validators.validateTextField(value, fieldName: 'Pharmacy name', minLength: 2, maxLength: 100);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Address
                        TextFormField(
                          controller: _addressController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Address',
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
                          validator: (value) {
                            return Validators.validateTextField(value, fieldName: 'Address', minLength: 5, maxLength: 255);
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

                        // Latitude & Longitude
                        Row(
                          children: [
                            const Text(
                              'Branches',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _addBranch,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Branch'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (_branches.isNotEmpty) ..._branches
                            .asMap()
                            .entries
                            .map((entry) => _buildBranchCard(entry.key))
                            .toList(),

                        const SizedBox(height: 16),

                        // Open & Close Time
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
                                          _openTime == null
                                              ? 'Open Time'
                                              : _openTime!.format(context),
                                          style: TextStyle(
                                            color: _openTime == null ? Colors.grey[500] : Colors.grey[800],
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
                                          _closeTime == null
                                              ? 'Close Time'
                                              : _closeTime!.format(context),
                                          style: TextStyle(
                                            color: _closeTime == null ? Colors.grey[500] : Colors.grey[800],
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
                        const SizedBox(height: 28),
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
                              onTap: _isLoading ? null : _registerPharmacy,
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
                                        'Register Pharmacy',
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
    _pharmacyNameController.dispose();
    super.dispose();
  }
}
