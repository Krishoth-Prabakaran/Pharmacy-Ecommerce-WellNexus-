// =====================================================
// PATIENT MODEL
// =====================================================
// Handles all database operations related to patients
// =====================================================

const pool = require("../config/db");

const PatientModel = {
  /**
   * Create a new patient
   * @param {Object} patientData - Patient details
   * @returns {Object} Created patient
   */
  async create(patientData) {
    const client = await pool.connect();

    try {
      await client.query('BEGIN');

      // First create user if not exists
      let userId = patientData.user_id;

      if (!userId) {
        const userResult = await client.query(
          `INSERT INTO users (username, email, password_hash, role, created_at)
           VALUES ($1, $2, $3, $4, NOW())
           RETURNING user_id`,
          [patientData.username, patientData.email?.toLowerCase(), patientData.password_hash, 'patient']
        );
        userId = userResult.rows[0].user_id;
      }

      // Create patient record
      const patientResult = await client.query(
        `INSERT INTO patients (first_name, last_name, phone, email, date_of_birth, gender, user_id)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         RETURNING *`,
        [
          patientData.first_name,
          patientData.last_name,
          patientData.phone,
          patientData.email?.toLowerCase(),
          patientData.date_of_birth,
          patientData.gender,
          userId
        ]
      );

      await client.query('COMMIT');

      return {
        ...patientResult.rows[0],
        user_id: userId
      };
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  },

  /**
   * Get patient by ID
   * @param {number} patientId
   * @returns {Object} Patient data
   */
  async getById(patientId) {
    const result = await pool.query(
      `SELECT p.*, u.username, u.email as user_email, u.role
       FROM patients p
       LEFT JOIN users u ON p.user_id = u.user_id
       WHERE p.patient_id = $1`,
      [patientId]
    );
    return result.rows[0];
  },

  /**
   * Get all patients
   * @returns {Array} List of patients
   */
  async getAll() {
    const result = await pool.query(
      `SELECT p.*, u.username, u.email as user_email, u.role
       FROM patients p
       LEFT JOIN users u ON p.user_id = u.user_id
       ORDER BY p.patient_id DESC`
    );
    return result.rows;
  },

  /**
   * Update patient
   * @param {number} patientId
   * @param {Object} updateData
   * @returns {Object} Updated patient
   */
  async update(patientId, updateData) {
    const fields = [];
    const values = [];
    let paramCount = 1;

    Object.keys(updateData).forEach(key => {
      if (updateData[key] !== undefined) {
        fields.push(`${key} = $${paramCount}`);
        values.push(updateData[key]);
        paramCount++;
      }
    });

    if (fields.length === 0) {
      throw new Error('No fields to update');
    }

    values.push(patientId);

    const result = await pool.query(
      `UPDATE patients SET ${fields.join(', ')} WHERE patient_id = $${paramCount} RETURNING *`,
      values
    );

    return result.rows[0];
  },

  /**
   * Delete patient
   * @param {number} patientId
   */
  async delete(patientId) {
    await pool.query('DELETE FROM patients WHERE patient_id = $1', [patientId]);
  }
};

module.exports = PatientModel;