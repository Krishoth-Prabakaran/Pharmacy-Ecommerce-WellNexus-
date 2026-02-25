// controllers/patientController.js
const pool = require("../config/db");

// ==================== SAVE PATIENT DETAILS ====================
// Now expects user_id in request body to directly link to users table.
// For backward compatibility, also accepts email (will fetch user_id).
exports.savePatientDetails = async (req, res) => {
  // Extract fields from request body
  const { 
    user_id,           // Primary linking field (new)
    email,             // Fallback if user_id not provided
    first_name, 
    last_name, 
    phone, 
    date_of_birth, 
    gender 
  } = req.body;

  console.log("📝 Saving patient details for user_id:", user_id, "email:", email);

  // Basic validation
  if (!first_name || !last_name || !phone) {
    console.log("❌ Missing required fields");
    return res.status(400).json({ 
      message: "Please provide first_name, last_name, and phone" 
    });
  }

  // Must have either user_id or email to link to users table
  if (!user_id && !email) {
    return res.status(400).json({ 
      message: "Either user_id or email is required to link patient to user account" 
    });
  }

  try {
    let userId = user_id;
    let userEmail = email;

    // If only email provided, fetch user_id from users table
    if (!userId && email) {
      const userResult = await pool.query(
        "SELECT user_id FROM users WHERE email = $1",
        [email.toLowerCase()]
      );
      if (userResult.rows.length === 0) {
        return res.status(404).json({ 
          message: "User not found with provided email. Please register first." 
        });
      }
      userId = userResult.rows[0].user_id;
      userEmail = email.toLowerCase(); // ensure lowercase
    }

    // If we have userId but no email, fetch email from users table for insertion
    if (userId && !userEmail) {
      const userResult = await pool.query(
        "SELECT email FROM users WHERE user_id = $1",
        [userId]
      );
      if (userResult.rows.length === 0) {
        return res.status(404).json({ 
          message: "User not found with provided user_id" 
        });
      }
      userEmail = userResult.rows[0].email;
    }

    // Check if patient record already exists for this user_id
    const existingPatient = await pool.query(
      "SELECT patient_id FROM patients WHERE user_id = $1",
      [userId]
    );

    if (existingPatient.rows.length > 0) {
      // Update existing record
      const result = await pool.query(
        `UPDATE patients 
         SET first_name = $1, last_name = $2, phone = $3, 
             date_of_birth = $4, gender = $5
         WHERE user_id = $6
         RETURNING patient_id, first_name, last_name, phone, email, date_of_birth, gender`,
        [first_name, last_name, phone, date_of_birth, gender, userId]
      );

      console.log("✅ Patient details updated for user_id:", userId);
      return res.status(200).json({
        message: "Patient details updated successfully",
        patient: result.rows[0]
      });
    } else {
      // Insert new patient record
      const result = await pool.query(
        `INSERT INTO patients 
           (user_id, first_name, last_name, phone, email, date_of_birth, gender)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         RETURNING patient_id, first_name, last_name, phone, email, date_of_birth, gender`,
        [userId, first_name, last_name, phone, userEmail, date_of_birth, gender]
      );

      console.log("✅ New patient details saved for user_id:", userId);
      return res.status(201).json({
        message: "Patient details saved successfully",
        patient: result.rows[0]
      });
    }
  } catch (err) {
    console.error("❌ ERROR SAVING PATIENT DETAILS:");
    console.error("Message:", err.message);
    console.error("Stack:", err.stack);

    // Handle duplicate phone violation
    if (err.code === '23505' && err.constraint === 'patients_phone_key') {
      return res.status(400).json({ 
        message: "Phone number already registered" 
      });
    }

    res.status(500).json({ 
      message: "Server error while saving patient details",
      error: err.message 
    });
  }
};

// ==================== GET PATIENT DETAILS ====================
// Can fetch by email or user_id (via query param)
exports.getPatientDetails = async (req, res) => {
  const { email, user_id } = req.query; // Allow both

  console.log("🔍 Fetching patient details for email:", email, "user_id:", user_id);

  try {
    let query;
    let params;

    if (user_id) {
      query = "SELECT * FROM patients WHERE user_id = $1";
      params = [user_id];
    } else if (email) {
      query = "SELECT * FROM patients WHERE email = $1";
      params = [email.toLowerCase()];
    } else {
      return res.status(400).json({ message: "Provide email or user_id" });
    }

    const result = await pool.query(query, params);

    if (result.rows.length === 0) {
      console.log("❌ No patient details found");
      return res.status(404).json({ message: "Patient details not found" });
    }

    console.log("✅ Patient details found");
    res.status(200).json({
      message: "Patient details retrieved successfully",
      patient: result.rows[0]
    });
  } catch (err) {
    console.error("❌ ERROR GETTING PATIENT DETAILS:", err.message);
    res.status(500).json({ 
      message: "Server error while fetching patient details",
      error: err.message 
    });
  }
};

