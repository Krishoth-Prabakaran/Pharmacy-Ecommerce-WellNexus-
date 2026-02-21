const pool = require("../config/db");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");

// ==================== LOGIN FUNCTION ====================
exports.login = async (req, res) => {
  // Convert email to lowercase for case-insensitive handling
  const email = req.body.email.toLowerCase(); // FIX: Convert to lowercase
  const { password } = req.body;
  
  console.log("Login attempt for email:", email);

  try {
    // Check database connection
    const testQuery = await pool.query("SELECT * FROM users LIMIT 1");
    console.log("Database connection successful. Sample user:", testQuery.rows[0]?.email);

    // Case-insensitive email lookup
    const result = await pool.query(
      "SELECT * FROM users WHERE LOWER(email) = $1", // FIX: Use LOWER() for comparison
      [email]
    );

    if (result.rows.length === 0) {
      console.log("User not found:", email);
      return res.status(400).json({ message: "User not found" });
    }

    const user = result.rows[0];
    console.log("User found:", user.email, "Role:", user.role);
    
    if (!user.password_hash) {
      console.log("User has no password hash:", user.email);
      return res.status(500).json({ message: "User data corrupted" });
    }

    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) {
      console.log("Invalid password for:", email);
      return res.status(400).json({ message: "Invalid password" });
    }

    if (!user.is_active) {
      console.log("Account disabled:", email);
      return res.status(403).json({ message: "Account disabled" });
    }

    const token = jwt.sign(
      { id: user.user_id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: "1d" }
    );

    console.log("Login successful for:", email);
    res.json({
      message: "Login successful",
      token,
      role: user.role,
      user_id: user.user_id,
      username: user.username
    });
  } catch (err) {
    console.log("ERROR DETAILS:");
    console.log("Message:", err.message);
    console.log("Stack:", err.stack);
    res.status(500).json({ 
      message: "Server error", 
      error: err.message
    });
  }
};

// ==================== REGISTER FUNCTION ====================
exports.register = async (req, res) => {
  const { username, password, role } = req.body;
  // Convert email to lowercase for case-insensitive handling
  const email = req.body.email.toLowerCase(); // FIX: Convert to lowercase

  console.log("Registration attempt for email:", email);

  // Basic validation
  if (!username || !email || !password || !role) {
    console.log("Missing fields:", { username, email, password, role });
    return res.status(400).json({ 
      message: "Please provide username, email, password and role" 
    });
  }

  // Validate role
  const allowedRoles = ['doctor', 'patient', 'pharmacist', 'admin'];
  if (!allowedRoles.includes(role)) {
    console.log("Invalid role:", role);
    return res.status(400).json({ 
      message: "Role must be doctor, patient, pharmacist, or admin" 
    });
  }

  // Validate email format
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return res.status(400).json({ 
      message: "Please provide a valid email address" 
    });
  }

  // Validate password strength
  if (password.length < 6) {
    return res.status(400).json({ 
      message: "Password must be at least 6 characters long" 
    });
  }

  try {
    // Check if user already exists (case-insensitive email check)
    const userExists = await pool.query(
      "SELECT * FROM users WHERE LOWER(email) = $1 OR username = $2", // FIX: Case-insensitive email check
      [email, username]
    );

    if (userExists.rows.length > 0) {
      const existingUser = userExists.rows[0];
      // Case-insensitive comparison for email
      if (existingUser.email.toLowerCase() === email) {
        console.log("Email already registered:", email);
        return res.status(400).json({ message: "Email already registered" });
      }
      if (existingUser.username === username) {
        console.log("Username already taken:", username);
        return res.status(400).json({ message: "Username already taken" });
      }
    }

    // Hash the password
    console.log("Hashing password for:", email);
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Insert new user (store email in lowercase)
    console.log("Inserting new user into database:", email);
    const newUser = await pool.query(
      `INSERT INTO users (username, email, password_hash, role, is_active) 
       VALUES ($1, $2, $3, $4, true) 
       RETURNING user_id, username, email, role, join_date`,
      [username, email, hashedPassword, role] // Store email as lowercase
    );

    // Generate JWT token
    const token = jwt.sign(
      { 
        id: newUser.rows[0].user_id, 
        role: newUser.rows[0].role 
      },
      process.env.JWT_SECRET,
      { expiresIn: "1d" }
    );

    console.log("Registration successful for:", email);
    console.log("New user ID:", newUser.rows[0].user_id);

    res.status(201).json({
      message: "Registration successful",
      token,
      user: {
        user_id: newUser.rows[0].user_id,
        username: newUser.rows[0].username,
        email: newUser.rows[0].email,
        role: newUser.rows[0].role,
        join_date: newUser.rows[0].join_date
      }
    });

  } catch (err) {
    console.error("REGISTRATION ERROR:", err.message);
    
    if (err.code === '23505') {
      return res.status(400).json({ 
        message: "Duplicate entry. User may already exist." 
      });
    }
    
    res.status(500).json({ 
      message: "Server error during registration",
      error: err.message 
    });
  }
};