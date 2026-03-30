// frontend/lib/screens/verify_email_screen.dar
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import 'patient_register_screen.dart';
import 'pharmacy_register_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const VerifyEmailScreen({Key? key, required this.userData}) : super(key: key);

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _verifyOtp() async {
    String otp = _controllers.map((c) => c.text).join();
    if (otp.length < 6) {
      setState(() => _errorMessage = "Please enter all 6 digits");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await AuthService().verifyOtp(
        widget.userData['email'],
        otp,
      );

      if (result['success']) {
        if (mounted) _navigateBasedOnRole(result['user']);
      } else {
        setState(() => _errorMessage = result['message'] ?? "Invalid OTP");
      }
    } catch (e) {
      setState(() => _errorMessage = "Connection error. Try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateBasedOnRole(Map<String, dynamic> user) {
    if (user['role'] == 'patient') {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => PatientRegisterScreen(userData: user))
      );
    } else if (user['role'] == 'pharmacist') {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => PharmacyRegisterScreen(userData: user))
      );
    } else {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("OTP Verification"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.security, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              "Verify Your Account",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              "Enter the 6-digit code sent to\n${widget.userData['email']}",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) => _buildOtpBox(index)),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 24),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
            const SizedBox(height: 40),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Verify & Register", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                // Logic to resend OTP could go here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Check your email for the new code")),
                );
              },
              child: const Text("Resend Code", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 45,
      height: 55,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: "",
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.blue, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          if (index == 5 && value.isNotEmpty) {
            FocusScope.of(context).unfocus();
          }
        },
      ),
    );
  }
}
