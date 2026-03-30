// backend/controllers/patientController.js
const pool = require("../config/db");

// ==================== SAVE PATIENT DETAILS ====================
exports.savePatientDetails = async (req, res) => {
  const { 
    user_id,           
    email,             
    first_name, 
    last_name, 
    phone, 
    date_of_birth, 
    gender 
  } = req.body;

  console.log("📝 Saving patient details for user_id:", user_id, "email:", email);

  if (!first_name || !last_name || !phone) {
    return res.status(400).json({ 
      message: "Please provide first_name, last_name, and phone" 
    });
  }

  if (date_of_birth) {
    const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
    if (!dateRegex.test(date_of_birth)) {
      return res.status(400).json({ 
        message: "Date of birth must be in YYYY-MM-DD format" 
      });
    }
  }

  if (!user_id && !email) {
    return res.status(400).json({ 
      message: "Either user_id or email is required" 
    });
  }

  try {
    let userId = user_id;
    let userEmail = email;

    if (!userId && email) {
      const userResult = await pool.query(
        "SELECT user_id FROM users WHERE email = $1",
        [email.toLowerCase()]
      );
      if (userResult.rows.length === 0) {
        return res.status(404).json({ 
          message: "User not found" 
        });
      }
      userId = userResult.rows[0].user_id;
      userEmail = email.toLowerCase();
    }

    if (userId && !userEmail) {
      const userResult = await pool.query(
        "SELECT email FROM users WHERE user_id = $1",
        [userId]
      );
      if (userResult.rows.length === 0) {
        return res.status(404).json({ 
          message: "User not found" 
        });
      }
      userEmail = userResult.rows[0].email;
    }

    const existingPatient = await pool.query(
      "SELECT patient_id FROM patients WHERE user_id = $1",
      [userId]
    );

    if (existingPatient.rows.length > 0) {
      const result = await pool.query(
        `UPDATE patients 
         SET first_name = $1, last_name = $2, phone = $3, 
             date_of_birth = $4, gender = $5
         WHERE user_id = $6
         RETURNING patient_id, first_name, last_name, phone, email, date_of_birth, gender`,
        [first_name, last_name, phone, date_of_birth, gender, userId]
      );

      return res.status(200).json({
        message: "Patient details updated successfully",
        patient: result.rows[0]
      });
    } else {
      const result = await pool.query(
        `INSERT INTO patients 
           (user_id, first_name, last_name, phone, email, date_of_birth, gender)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         RETURNING patient_id, first_name, last_name, phone, email, date_of_birth, gender`,
        [userId, first_name, last_name, phone, userEmail, date_of_birth, gender]
      );

      return res.status(201).json({
        message: "Patient details saved successfully",
        patient: result.rows[0]
      });
    }
  } catch (err) {
    console.error("❌ ERROR SAVING PATIENT DETAILS:", err.message);

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

// ==================== GET PATIENT DASHBOARD ====================
exports.getPatientDashboard = async (req, res) => {
  const { userId } = req.params;
  
  console.log("📊 Fetching dashboard data for user_id:", userId);

  try {
    const userResult = await pool.query(
      "SELECT user_id, username, email, role, join_date FROM users WHERE user_id = $1",
      [userId]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({ 
        success: false, 
        message: "User not found" 
      });
    }

    const user = userResult.rows[0];

    const patientResult = await pool.query(
      `SELECT patient_id, first_name, last_name, phone, 
              date_of_birth, gender
       FROM patients 
       WHERE user_id = $1`,
      [userId]
    );

    const patientDetails = patientResult.rows[0] || null;

    let age = null;
    if (patientDetails && patientDetails.date_of_birth) {
      const birthDate = new Date(patientDetails.date_of_birth);
      const today = new Date();
      age = today.getFullYear() - birthDate.getFullYear();
      const monthDiff = today.getMonth() - birthDate.getMonth();
      if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthDate.getDate())) {
        age--;
      }
    }

    const dashboardData = {
      success: true,
      user: {
        id: user.user_id,
        username: user.username,
        email: user.email,
        role: user.role,
        member_since: user.join_date
      },
      profile: patientDetails ? {
        full_name: `${patientDetails.first_name} ${patientDetails.last_name}`,
        first_name: patientDetails.first_name,
        last_name: patientDetails.last_name,
        phone: patientDetails.phone,
        date_of_birth: patientDetails.date_of_birth,
        age: age,
        gender: patientDetails.gender ? 
          patientDetails.gender.charAt(0).toUpperCase() + patientDetails.gender.slice(1) : null,
        patient_id: patientDetails.patient_id
      } : null,
      health_metrics: [],
      recent_appointments: [],
      recent_prescriptions: [],
      medical_records: [],
      stats: {
        total_appointments: 0,
        total_prescriptions: 0,
        has_complete_profile: patientDetails !== null
      }
    };

    console.log("✅ Dashboard data fetched successfully");
    res.status(200).json(dashboardData);

  } catch (err) {
    console.error("❌ ERROR FETCHING DASHBOARD DATA:", err.message);
    res.status(500).json({ 
      success: false, 
      message: "Server error while fetching dashboard data",
      error: err.message 
    });
  }
};

