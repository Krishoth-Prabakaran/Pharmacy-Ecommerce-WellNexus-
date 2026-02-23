const pool = require("../config/db");

// ==================== SAVE PATIENT DETAILS ====================
exports.savePatientDetails = async (req, res) => {
  const { email, first_name, last_name, phone, date_of_birth, gender } = req.body;

  console.log("Saving patient details for email:", email);

  // Basic validation
  if (!email || !first_name || !last_name || !phone) {
    console.log("Missing required fields");
    return res.status(400).json({ 
      message: "Please provide email, first_name, last_name, and phone" 
    });
  }

  try {
    // First, check if the user exists in users table
    const userResult = await pool.query(
      "SELECT user_id, username FROM users WHERE email = $1",
      [email.toLowerCase()]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({ 
        message: "User not found. Please register first." 
      });
    }

    const userId = userResult.rows[0].user_id;
    const username = userResult.rows[0].username;

    // Check if patient details already exist for this email
    const existingPatient = await pool.query(
      "SELECT * FROM patients WHERE email = $1",
      [email.toLowerCase()]
    );

    if (existingPatient.rows.length > 0) {
      // Update existing patient details
      const result = await pool.query(
        `UPDATE patients 
         SET first_name = $1, last_name = $2, phone = $3, 
             date_of_birth = $4, gender = $5
         WHERE email = $6
         RETURNING patient_id, first_name, last_name, phone, email, date_of_birth, gender`,
        [first_name, last_name, phone, date_of_birth, gender, email.toLowerCase()]
      );

      console.log("Patient details updated for email:", email);
      return res.status(200).json({
        message: "Patient details updated successfully",
        patient: result.rows[0],
        user_id: userId,
        username: username
      });
    } else {
      // Insert new patient details
      const result = await pool.query(
        `INSERT INTO patients (first_name, last_name, phone, email, date_of_birth, gender)
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING patient_id, first_name, last_name, phone, email, date_of_birth, gender`,
        [first_name, last_name, phone, email.toLowerCase(), date_of_birth, gender]
      );

      console.log("New patient details saved for email:", email);
      return res.status(201).json({
        message: "Patient details saved successfully",
        patient: result.rows[0],
        user_id: userId,
        username: username
      });
    }
  } catch (err) {
    console.error("ERROR SAVING PATIENT DETAILS:");
    console.error("Message:", err.message);
    console.error("Stack:", err.stack);
    
    // Check for duplicate phone violation
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
exports.getPatientDetails = async (req, res) => {
  const { email } = req.params;

  console.log("Fetching patient details for email:", email);

  try {
    const result = await pool.query(
      "SELECT patient_id, first_name, last_name, phone, email, date_of_birth, gender FROM patients WHERE email = $1",
      [email.toLowerCase()]
    );

    if (result.rows.length === 0) {
      console.log("No patient details found for email:", email);
      return res.status(404).json({ 
        message: "Patient details not found" 
      });
    }

    // Also get user info from users table
    const userResult = await pool.query(
      "SELECT user_id, username FROM users WHERE email = $1",
      [email.toLowerCase()]
    );

    console.log("Patient details found for email:", email);
    res.status(200).json({
      message: "Patient details retrieved successfully",
      patient: result.rows[0],
      user: userResult.rows[0] || null
    });
  } catch (err) {
    console.error("ERROR GETTING PATIENT DETAILS:");
    console.error("Message:", err.message);
    res.status(500).json({ 
      message: "Server error while fetching patient details",
      error: err.message 
    });
  }
};

// ==================== GET PATIENT BY PHONE ====================
exports.getPatientByPhone = async (req, res) => {
  const { phone } = req.params;

  console.log("Fetching patient details for phone:", phone);

  try {
    const result = await pool.query(
      "SELECT patient_id, first_name, last_name, phone, email, date_of_birth, gender FROM patients WHERE phone = $1",
      [phone]
    );

    if (result.rows.length === 0) {
      console.log("No patient found for phone:", phone);
      return res.status(404).json({ 
        message: "Patient not found" 
      });
    }

    res.status(200).json({
      message: "Patient retrieved successfully",
      patient: result.rows[0]
    });
  } catch (err) {
    console.error("ERROR GETTING PATIENT BY PHONE:");
    console.error("Message:", err.message);
    res.status(500).json({ 
      message: "Server error while fetching patient",
      error: err.message 
    });
  }
};

// ==================== UPDATE PATIENT DETAILS ====================
exports.updatePatientDetails = async (req, res) => {
  const { email } = req.params;
  const { first_name, last_name, phone, date_of_birth, gender } = req.body;

  console.log("Updating patient details for email:", email);

  try {
    // Check if patient exists
    const existingPatient = await pool.query(
      "SELECT * FROM patients WHERE email = $1",
      [email.toLowerCase()]
    );

    if (existingPatient.rows.length === 0) {
      console.log("Patient details not found for email:", email);
      return res.status(404).json({ 
        message: "Patient details not found" 
      });
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

    // Add email as the last parameter
    values.push(email.toLowerCase());

    const query = `
      UPDATE patients 
      SET ${updates.join(', ')}
      WHERE email = $${paramCounter}
      RETURNING patient_id, first_name, last_name, phone, email, date_of_birth, gender
    `;

    const result = await pool.query(query, values);

    console.log("Patient details updated for email:", email);
    res.status(200).json({
      message: "Patient details updated successfully",
      patient: result.rows[0]
    });
  } catch (err) {
    console.error("ERROR UPDATING PATIENT DETAILS:");
    console.error("Message:", err.message);
    
    if (err.code === '23505' && err.constraint === 'patients_phone_key') {
      return res.status(400).json({ 
        message: "Phone number already registered" 
      });
    }
    
    res.status(500).json({ 
      message: "Server error while updating patient details",
      error: err.message 
    });
  }
};

// ==================== CHECK IF PATIENT HAS DETAILS ====================
exports.checkPatientDetails = async (req, res) => {
  const { email } = req.params;

  console.log("Checking if patient has details for email:", email);

  try {
    const result = await pool.query(
      "SELECT EXISTS(SELECT 1 FROM patients WHERE email = $1) as has_details",
      [email.toLowerCase()]
    );

    res.status(200).json({
      has_details: result.rows[0].has_details
    });
  } catch (err) {
    console.error("ERROR CHECKING PATIENT DETAILS:");
    console.error("Message:", err.message);
    res.status(500).json({ 
      message: "Server error while checking patient details",
      error: err.message 
    });
  }
};