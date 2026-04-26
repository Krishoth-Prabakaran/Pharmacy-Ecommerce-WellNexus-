// backend/routes/authRoutes.js
const express = require("express");
const router = express.Router();
const rateLimit = require("express-rate-limit");
const authController = require("../controllers/authController");

/**
 * Authentication Routes
 * Base path: /api/auth
 */

// ==================== RATE LIMITING MIDDLEWARE ====================
// Protect against brute force attacks
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // 5 attempts per window
  message: "Too many login attempts. Please try again later.",
  standardHeaders: true,
  legacyHeaders: false,
});

const registerLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 3, // 3 registrations per hour per IP
  message: "Too many registrations from this IP. Please try again later.",
  standardHeaders: true,
  legacyHeaders: false,
});

const otpLimiter = rateLimit({
  windowMs: 5 * 60 * 1000, // 5 minutes
  max: 5, // 5 OTP verification attempts
  message: "Too many OTP attempts. Please try again later.",
  standardHeaders: true,
  legacyHeaders: false,
});

// ==================== PUBLIC ROUTES ====================

/**
 * @route   POST /api/auth/login
 * @desc    Authenticate user and return JWT token
 * @access  Public
 * @body    { email, password }
 * @returns { token, role, user_id, username, email, email_verified }
 */
router.post("/login", loginLimiter, authController.login);

/**
 * @route   POST /api/auth/register
 * @desc    Register new user and send verification email
 * @access  Public
 * @body    { username, email, password, role }
 * @returns { success, message, user, email_sent }
 */
router.post("/register", registerLimiter, authController.register);

 

/**

 * @route   POST /api/auth/verify-email

 * @desc    Verify user's email using token

 * @access  Public

 * @query   { token }

 * @returns { success, message, token, user } or redirects to frontend

 */

router.post("/verify-email", otpLimiter, authController.verifyEmail);

 

 

/**
 * @route   POST /api/auth/resend-verification
 * @desc    Resend verification email
 * @access  Public
 * @body    { email }
 * @returns { success, message, email_sent }
 */
router.post("/resend-verification", otpLimiter, authController.resendVerification);

/**
 * @route   GET /api/auth/verification-status
 * @desc    Check if user's email is verified
 * @access  Public
 * @query   { email }
 * @returns { success, verified, user }
 */
router.get("/verification-status", authController.checkVerificationStatus);

// ==================== PROTECTED ROUTES ====================

/**
 * @route   GET /api/auth/user/:userId
 * @desc    Get user by ID (protected - add auth middleware later)
 * @access  Private
 * @params  { userId }
 */
router.get("/user/:userId", authController.getUserById);

/**
 * @route   GET /api/auth/test-email
 * @desc    Test email configuration (development only)
 * @access  Private (should be restricted in production)
 */
router.get("/test-email", authController.testEmail);

// ==================== PASSWORD RESET ROUTES ====================

/**
 * @route   POST /api/auth/forgot-password
 * @desc    Request password reset (sends email with reset link)
 * @access  Public
 * @body    { email }
 * @returns { success, message }
 */
router.post("/forgot-password", authController.forgotPassword);

/**
 * @route   POST /api/auth/verify-password-reset-otp
 * @desc    Verify OTP for password reset and return reset token
 * @access  Public
 * @body    { email, otp }
 * @returns { success, message, reset_token, user }
 */
router.post("/verify-password-reset-otp", authController.verifyPasswordResetOtp);

/**
 * @route   POST /api/auth/verify-reset-token
 * @desc    Verify if reset token is valid
 * @access  Public
 * @body    { token }
 * @returns { success, message, user }
 */
router.post("/verify-reset-token", authController.verifyResetToken);

/**
 * @route   POST /api/auth/reset-password
 * @desc    Reset password with valid token
 * @access  Public
 * @body    { token, newPassword }
 * @returns { success, message }
 */
router.post("/reset-password", authController.resetPassword);

module.exports = router;
