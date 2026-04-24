// =====================================================
// APPOINTMENT MODEL
// =====================================================
// Database operations for appointments
// =====================================================

const pool = require('../config/db');

class AppointmentModel {
  /**
   * Create a new appointment
   */
  static async createAppointment(appointmentData) {
    const {
      doctor_id,
      patient_id,
      appointment_date,
      appointment_time,
      duration_minutes = 30,
      appointment_type = 'consultation',
      notes = '',
      status = 'scheduled'
    } = appointmentData;

    const query = `
      INSERT INTO appointments (
        doctor_id, patient_id, appointment_date, appointment_time,
        duration_minutes, appointment_type, notes, status, created_at
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())
      RETURNING *
    `;

    const values = [
      doctor_id, patient_id, appointment_date, appointment_time,
      duration_minutes, appointment_type, notes, status
    ];

    try {
      const result = await pool.query(query, values);
      return result.rows[0];
    } catch (error) {
      console.error('Error creating appointment:', error);
      throw error;
    }
  }

  /**
   * Get appointments by doctor
   */
  static async getAppointmentsByDoctor(doctorId, status = null, limit = null) {
    let query = `
      SELECT
        a.*,
        p.first_name as patient_first_name,
        p.last_name as patient_last_name,
        p.phone as patient_phone,
        u.email as patient_email
      FROM appointments a
      LEFT JOIN patients p ON a.patient_id = p.user_id
      LEFT JOIN users u ON a.patient_id = u.user_id
      WHERE a.doctor_id = $1
    `;

    const values = [doctorId];
    let paramIndex = 2;

    if (status) {
      query += ` AND a.status = $${paramIndex}`;
      values.push(status);
      paramIndex++;
    }

    query += ` ORDER BY a.appointment_date DESC, a.appointment_time DESC`;

    if (limit) {
      query += ` LIMIT $${paramIndex}`;
      values.push(limit);
    }

    try {
      const result = await pool.query(query, values);
      return result.rows;
    } catch (error) {
      console.error('Error getting appointments by doctor:', error);
      throw error;
    }
  }

  /**
   * Get appointments by patient
   */
  static async getAppointmentsByPatient(patientId, status = null) {
    let query = `
      SELECT
        a.*,
        d.first_name as doctor_first_name,
        d.last_name as doctor_last_name,
        d.specialization,
        d.clinic_address
      FROM appointments a
      LEFT JOIN doctors d ON a.doctor_id = d.user_id
      WHERE a.patient_id = $1
    `;

    const values = [patientId];
    let paramIndex = 2;

    if (status) {
      query += ` AND a.status = $${paramIndex}`;
      values.push(status);
      paramIndex++;
    }

    query += ` ORDER BY a.appointment_date DESC, a.appointment_time DESC`;

    try {
      const result = await pool.query(query, values);
      return result.rows;
    } catch (error) {
      console.error('Error getting appointments by patient:', error);
      throw error;
    }
  }

  /**
   * Update appointment status
   */
  static async updateAppointmentStatus(appointmentId, status, notes = null) {
    const query = `
      UPDATE appointments
      SET status = $1, updated_at = NOW()
      ${notes !== null ? ', notes = $3' : ''}
      WHERE appointment_id = $2
      RETURNING *
    `;

    const values = notes !== null ? [status, appointmentId, notes] : [status, appointmentId];

    try {
      const result = await pool.query(query, values);
      return result.rows[0];
    } catch (error) {
      console.error('Error updating appointment status:', error);
      throw error;
    }
  }

  /**
   * Get appointment by ID
   */
  static async getAppointmentById(appointmentId) {
    const query = `
      SELECT
        a.*,
        p.first_name as patient_first_name,
        p.last_name as patient_last_name,
        p.phone as patient_phone,
        p.date_of_birth,
        d.first_name as doctor_first_name,
        d.last_name as doctor_last_name,
        d.specialization,
        d.license_number,
        d.clinic_address,
        u.email as patient_email
      FROM appointments a
      LEFT JOIN patients p ON a.patient_id = p.user_id
      LEFT JOIN doctors d ON a.doctor_id = d.user_id
      LEFT JOIN users u ON a.patient_id = u.user_id
      WHERE a.appointment_id = $1
    `;

    try {
      const result = await pool.query(query, [appointmentId]);
      return result.rows[0];
    } catch (error) {
      console.error('Error getting appointment by ID:', error);
      throw error;
    }
  }

  /**
   * Get appointments for a specific date range
   */
  static async getAppointmentsByDateRange(doctorId, startDate, endDate) {
    const query = `
      SELECT
        a.*,
        p.first_name as patient_first_name,
        p.last_name as patient_last_name,
        p.phone as patient_phone
      FROM appointments a
      LEFT JOIN patients p ON a.patient_id = p.user_id
      WHERE a.doctor_id = $1
      AND a.appointment_date BETWEEN $2 AND $3
      ORDER BY a.appointment_date, a.appointment_time
    `;

    try {
      const result = await pool.query(query, [doctorId, startDate, endDate]);
      return result.rows;
    } catch (error) {
      console.error('Error getting appointments by date range:', error);
      throw error;
    }
  }

  /**
   * Delete appointment
   */
  static async deleteAppointment(appointmentId) {
    const query = `DELETE FROM appointments WHERE appointment_id = $1 RETURNING *`;

    try {
      const result = await pool.query(query, [appointmentId]);
      return result.rows[0];
    } catch (error) {
      console.error('Error deleting appointment:', error);
      throw error;
    }
  }
}

module.exports = AppointmentModel;