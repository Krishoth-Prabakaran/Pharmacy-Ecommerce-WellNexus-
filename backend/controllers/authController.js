// backend/controllers/authController.js
const pool = require("../config/db");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const emailService = require('../services/emailService');

// ==================== REGISTER FUNCTION ====================
exports.register = async (req, res) => {
  const { username, password, role } = req.body;
  const email = req.body.email.toLowerCase();

  console.log("📝 Registering:", email, "with username:", username);

  try {
    // Check if either email OR username already exists
    const userExists = await pool.query(
      "SELECT * FROM users WHERE email = $1 OR username = $2", 
      [email, username]
    );
    
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const otpExpires = new Date(Date.now() + 24 * 60 * 60 * 1000);

    if (userExists.rows.length > 0) {
      const user = userExists.rows[0];
      
      // Case 1: The user exists but is NOT verified (Safe to update and resend OTP)
      if (!user.email_verified) {
        console.log("🔄 Updating unverified user:", email);
        
        // Update both just in case they changed the username for the same email
        await pool.query(
          "UPDATE users SET verification_token = $1, verification_token_expires = $2, username = $3 WHERE email = $4",
          [otp, otpExpires, username, email]
        );
        
        const emailResult = await emailService.sendVerificationEmail(email, otp, username);
        if (!emailResult.success) {
          return res.status(500).json({ success: false, message: "Failed to send OTP email." });
        }
        
        return res.status(200).json({ success: true, message: "New OTP sent to your email!" });
      } 
      
      // Case 2: The user is already verified
      if (user.email === email) {
        return res.status(400).json({ success: false, message: "Email already registered and verified." });
      } else {
        return res.status(400).json({ success: false, message: "Username already taken." });
      }
    }

    // Normal Registration for a brand new user
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    await pool.query(
      `INSERT INTO users (username, email, password_hash, role, verification_token, verification_token_expires, email_verified) 
       VALUES ($1, $2, $3, $4, $5, $6, false)`,
      [username, email, hashedPassword, role, otp, otpExpires]
    );

    const emailResult = await emailService.sendVerificationEmail(email, otp, username);
    
    if (!emailResult.success) {
      console.error("📧 Email send failed:", emailResult.error);
      return res.status(500).json({ 
        success: false, 
        message: "Registration saved, but failed to send email. Check settings.",
        error: emailResult.error 
      });
    }

    res.status(201).json({
      success: true,
      message: "OTP sent to your email!",
      user: { email, username, role }
    });

  } catch (err) {
    console.error("❌ REGISTRATION CRASH:", err.message);
    res.status(500).json({ 
      success: false, 
      message: "Server error: " + err.message 
    });
  }
};

// ==================== VERIFY EMAIL/OTP ====================
exports.verifyEmail = async (req, res) => {
  const { email, otp } = req.body;
  try {
    const result = await pool.query(
      "SELECT * FROM users WHERE email = $1 AND verification_token = $2 AND email_verified = false",
      [email.toLowerCase(), otp]
    );

    if (result.rows.length === 0) {
      return res.status(400).json({ success: false, message: "Invalid or expired OTP" });
    }

    const user = result.rows[0];
    await pool.query(
      "UPDATE users SET email_verified = true, verification_token = NULL, verification_token_expires = NULL WHERE user_id = $1",
      [user.user_id]
    );

    const token = jwt.sign({ id: user.user_id, role: user.role }, process.env.JWT_SECRET || 'secret', { expiresIn: "1d" });

    res.json({
      success: true,
      message: "Email verified successfully!",
      token,
      user: { user_id: user.user_id, username: user.username, email: user.email, role: user.role }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: "Verification failed: " + err.message });
  }
};

// ==================== LOGIN ====================
exports.login = async (req, res) => {
  const email = req.body.email.toLowerCase();
  const { password } = req.body;
  try {
    const result = await pool.query("SELECT * FROM users WHERE email = $1", [email]);
    if (result.rows.length === 0) return res.status(400).json({ success: false, message: "User not found" });

    const user = result.rows[0];
    if (!user.email_verified) return res.status(403).json({ success: false, needs_verification: true, email: user.email, message: "Please verify your email first" });

    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) return res.status(400).json({ success: false, message: "Invalid password" });

    const token = jwt.sign({ id: user.user_id, role: user.role }, process.env.JWT_SECRET || 'secret', { expiresIn: "1d" });
    res.json({ success: true, token, role: user.role, user_id: user.user_id, username: user.username, email: user.email });
  } catch (err) {
    res.status(500).json({ success: false, message: "Login error: " + err.message });
  }
};

// ==================== RESEND VERIFICATION ====================
exports.resendVerification = async (req, res) => {
  const { email } = req.body;
  try {
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const otpExpires = new Date(Date.now() + 24 * 60 * 60 * 1000);
    
    const result = await pool.query(
      "UPDATE users SET verification_token = $1, verification_token_expires = $2 WHERE email = $3 AND email_verified = false RETURNING username",
      [otp, otpExpires, email.toLowerCase()]
    );
    
    if (result.rows.length === 0) return res.status(400).json({ success: false, message: "User not found or already verified" });
    
    await emailService.sendVerificationEmail(email, otp, result.rows[0].username);
    res.json({ success: true, message: "New OTP sent!" });
  } catch (err) {
    res.status(500).json({ success: false, message: "Error resending OTP", error: err.message });
  }
};

// ==================== CHECK VERIFICATION STATUS ====================
exports.checkVerificationStatus = async (req, res) => {
  const { email } = req.query;
  try {
    const result = await pool.query("SELECT email_verified FROM users WHERE email = $1", [email.toLowerCase()]);
    if (result.rows.length === 0) return res.status(404).json({ success: false, message: "User not found" });
    res.json({ success: true, verified: result.rows[0].email_verified });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
};

// ==================== GET USER BY ID ====================
exports.getUserById = async (req, res) => {
  const { userId } = req.params;
  try {
    const result = await pool.query("SELECT user_id, username, email, role FROM users WHERE user_id = $1", [userId]);
    if (result.rows.length === 0) return res.status(404).json({ success: false, message: "User not found" });
    res.json({ success: true, user: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
};

// ==================== TEST EMAIL CONFIGURATION ====================
exports.testEmail = async (req, res) => {
  try {
    const result = await emailService.testEmailConfig();
    res.json(result);
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
};
