// backend/utils/validators.js

class Validators {
  // ==================== EMAIL VALIDATION ====================
  static validateEmail(email) {
    if (!email || typeof email !== 'string') {
      return { valid: false, message: 'Email is required' };
    }

    // RFC 5322 simplified regex for email validation
    const emailRegex = /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/;
    
    if (!emailRegex.test(email.trim())) {
      return { valid: false, message: 'Please enter a valid email address' };
    }

    return { valid: true };
  }

  // ==================== PASSWORD VALIDATION ====================
  // Requirements:
  // - Minimum 8 characters
  // - At least one uppercase letter (A-Z)
  // - At least one lowercase letter (a-z)
  // - At least one number (0-9)
  // - At least one special character (!@#$%^&*)
  static validatePassword(password) {
    if (!password || typeof password !== 'string') {
      return { valid: false, message: 'Password is required' };
    }

    if (password.length < 8) {
      return { valid: false, message: 'Password must be at least 8 characters' };
    }

    if (password.length > 128) {
      return { valid: false, message: 'Password must not exceed 128 characters' };
    }

    if (!/[A-Z]/.test(password)) {
      return { valid: false, message: 'Password must contain at least one uppercase letter' };
    }

    if (!/[a-z]/.test(password)) {
      return { valid: false, message: 'Password must contain at least one lowercase letter' };
    }

    if (!/[0-9]/.test(password)) {
      return { valid: false, message: 'Password must contain at least one number' };
    }

    if (!/[!@#$%^&*()_+\-=\[\]{};:'",.<>?/\\|`~]/.test(password)) {
      return { valid: false, message: 'Password must contain at least one special character' };
    }

    return { valid: true };
  }

  // ==================== USERNAME VALIDATION ====================
  // Requirements:
  // - Minimum 3 characters
  // - Maximum 30 characters
  // - Only alphanumeric characters, underscores, and hyphens
  static validateUsername(username) {
    if (!username || typeof username !== 'string') {
      return { valid: false, message: 'Username is required' };
    }

    if (username.length < 3) {
      return { valid: false, message: 'Username must be at least 3 characters' };
    }

    if (username.length > 30) {
      return { valid: false, message: 'Username must not exceed 30 characters' };
    }

    if (!/^[a-zA-Z0-9_-]+$/.test(username)) {
      return { valid: false, message: 'Username can only contain letters, numbers, underscores, and hyphens' };
    }

    return { valid: true };
  }

  // ==================== PHONE NUMBER VALIDATION (Sri Lankan) ====================
  // Sri Lankan mobile: 07X XXXXXXX (10 digits total)
  // Formats accepted:
  // - 0XXXXXXXXXX (10 digits starting with 0)
  // - +94XXXXXXXXX (11 characters: +94 followed by 9 digits)
  static validatePhoneNumber(phone) {
    if (!phone || typeof phone !== 'string') {
      return { valid: false, message: 'Phone number is required' };
    }

    // Remove spaces and hyphens
    const cleanedPhone = phone.replace(/[\s\-]/g, '');

    // Format 1: 0XXXXXXXXXX (10 digits starting with 0)
    if (/^0\d{9}$/.test(cleanedPhone)) {
      return { valid: true };
    }

    // Format 2: +94XXXXXXXXX (11 characters: +94 followed by 9 digits)
    if (/^\+94\d{9}$/.test(cleanedPhone)) {
      return { valid: true };
    }

    // Format 3: 94XXXXXXXXX (11 digits starting with 94)
    if (/^94\d{9}$/.test(cleanedPhone)) {
      return { valid: true };
    }

    return {
      valid: false,
      message: 'Please enter a valid Sri Lankan phone number (e.g., 0XXXXXXXXX or +94XXXXXXXXX)',
    };
  }

  // ==================== NAME VALIDATION ====================
  static validateName(name, fieldName = 'Name') {
    if (!name || typeof name !== 'string') {
      return { valid: false, message: `${fieldName} is required` };
    }

    if (name.length < 2) {
      return { valid: false, message: `${fieldName} must be at least 2 characters` };
    }

    if (name.length > 50) {
      return { valid: false, message: `${fieldName} must not exceed 50 characters` };
    }

    if (!/^[a-zA-Z\s.\-']+$/.test(name)) {
      return {
        valid: false,
        message: `${fieldName} can only contain letters, spaces, dots, hyphens, and apostrophes`,
      };
    }

    return { valid: true };
  }

  // ==================== LATITUDE VALIDATION ====================
  static validateLatitude(latitude) {
    if (!latitude) {
      return { valid: true }; // Optional
    }

    const lat = parseFloat(latitude);

    if (isNaN(lat)) {
      return { valid: false, message: 'Please enter a valid latitude value' };
    }

    if (lat < -90 || lat > 90) {
      return { valid: false, message: 'Latitude must be between -90 and 90' };
    }

    return { valid: true };
  }

  // ==================== LONGITUDE VALIDATION ====================
  static validateLongitude(longitude) {
    if (!longitude) {
      return { valid: true }; // Optional
    }

    const lon = parseFloat(longitude);

    if (isNaN(lon)) {
      return { valid: false, message: 'Please enter a valid longitude value' };
    }

    if (lon < -180 || lon > 180) {
      return { valid: false, message: 'Longitude must be between -180 and 180' };
    }

    return { valid: true };
  }

  // ==================== GENERAL TEXT FIELD VALIDATION ====================
  static validateTextField(value, fieldName = 'This field', minLength = 1, maxLength = 255) {
    if (!value || typeof value !== 'string') {
      return { valid: false, message: `${fieldName} is required` };
    }

    if (value.length < minLength) {
      return { valid: false, message: `${fieldName} must be at least ${minLength} characters` };
    }

    if (value.length > maxLength) {
      return { valid: false, message: `${fieldName} must not exceed ${maxLength} characters` };
    }

    return { valid: true };
  }

  // ==================== NUMERIC VALIDATION ====================
  static validateNumeric(value, fieldName = 'This field') {
    if (!value || typeof value !== 'string') {
      return { valid: false, message: `${fieldName} is required` };
    }

    if (!/^[0-9]+$/.test(value)) {
      return { valid: false, message: `${fieldName} must contain only numbers` };
    }

    return { valid: true };
  }

  // ==================== LICENSE NUMBER VALIDATION ====================
  static validateLicenseNumber(license) {
    if (!license || typeof license !== 'string') {
      return { valid: false, message: 'License number is required' };
    }

    if (license.length < 4) {
      return { valid: false, message: 'License number must be at least 4 characters' };
    }

    if (license.length > 30) {
      return { valid: false, message: 'License number must not exceed 30 characters' };
    }

    return { valid: true };
  }

  // ==================== SPECIALIZATION VALIDATION ====================
  static validateSpecialization(specialization) {
    if (!specialization || typeof specialization !== 'string') {
      return { valid: false, message: 'Please select a specialization' };
    }

    return { valid: true };
  }

  // ==================== CONSULTATION FEE VALIDATION ====================
  static validateConsultationFee(fee) {
    if (!fee) {
      return { valid: false, message: 'Consultation fee is required' };
    }

    const parsedFee = parseFloat(fee);

    if (isNaN(parsedFee)) {
      return { valid: false, message: 'Please enter a valid consultation fee' };
    }

    if (parsedFee <= 0) {
      return { valid: false, message: 'Consultation fee must be greater than 0' };
    }

    if (parsedFee > 1000000) {
      return { valid: false, message: 'Consultation fee seems too high' };
    }

    return { valid: true };
  }

  // ==================== ROLE VALIDATION ====================
  static validateRole(role) {
    const validRoles = ['patient', 'doctor', 'pharmacist', 'admin'];

    if (!role || typeof role !== 'string') {
      return { valid: false, message: 'Role is required' };
    }

    if (!validRoles.includes(role.toLowerCase())) {
      return { valid: false, message: `Role must be one of: ${validRoles.join(', ')}` };
    }

    return { valid: true };
  }
}

module.exports = Validators;
