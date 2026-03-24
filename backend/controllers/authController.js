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
          console.error("❌ Failed to send OTP email:", emailResult.error);
          return res.status(500).json({ 
            success: false, 
            message: "Failed to send OTP email. Please try again.",
            error: emailResult.error 
          });
        }
        
        return res.status(200).json({ 
          success: true, 
          message: "New OTP sent to your email!",
          email: email,
          username: username
        });
      } 
      
      // Case 2: The user is already verified
      if (user.email === email) {
        return res.status(400).json({ 
          success: false, 
          message: "Email already registered and verified. Please login." 
        });
      } else {
        return res.status(400).json({ 
          success: false, 
          message: "Username already taken. Please choose another." 
        });
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
        message: "Registration saved, but failed to send email. Please check your email settings.",
        error: emailResult.error 
      });
    }

    console.log("✅ Registration successful for:", email);
    res.status(201).json({
      success: true,
      message: "OTP sent to your email! Please check your inbox.",
      user: { email, username, role }
    });

  } catch (err) {
    console.error("❌ REGISTRATION CRASH:", err.message);
    console.error("Stack:", err.stack);
    res.status(500).json({ 
      success: false, 
      message: "Server error: " + err.message 
    });
  }
};

// ==================== VERIFY EMAIL/OTP ====================
exports.verifyEmail = async (req, res) => {
  const { email, otp } = req.body;
  
  console.log("🔐 Verifying OTP for email:", email, "OTP:", otp);
  
  if (!email || !otp) {
    console.log("❌ Missing email or OTP");
    return res.status(400).json({ 
      success: false, 
      message: "Email and OTP are required" 
    });
  }
  
  try {
    // First, check if user exists and is not verified
    const result = await pool.query(
      "SELECT * FROM users WHERE email = $1 AND email_verified = false",
      [email.toLowerCase()]
    );

    console.log("Found unverified users:", result.rows.length);

    if (result.rows.length === 0) {
      // Check if user is already verified
      const verifiedUser = await pool.query(
        "SELECT * FROM users WHERE email = $1 AND email_verified = true",
        [email.toLowerCase()]
      );
      
      if (verifiedUser.rows.length > 0) {
        return res.status(400).json({ 
          success: false, 
          message: "Email already verified. Please login." 
        });
      }
      
      return res.status(400).json({ 
        success: false, 
        message: "User not found. Please register first." 
      });
    }

    const user = result.rows[0];
    
    // Check if OTP matches and is not expired
    if (user.verification_token !== otp) {
      console.log("❌ OTP mismatch. Expected:", user.verification_token, "Got:", otp);
      return res.status(400).json({ 
        success: false, 
        message: "Invalid OTP. Please check and try again." 
      });
    }
    
    // Check if OTP is expired
    if (new Date() > new Date(user.verification_token_expires)) {
      console.log("❌ OTP expired for:", email);
      return res.status(400).json({ 
        success: false, 
        message: "OTP has expired. Please request a new one." 
      });
    }
    
    // Update user as verified
    await pool.query(
      "UPDATE users SET email_verified = true, verification_token = NULL, verification_token_expires = NULL WHERE user_id = $1",
      [user.user_id]
    );

    // Generate JWT token
    const token = jwt.sign(
      { id: user.user_id, role: user.role }, 
      process.env.JWT_SECRET || 'secret', 
      { expiresIn: "1d" }
    );

    console.log("✅ Email verified successfully for:", email);
    
    res.json({
      success: true,
      message: "Email verified successfully!",
      token,
      user: { 
        user_id: user.user_id, 
        username: user.username, 
        email: user.email, 
        role: user.role 
      }
    });
  } catch (err) {
    console.error("❌ Verification error:", err.message);
    console.error("Stack:", err.stack);
    res.status(500).json({ 
      success: false, 
      message: "Verification failed: " + err.message 
    });
  }
};