// ==================== GET PATIENT DETAILS ====================
exports.getPatientDetails = async (req, res) => {
  const { email, user_id } = req.query;

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
      return res.status(404).json({ message: "Patient details not found" });
    }

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
  const { user_id } = req.params;
  const { first_name, last_name, phone, date_of_birth, gender } = req.body;

  console.log("✏️ Updating patient details for user_id:", user_id);

  try {
    const existingPatient = await pool.query(
      "SELECT * FROM patients WHERE user_id = $1",
      [user_id]
    );

    if (existingPatient.rows.length === 0) {
      return res.status(404).json({ message: "Patient details not found" });
    }

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

    values.push(user_id);

    const query = `
      UPDATE patients 
      SET ${updates.join(', ')}
      WHERE user_id = $${paramCounter}
      RETURNING patient_id, first_name, last_name, phone, email, date_of_birth, gender
    `;

    const result = await pool.query(query, values);

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

// ==================== UPDATE PATIENT PROFILE ====================
exports.updatePatientProfile = async (req, res) => {
  const { userId } = req.params;
  const { first_name, last_name, phone, date_of_birth, gender } = req.body;

  console.log("✏️ Updating patient profile for user_id:", userId);

  try {
    const existingPatient = await pool.query(
      "SELECT patient_id FROM patients WHERE user_id = $1",
      [userId]
    );

    if (existingPatient.rows.length === 0) {
      return res.status(404).json({ 
        success: false,
        message: "Patient profile not found" 
      });
    }

    const updates = [];
    const values = [];
    let paramCounter = 1;

    if (first_name !== undefined) {
      updates.push(`first_name = $${paramCounter++}`);
      values.push(first_name);
    }
    if (last_name !== undefined) {
      updates.push(`last_name = $${paramCounter++}`);
      values.push(last_name);
    }
    if (phone !== undefined) {
      updates.push(`phone = $${paramCounter++}`);
      values.push(phone);
    }
    if (date_of_birth !== undefined) {
      updates.push(`date_of_birth = $${paramCounter++}`);
      values.push(date_of_birth);
    }
    if (gender !== undefined) {
      updates.push(`gender = $${paramCounter++}`);
      values.push(gender);
    }

    if (updates.length === 0) {
      return res.status(400).json({ 
        success: false,
        message: "No fields to update" 
      });
    }

    values.push(userId);

    const query = `
      UPDATE patients 
      SET ${updates.join(', ')}
      WHERE user_id = $${paramCounter}
      RETURNING patient_id, first_name, last_name, phone, email, date_of_birth, gender
    `;

    const result = await pool.query(query, values);

    res.status(200).json({
      success: true,
      message: "Profile updated successfully",
      profile: result.rows[0]
    });

  } catch (err) {
    console.error("❌ ERROR UPDATING PATIENT PROFILE:", err.message);
    
    if (err.code === '23505' && err.constraint === 'patients_phone_key') {
      return res.status(400).json({ 
        success: false,
        message: "Phone number already registered" 
      });
    }
    
    res.status(500).json({ 
      success: false,
      message: "Server error while updating profile",
      error: err.message 
    });
  }
};

// ==================== CHECK IF PATIENT HAS DETAILS ====================
exports.checkPatientDetails = async (req, res) => {
  const { userId } = req.params;

  console.log("🔍 Checking if patient has details for user_id:", userId);

  try {
    const result = await pool.query(
      "SELECT EXISTS(SELECT 1 FROM patients WHERE user_id = $1) as has_details",
      [userId]
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