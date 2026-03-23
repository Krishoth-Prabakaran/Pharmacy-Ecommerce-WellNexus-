// backend/routes/authRoutes.js
const express = require("express");
const router = express.Router();
const authController = require("../controllers/authController");

/**
 * Authentication Routes
 * Base path: /api/auth
 */

// ==================== PUBLIC ROUTES ====================

/**
 * @route   POST /api/auth/login
 * @desc    Authenticate user and return JWT token
 * @access  Public
 * @body    { email, password }
 * @returns { token, role, user_id, username, email, email_verified }
 */
router.post("/login", authController.login);

/**
 * @route   POST /api/auth/register
 * @desc    Register new user and send verification email
 * @access  Public
 * @body    { username, email, password, role }
 * @returns { success, message, user, email_sent }
 */
router.post("/register", authController.register);

 

/**

 * @route   POST /api/auth/verify-email

 * @desc    Verify user's email using token

 * @access  Public

 * @query   { token }

 * @returns { success, message, token, user } or redirects to frontend

 */

router.post("/verify-email", authController.verifyEmail);

 

 

/**
 * @route   POST /api/auth/resend-verification
 * @desc    Resend verification email
 * @access  Public
 * @body    { email }
 * @returns { success, message, email_sent }
 */
router.post("/resend-verification", authController.resendVerification);

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

module.exports = router;