// ==================== LOGIN ====================
exports.login = async (req, res) => {
  const email = req.body.email.toLowerCase();
  const { password } = req.body;
  
  console.log("🔑 Login attempt for email:", email);
  
  if (!email || !password) {
    return res.status(400).json({ 
      success: false, 
      message: "Email and password are required" 
    });
  }
  
  try {
    const result = await pool.query("SELECT * FROM users WHERE email = $1", [email]);
    
    if (result.rows.length === 0) {
      console.log("❌ User not found:", email);
      return res.status(400).json({ 
        success: false, 
        message: "User not found. Please register." 
      });
    }

    const user = result.rows[0];
    
    if (!user.email_verified) {
      console.log("❌ Email not verified:", email);
      return res.status(403).json({ 
        success: false, 
        needs_verification: true, 
        email: user.email, 
        message: "Please verify your email first. Check your inbox for the OTP." 
      });
    }

    const valid = await bcrypt.compare(password, user.password_hash);
    
    if (!valid) {
      console.log("❌ Invalid password for:", email);
      return res.status(400).json({ 
        success: false, 
        message: "Invalid password. Please try again." 
      });
    }

    const token = jwt.sign(
      { id: user.user_id, role: user.role }, 
      process.env.JWT_SECRET || 'secret', 
      { expiresIn: "1d" }
    );
    
    console.log("✅ Login successful for:", email);
    
    res.json({ 
      success: true, 
      token, 
      role: user.role, 
      user_id: user.user_id, 
      username: user.username, 
      email: user.email 
    });
  } catch (err) {
    console.error("❌ Login error:", err.message);
    console.error("Stack:", err.stack);
    res.status(500).json({ 
      success: false, 
      message: "Login error: " + err.message 
    });
  }
};

// ==================== RESEND VERIFICATION ====================
exports.resendVerification = async (req, res) => {
  const { email } = req.body;
  
  console.log("📧 Resending verification email to:", email);
  
  if (!email) {
    return res.status(400).json({ 
      success: false, 
      message: "Email is required" 
    });
  }
  
  try {
    // Check if user exists and is not verified
    const userResult = await pool.query(
      "SELECT user_id, username, email_verified FROM users WHERE email = $1",
      [email.toLowerCase()]
    );
    
    if (userResult.rows.length === 0) {
      return res.status(400).json({ 
        success: false, 
        message: "User not found. Please register." 
      });
    }
    
    const user = userResult.rows[0];
    
    if (user.email_verified) {
      return res.status(400).json({ 
        success: false, 
        message: "Email already verified. Please login." 
      });
    }
    
    // Generate new OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const otpExpires = new Date(Date.now() + 24 * 60 * 60 * 1000);
    
    // Update user with new OTP
    await pool.query(
      "UPDATE users SET verification_token = $1, verification_token_expires = $2 WHERE email = $3",
      [otp, otpExpires, email.toLowerCase()]
    );
    
    // Send new OTP email
    const emailResult = await emailService.sendVerificationEmail(email, otp, user.username);
    
    if (!emailResult.success) {
      console.error("❌ Failed to send OTP email:", emailResult.error);
      return res.status(500).json({ 
        success: false, 
        message: "Failed to send OTP email. Please try again later." 
      });
    }
    
    console.log("✅ New OTP sent to:", email);
    res.json({ 
      success: true, 
      message: "New OTP sent to your email!",
      email_preview: email
    });
  } catch (err) {
    console.error("❌ Error resending OTP:", err.message);
    console.error("Stack:", err.stack);
    res.status(500).json({ 
      success: false, 
      message: "Error resending OTP: " + err.message 
    });
  }
};

// ==================== CHECK VERIFICATION STATUS ====================
exports.checkVerificationStatus = async (req, res) => {
  const { email } = req.query;
  
  console.log("🔍 Checking verification status for:", email);
  
  if (!email) {
    return res.status(400).json({ 
      success: false, 
      message: "Email is required" 
    });
  }
  
  try {
    const result = await pool.query(
      "SELECT email_verified FROM users WHERE email = $1", 
      [email.toLowerCase()]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false, 
        message: "User not found" 
      });
    }
    
    console.log("Verification status for", email, ":", result.rows[0].email_verified);
    res.json({ 
      success: true, 
      verified: result.rows[0].email_verified 
    });
  } catch (err) {
    console.error("❌ Error checking verification status:", err.message);
    res.status(500).json({ 
      success: false, 
      error: err.message 
    });
  }
};

// ==================== GET USER BY ID ====================
exports.getUserById = async (req, res) => {
  const { userId } = req.params;
  
  console.log("🔍 Fetching user by ID:", userId);
  
  try {
    const result = await pool.query(
      "SELECT user_id, username, email, role FROM users WHERE user_id = $1", 
      [userId]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false, 
        message: "User not found" 
      });
    }
    
    res.json({ 
      success: true, 
      user: result.rows[0] 
    });
  } catch (err) {
    console.error("❌ Error fetching user:", err.message);
    res.status(500).json({ 
      success: false, 
      error: err.message 
    });
  }
};

// ==================== TEST EMAIL CONFIGURATION ====================
exports.testEmail = async (req, res) => {
  console.log("🧪 Testing email configuration...");
  
  try {
    const result = await emailService.testEmailConfig();
    res.json(result);
  } catch (err) {
    console.error("❌ Email test error:", err.message);
    res.status(500).json({ 
      success: false, 
      error: err.message 
    });
  }
};