// ==================== GET PATIENT BY PHONE ====================
exports.getPatientByPhone = async (req, res) => {
  const { phone } = req.params;

  console.log("🔍 Fetching patient details for phone:", phone);

  try {
    const result = await pool.query(
      "SELECT patient_id, first_name, last_name, phone, email, date_of_birth, gender FROM patients WHERE phone = $1",
      [phone]
    );

    if (result.rows.length === 0) {
      console.log("❌ No patient found for phone:", phone);
      return res.status(404).json({ message: "Patient not found" });
    }

    res.status(200).json({
      message: "Patient retrieved successfully",
      patient: result.rows[0]
    });
  } catch (err) {
    console.error("❌ ERROR GETTING PATIENT BY PHONE:", err.message);
    res.status(500).json({ 
      message: "Server error while fetching patient",
      error: err.message 
    });
  }
};

// ==================== UPDATE PATIENT DETAILS ====================
exports.updatePatientDetails = async (req, res) => {
  const { user_id } = req.params; // Use user_id in URL
  const { first_name, last_name, phone, date_of_birth, gender } = req.body;

  console.log("✏️ Updating patient details for user_id:", user_id);

  try {
    // Check if patient exists
    const existingPatient = await pool.query(
      "SELECT * FROM patients WHERE user_id = $1",
      [user_id]
    );

    if (existingPatient.rows.length === 0) {
      console.log("❌ Patient details not found for user_id:", user_id);
      return res.status(404).json({ message: "Patient details not found" });
    }

    // Build dynamic update query
    const updates = [];
    const values = [];
    let paramCounter = 1;

    if (first_name) {
      updates.push(`first_name = $${paramCounter++}`);
      values.push(first_name);
    }
    if (last_name) {
      updates.push(`last_name = $${paramCounter++}`);
      values.push(last_name);
    }
    if (phone) {
      updates.push(`phone = $${paramCounter++}`);
      values.push(phone);
    }
    if (date_of_birth) {
      updates.push(`date_of_birth = $${paramCounter++}`);
      values.push(date_of_birth);
    }
    if (gender) {
      updates.push(`gender = $${paramCounter++}`);
      values.push(gender);
    }

    if (updates.length === 0) {
      return res.status(400).json({ message: "No fields to update" });
    }

    // Add user_id as last parameter
    values.push(user_id);

    const query = `
      UPDATE patients 
      SET ${updates.join(', ')}
      WHERE user_id = $${paramCounter}
      RETURNING patient_id, first_name, last_name, phone, email, date_of_birth, gender
    `;

    const result = await pool.query(query, values);

    console.log("✅ Patient details updated for user_id:", user_id);
    res.status(200).json({
      message: "Patient details updated successfully",
      patient: result.rows[0]
    });
  } catch (err) {
    console.error("❌ ERROR UPDATING PATIENT DETAILS:", err.message);

    if (err.code === '23505' && err.constraint === 'patients_phone_key') {
      return res.status(400).json({ message: "Phone number already registered" });
    }

    res.status(500).json({ 
      message: "Server error while updating patient details",
      error: err.message 
    });
  }
};

// ==================== CHECK IF PATIENT HAS DETAILS ====================
exports.checkPatientDetails = async (req, res) => {
  const { user_id } = req.params; // Now uses user_id

  console.log("🔍 Checking if patient has details for user_id:", user_id);

  try {
    const result = await pool.query(
      "SELECT EXISTS(SELECT 1 FROM patients WHERE user_id = $1) as has_details",
      [user_id]
    );

    res.status(200).json({
      has_details: result.rows[0].has_details
    });
  } catch (err) {
    console.error("❌ ERROR CHECKING PATIENT DETAILS:", err.message);
    res.status(500).json({ 
      message: "Server error while checking patient details",
      error: err.message 
    });
  }
};