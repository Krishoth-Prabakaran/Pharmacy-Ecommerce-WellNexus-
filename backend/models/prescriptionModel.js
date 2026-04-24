// =====================================================
// PRESCRIPTION MODEL
// =====================================================
// Handles all database operations related to prescriptions
// =====================================================

const pool = require("../config/db");

const PrescriptionModel = {
  /**
   * Create a new prescription
   * @param {Object} prescriptionData - Prescription details
   * @returns {Object} Created prescription
   */
  async create(prescriptionData) {
    const client = await pool.connect();

    try {
      await client.query('BEGIN');

      // Generate SMS code (simple random string)
      const smsCode = Math.random().toString(36).substring(2, 8).toUpperCase();

      const result = await client.query(
        `INSERT INTO prescriptions (patient_id, doctor_name, prescription_date, valid_until, sms_code, status, medicine_name, doctor_license)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         RETURNING *`,
        [
          prescriptionData.patient_id,
          prescriptionData.doctor_name,
          prescriptionData.prescription_date || new Date(),
          prescriptionData.valid_until,
          smsCode,
          prescriptionData.status || 'active',
          prescriptionData.medicine_name,
          prescriptionData.doctor_license
        ]
      );

      const prescription = result.rows[0];

      // Add prescription items if provided
      if (prescriptionData.items && prescriptionData.items.length > 0) {
        for (const item of prescriptionData.items) {
          await client.query(
            `INSERT INTO prescription_items (prescription_id, variant_id, dosage, duration_days)
             VALUES ($1, $2, $3, $4)`,
            [prescription.prescription_id, item.variant_id, item.dosage, item.duration_days]
          );
        }
      }

      await client.query('COMMIT');

      return prescription;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  },

  /**
   * Get prescription by ID with items
   * @param {number} prescriptionId
   * @returns {Object} Prescription with items
   */
  async getById(prescriptionId) {
    const prescriptionResult = await pool.query(
      `SELECT p.*, pt.first_name, pt.last_name, pt.phone
       FROM prescriptions p
       LEFT JOIN patients pt ON p.patient_id = pt.patient_id
       WHERE p.prescription_id = $1`,
      [prescriptionId]
    );

    if (prescriptionResult.rows.length === 0) {
      return null;
    }

    const prescription = prescriptionResult.rows[0];

    const itemsResult = await pool.query(
      `SELECT pi.*, mv.variant_name, mv.medicine_name as base_medicine_name
       FROM prescription_items pi
       LEFT JOIN medicine_variants mv ON pi.variant_id = mv.variant_id
       WHERE pi.prescription_id = $1`,
      [prescriptionId]
    );

    prescription.items = itemsResult.rows;

    return prescription;
  },

  /**
   * Get prescriptions by doctor license
   * @param {number} doctorLicense
   * @returns {Array} List of prescriptions
   */
  async getByDoctor(doctorLicense) {
    const result = await pool.query(
      `SELECT p.*, pt.first_name, pt.last_name, pt.phone
       FROM prescriptions p
       LEFT JOIN patients pt ON p.patient_id = pt.patient_id
       WHERE p.doctor_license = $1
       ORDER BY p.prescription_date DESC`,
      [doctorLicense]
    );
    return result.rows;
  },

  /**
   * Get prescriptions by patient ID
   * @param {number} patientId
   * @returns {Array} List of prescriptions
   */
  async getByPatient(patientId) {
    const result = await pool.query(
      `SELECT p.*, d.first_name as doctor_first_name, d.last_name as doctor_last_name
       FROM prescriptions p
       LEFT JOIN doctors d ON p.doctor_license = d.doctor_license
       WHERE p.patient_id = $1
       ORDER BY p.prescription_date DESC`,
      [patientId]
    );
    return result.rows;
  },

  /**
   * Update prescription status
   * @param {number} prescriptionId
   * @param {string} status
   * @returns {Object} Updated prescription
   */
  async updateStatus(prescriptionId, status) {
    const result = await pool.query(
      `UPDATE prescriptions SET status = $1 WHERE prescription_id = $2 RETURNING *`,
      [status, prescriptionId]
    );
    return result.rows[0];
  },

  /**
   * Delete prescription
   * @param {number} prescriptionId
   */
  async delete(prescriptionId) {
    await pool.query('DELETE FROM prescriptions WHERE prescription_id = $1', [prescriptionId]);
  }
};

module.exports = PrescriptionModel;