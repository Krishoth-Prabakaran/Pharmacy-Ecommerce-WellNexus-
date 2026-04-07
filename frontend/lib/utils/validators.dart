// lib/utils/validators.dart

class Validators {
  // ==================== EMAIL VALIDATION ====================
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an email';
    }
    // RFC 5322 simplified regex for email validation
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    );
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // ==================== PASSWORD VALIDATION ====================
  // Requirements:
  // - Minimum 8 characters
  // - At least one uppercase letter (A-Z)
  // - At least one lowercase letter (a-z)
  // - At least one number (0-9)
  // - At least one special character (!@#$%^&*)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (value.length > 128) {
      return 'Password must not exceed 128 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    if (!RegExp(r'[!@#$%^&*()\-_=\[\]{};:,.<>?/\\|`~]').hasMatch(value)) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  // ==================== CONFIRM PASSWORD VALIDATION ====================
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  // ==================== USERNAME VALIDATION ====================
  // Requirements:
  // - Minimum 3 characters
  // - Maximum 30 characters
  // - Only alphanumeric characters, underscores, and hyphens
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a username';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (value.length > 30) {
      return 'Username must not exceed 30 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value)) {
      return 'Username can only contain letters, numbers, underscores, and hyphens';
    }
    return null;
  }

  // ==================== PHONE NUMBER VALIDATION (Sri Lankan) ====================
  // Sri Lankan mobile: 07X XXXXXXX (10 digits total)
  // Formats accepted:
  // - 0XXXXXXXXXX (10 digits starting with 0)
  // - +94XXXXXXXXX (11 characters: +94 followed by 9 digits)
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a phone number';
    }

    // Remove spaces and hyphens
    final cleanedPhone = value.replaceAll(RegExp(r'[\s\-]'), '');

    // Check if it's valid Sri Lankan format
    // Format 1: 0XXXXXXXXXX (10 digits starting with 0)
    if (RegExp(r'^0\d{9}$').hasMatch(cleanedPhone)) {
      return null;
    }

    // Format 2: +94XXXXXXXXX (11 characters: +94 followed by 9 digits)
    if (RegExp(r'^\+94\d{9}$').hasMatch(cleanedPhone)) {
      return null;
    }

    // Format 3: 94XXXXXXXXX (11 digits starting with 94)
    if (RegExp(r'^94\d{9}$').hasMatch(cleanedPhone)) {
      return null;
    }

    return 'Please enter a valid Sri Lankan phone number (e.g., 0XXXXXXXXX or +94XXXXXXXXX)';
  }

  // ==================== NAME VALIDATION ====================
  static String? validateName(String? value, {String fieldName = 'Name'}) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
    }
    if (value.length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    if (value.length > 50) {
      return '$fieldName must not exceed 50 characters';
    }
    if (!RegExp(r"^[a-zA-Z\s.\-']+$").hasMatch(value)) {
      return '$fieldName can only contain letters, spaces, dots, hyphens, and apostrophes';
    }
    return null;
  }

  // ==================== LATITUDE VALIDATION ====================
  static String? validateLatitude(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    try {
      final lat = double.parse(value);
      if (lat < -90 || lat > 90) {
        return 'Latitude must be between -90 and 90';
      }
      return null;
    } catch (e) {
      return 'Please enter a valid latitude value';
    }
  }

  // ==================== LONGITUDE VALIDATION ====================
  static String? validateLongitude(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    try {
      final lon = double.parse(value);
      if (lon < -180 || lon > 180) {
        return 'Longitude must be between -180 and 180';
      }
      return null;
    } catch (e) {
      return 'Please enter a valid longitude value';
    }
  }

  // ==================== GENERAL TEXT FIELD VALIDATION ====================
  static String? validateTextField(String? value, {String fieldName = 'This field', int minLength = 1, int maxLength = 255}) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
    }
    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    if (value.length > maxLength) {
      return '$fieldName must not exceed $maxLength characters';
    }
    return null;
  }

  // ==================== NUMERIC VALIDATION ====================
  static String? validateNumeric(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return '$fieldName must contain only numbers';
    }
    return null;
  }

  // ==================== LICENSE NUMBER VALIDATION ====================
  static String? validateLicenseNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter license number';
    }
    if (value.length < 4) {
      return 'License number must be at least 4 characters';
    }
    if (value.length > 30) {
      return 'License number must not exceed 30 characters';
    }
    return null;
  }

  // ==================== SPECIALIZATION VALIDATION ====================
  static String? validateSpecialization(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a specialization';
    }
    return null;
  }

  // ==================== CONSULTATION FEE VALIDATION ====================
  static String? validateConsultationFee(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter consultation fee';
    }
    try {
      final fee = double.parse(value);
      if (fee <= 0) {
        return 'Consultation fee must be greater than 0';
      }
      if (fee > 1000000) {
        return 'Consultation fee seems too high';
      }
      return null;
    } catch (e) {
      return 'Please enter a valid consultation fee';
    }
  }
}
