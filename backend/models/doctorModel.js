// =====================================================
// DOCTOR MODEL
// =====================================================
// Handles all database operations related to doctors
// Uses transactions to ensure data consistency between
// users table and doctors table
// =====================================================

const pool = require("../config/db");

const DoctorModel = {
  /**
   * Create a new doctor with transaction
   * @param {Object} doctorData - Professional details (first_name, last_name, specialization, etc.)
   * @param {Object} userData - User account details (username, email, password_hash)
   * @returns {Object} Created doctor with user information
   */
  async create(doctorData, userData) {
    const client = await pool.connect();
    
    try {
      await client.query('BEGIN');
      
      // Step 1: Insert into users table
      const userResult = await client.query(
        `INSERT INTO users (username, email, password_hash, role, created_at)
         VALUES ($1, $2, $3, $4, NOW())
         RETURNING user_id, username, email, role`,
        [userData.username, userData.email.toLowerCase(), userData.password_hash, 'doctor']
      );
      
      const userId = userResult.rows[0].user_id;
      
      // Step 2: Insert into doctors table
      const doctorResult = await client.query(
        `INSERT INTO doctors (
          first_name, last_name, specialization, license_number,
          phone, consultation_fee, experience_years, available_from,
          available_to, education, clinic_address, user_id
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
        RETURNING 
          doctor_id, first_name, last_name, specialization,
          license_number, phone, consultation_fee, experience_years,
          available_from, available_to, education, clinic_address`,
        [
          doctorData.first_name,
          doctorData.last_name,
          doctorData.specialization,
          doctorData.license_number,
          doctorData.phone,
          doctorData.consultation_fee || null,
          doctorData.experience_years || null,
          doctorData.available_from || null,
          doctorData.available_to || null,
          doctorData.education || null,
          doctorData.clinic_address || null,
          userId
        ]
      );
      
      await client.query('COMMIT');
      
      // Combine and return all data
      return {
        ...doctorResult.rows[0],
        email: userResult.rows[0].email,
        username: userResult.rows[0].username,
        role: userResult.rows[0].role
      };
      
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  },

  /**
   * Find doctor by email
   * @param {string} email - Doctor's email
   * @returns {Object} Doctor details with user information
   */
  async findByEmail(email) {
    const result = await pool.query(
      `SELECT 
        d.doctor_id, d.first_name, d.last_name, d.specialization,
        d.license_number, d.phone, d.consultation_fee, d.experience_years,
        d.available_from, d.available_to, d.education, d.clinic_address,
        u.user_id, u.email, u.username, u.role
       FROM doctors d
       JOIN users u ON d.user_id = u.user_id
       WHERE u.email = $1`,
      [email.toLowerCase()]
    );
    return result.rows[0];
  },

  /**
   * Find doctor by ID
   * @param {number} doctorId - Doctor's ID
   * @returns {Object} Doctor details with user information
   */
  async findById(doctorId) {
    const result = await pool.query(
      `SELECT 
        d.doctor_id, d.first_name, d.last_name, d.specialization,
        d.license_number, d.phone, d.consultation_fee, d.experience_years,
        d.available_from, d.available_to, d.education, d.clinic_address,
        u.user_id, u.email, u.username
       FROM doctors d
       JOIN users u ON d.user_id = u.user_id
       WHERE d.doctor_id = $1`,
      [doctorId]
    );
    return result.rows[0];
  },

  /**
   * Find doctor by license number
   * @param {string} licenseNumber - Medical license number
   * @returns {Object} Basic doctor info for uniqueness check
   */
  async findByLicense(licenseNumber) {
    const result = await pool.query(
      'SELECT doctor_id FROM doctors WHERE license_number = $1',
      [licenseNumber]
    );
    return result.rows[0];
  },

  /**
   * Get all doctors
   * @returns {Array} List of all doctors with user information
   */
  async findAll() {
    const result = await pool.query(
      `SELECT 
        d.doctor_id, d.first_name, d.last_name, d.specialization,
        d.license_number, d.phone, d.consultation_fee, d.experience_years,
        d.available_from, d.available_to, d.education, d.clinic_address,
        u.email, u.username
       FROM doctors d
       JOIN users u ON d.user_id = u.user_id
       ORDER BY d.last_name, d.first_name`
    );
    return result.rows;
  },

  /**
   * Update doctor information
   * @param {number} doctorId - Doctor's ID
   * @param {Object} updateData - Fields to update
   * @returns {Object} Updated doctor information
   */
  async update(doctorId, updateData) {
    const updates = [];
    const values = [];
    let paramCounter = 1;

    const allowedFields = [
      'first_name', 'last_name', 'specialization', 'license_number',
      'phone', 'consultation_fee', 'experience_years', 'available_from',
      'available_to', 'education', 'clinic_address'
    ];

    // Build dynamic update query
    allowedFields.forEach(field => {
      if (updateData[field] !== undefined) {
        updates.push(`${field} = $${paramCounter++}`);
        values.push(updateData[field]);
      }
    });

    if (updates.length === 0) {
      throw new Error('No fields to update');
    }

    values.push(doctorId);

    const query = `
      UPDATE doctors 
      SET ${updates.join(', ')}
      WHERE doctor_id = $${paramCounter}
      RETURNING doctor_id, first_name, last_name, specialization,
                license_number, phone, consultation_fee, experience_years,
                available_from, available_to, education, clinic_address
    `;

    const result = await pool.query(query, values);
    return result.rows[0];
  },

  /**
   * Delete doctor (cascades to users table)
   * @param {number} doctorId - Doctor's ID
   * @returns {boolean} True if successful
   */
  async delete(doctorId) {
    const client = await pool.connect();
    
    try {
      await client.query('BEGIN');
      
      // Get user_id first
      const doctorResult = await client.query(
        'SELECT user_id FROM doctors WHERE doctor_id = $1',
        [doctorId]
      );
      
      if (doctorResult.rows.length === 0) {
        throw new Error('Doctor not found');
      }
      
      const userId = doctorResult.rows[0].user_id;
      
      // Delete from doctors table
      await client.query(
        'DELETE FROM doctors WHERE doctor_id = $1',
        [doctorId]
      );
      
      // Delete from users table
      await client.query(
        'DELETE FROM users WHERE user_id = $1',
        [userId]
      );
      
      await client.query('COMMIT');
      return true;
      
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  },

  /**
   * Find doctors by specialization (partial match)
   * @param {string} specialization - Specialization to search for
   * @returns {Array} List of matching doctors
   */
  async findBySpecialization(specialization) {
    const result = await pool.query(
      `SELECT 
        d.doctor_id, d.first_name, d.last_name, d.specialization,
        d.license_number, d.phone, d.consultation_fee, d.experience_years,
        d.available_from, d.available_to, d.education, d.clinic_address,
        u.email, u.username
       FROM doctors d
       JOIN users u ON d.user_id = u.user_id
       WHERE d.specialization ILIKE $1
       ORDER BY d.last_name, d.first_name`,
      [`%${specialization}%`]
    );
    return result.rows;
  },

  // ================ UNIQUENESS CHECK METHODS ================

  /**
   * Check if email already exists
   * @param {string} email - Email to check
   * @returns {boolean} True if email exists
   */
  async emailExists(email) {
    const result = await pool.query(
      'SELECT user_id FROM users WHERE email = $1',
      [email.toLowerCase()]
    );
    return result.rows.length > 0;
  },

  /**
   * Check if username already exists
   * @param {string} username - Username to check
   * @returns {boolean} True if username exists
   */
  async usernameExists(username) {
    const result = await pool.query(
      'SELECT user_id FROM users WHERE username = $1',
      [username]
    );
    return result.rows.length > 0;
  },

  /**
   * Check if license number already exists
   * @param {string} licenseNumber - License number to check
   * @returns {boolean} True if license number exists
   */
  async licenseExists(licenseNumber) {
    const result = await pool.query(
      'SELECT doctor_id FROM doctors WHERE license_number = $1',
      [licenseNumber]
    );
    return result.rows.length > 0;
  },

  /**
   * Check if phone number already exists
   * @param {string} phone - Phone number to check
   * @returns {boolean} True if phone exists
   */
  async phoneExists(phone) {
    const result = await pool.query(
      'SELECT doctor_id FROM doctors WHERE phone = $1',
      [phone]
    );
    return result.rows.length > 0;
  }
};

module.exports = DoctorModel;