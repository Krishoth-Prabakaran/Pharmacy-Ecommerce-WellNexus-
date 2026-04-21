// =====================================================
// ADMIN MODEL
// =====================================================
// Handles all database operations related to admin dashboard
// Provides statistics and management capabilities for admins
// =====================================================

const pool = require("../config/db");

const AdminModel = {
  /**
   * Get system-wide statistics for admin dashboard
   * @returns {Object} System statistics
   */
  async getDashboardStats() {
    try {
      // Get total counts
      const [users, patients, doctors, pharmacists, appointments, prescriptions] = await Promise.all([
        pool.query("SELECT COUNT(*) as total FROM users WHERE email_verified = true"),
        pool.query("SELECT COUNT(*) as total FROM patients"),
        pool.query("SELECT COUNT(*) as total FROM doctors"),
        pool.query("SELECT COUNT(*) as total FROM pharmacies"),
        pool.query("SELECT COUNT(*) as total FROM appointments"),
        pool.query("SELECT COUNT(*) as total FROM prescriptions"),
      ]);

      // Get recent activities
      const recentActivities = await pool.query(`
        (SELECT 
          'appointment' as type,
          a.appointment_id as id,
          CONCAT(u.username, ' - Appointment with Dr. ', d.username) as description,
          a.created_at as timestamp
        FROM appointments a
        JOIN users u ON a.patient_id = u.user_id
        JOIN users d ON a.doctor_id = d.user_id
        ORDER BY a.created_at DESC LIMIT 5)
        
        UNION ALL
        
        (SELECT 
          'prescription' as type,
          p.prescription_id as id,
          CONCAT('Prescription for ', pt.first_name, ' ', pt.last_name) as description,
          p.prescription_date as timestamp
        FROM prescriptions p
        LEFT JOIN patients pt ON p.patient_id = pt.patient_id
        ORDER BY p.prescription_date DESC LIMIT 5)
        
        ORDER BY timestamp DESC LIMIT 10
      `);

      // Get revenue statistics (from pharmacy sales if applicable)
      const revenue = await pool.query(`
        SELECT COALESCE(SUM(total_amount), 0) as total_revenue
        FROM orders 
        WHERE status = 'completed'
      `);

      return {
        success: true,
        stats: {
          totalUsers: parseInt(users.rows[0]?.total || 0),
          totalPatients: parseInt(patients.rows[0]?.total || 0),
          totalDoctors: parseInt(doctors.rows[0]?.total || 0),
          totalPharmacists: parseInt(pharmacists.rows[0]?.total || 0),
          totalAppointments: parseInt(appointments.rows[0]?.total || 0),
          totalPrescriptions: parseInt(prescriptions.rows[0]?.total || 0),
          totalRevenue: parseFloat(revenue.rows[0]?.total_revenue || 0),
        },
        recentActivities: recentActivities.rows,
      };
    } catch (error) {
      console.error("Error fetching dashboard stats:", error);
      throw error;
    }
  },

  /**
   * Get all users with pagination and filtering
   * @param {Object} options - Query options
   * @returns {Object} Paginated users list
   */
  async getAllUsers(options = {}) {
    const {
      page = 1,
      limit = 20,
      role = null,
      search = null,
      sortBy = 'created_at',
      sortOrder = 'DESC',
    } = options;

    const offset = (page - 1) * limit;
    let whereConditions = [];
    let params = [];
    let paramCount = 1;

    if (role) {
      whereConditions.push(`role = $${paramCount}`);
      params.push(role);
      paramCount++;
    }

    if (search) {
      whereConditions.push(`(username ILIKE $${paramCount} OR email ILIKE $${paramCount})`);
      params.push(`%${search}%`);
      paramCount++;
    }

    const whereClause = whereConditions.length > 0 ? `WHERE ${whereConditions.join(' AND ')}` : '';

    try {
      const [usersResult, countResult] = await Promise.all([
        pool.query(
          `SELECT user_id, username, email, role, email_verified, created_at 
           FROM users 
           ${whereClause} 
           ORDER BY ${sortBy} ${sortOrder} 
           LIMIT $${paramCount} OFFSET $${paramCount + 1}`,
          [...params, limit, offset]
        ),
        pool.query(`SELECT COUNT(*) as total FROM users ${whereClause}`, params),
      ]);

      return {
        success: true,
        users: usersResult.rows,
        pagination: {
          currentPage: page,
          totalPages: Math.ceil(countResult.rows[0].total / limit),
          totalUsers: countResult.rows[0].total,
          hasNext: page * limit < countResult.rows[0].total,
          hasPrev: page > 1,
        },
      };
    } catch (error) {
      console.error("Error fetching users:", error);
      throw error;
    }
  },

  /**
   * Get all patients with their details
   * @param {Object} options - Query options
   * @returns {Array} List of patients
   */
  async getAllPatients(options = {}) {
    const { page = 1, limit = 20, search = null } = options;
    const offset = (page - 1) * limit;
    let params = [];
    let paramCount = 1;

    let whereClause = '';
    if (search) {
      whereClause = `WHERE p.first_name ILIKE $${paramCount} OR p.last_name ILIKE $${paramCount} OR p.phone ILIKE $${paramCount} OR p.email ILIKE $${paramCount}`;
      params.push(`%${search}%`);
      paramCount++;
    }

    try {
      const [patientsResult, countResult] = await Promise.all([
        pool.query(
          `SELECT p.*, u.username, u.email as user_email, u.role, u.email_verified, u.created_at
           FROM patients p
           LEFT JOIN users u ON p.user_id = u.user_id
           ${whereClause}
           ORDER BY p.patient_id DESC
           LIMIT $${paramCount} OFFSET $${paramCount + 1}`,
          [...params, limit, offset]
        ),
        pool.query(`SELECT COUNT(*) as total FROM patients p LEFT JOIN users u ON p.user_id = u.user_id ${whereClause}`, params),
      ]);

      return {
        success: true,
        patients: patientsResult.rows,
        pagination: {
          currentPage: page,
          totalPages: Math.ceil(countResult.rows[0].total / limit),
          totalPatients: countResult.rows[0].total,
          hasNext: page * limit < countResult.rows[0].total,
          hasPrev: page > 1,
        },
      };
    } catch (error) {
      console.error("Error fetching patients:", error);
      throw error;
    }
  },

  /**
   * Get all doctors with their details
   * @param {Object} options - Query options
   * @returns {Array} List of doctors
   */
  async getAllDoctors(options = {}) {
    const { page = 1, limit = 20, search = null } = options;
    const offset = (page - 1) * limit;
    let params = [];
    let paramCount = 1;

    let whereClause = '';
    if (search) {
      whereClause = `WHERE d.first_name ILIKE $${paramCount} OR d.last_name ILIKE $${paramCount} OR d.specialization ILIKE $${paramCount}`;
      params.push(`%${search}%`);
      paramCount++;
    }

    try {
      const [doctorsResult, countResult] = await Promise.all([
        pool.query(
          `SELECT d.*, u.username, u.email as user_email, u.role, u.email_verified, u.created_at
           FROM doctors d
           LEFT JOIN users u ON d.user_id = u.user_id
           ${whereClause}
           ORDER BY d.doctor_id DESC
           LIMIT $${paramCount} OFFSET $${paramCount + 1}`,
          [...params, limit, offset]
        ),
        pool.query(`SELECT COUNT(*) as total FROM doctors d LEFT JOIN users u ON d.user_id = u.user_id ${whereClause}`, params),
      ]);

      return {
        success: true,
        doctors: doctorsResult.rows,
        pagination: {
          currentPage: page,
          totalPages: Math.ceil(countResult.rows[0].total / limit),
          totalDoctors: countResult.rows[0].total,
          hasNext: page * limit < countResult.rows[0].total,
          hasPrev: page > 1,
        },
      };
    } catch (error) {
      console.error("Error fetching doctors:", error);
      throw error;
    }
  },

  /**
   * Get all appointments with details
   * @param {Object} options - Query options
   * @returns {Array} List of appointments
   */
  async getAllAppointments(options = {}) {
    const { page = 1, limit = 20, status = null } = options;
    const offset = (page - 1) * limit;
    let params = [];
    let paramCount = 1;

    let whereClause = '';
    if (status) {
      whereClause = `WHERE a.status = $${paramCount}`;
      params.push(status);
      paramCount++;
    }

    try {
      const [appointmentsResult, countResult] = await Promise.all([
        pool.query(
          `SELECT a.*, 
                  p.first_name as patient_first_name, p.last_name as patient_last_name,
                  d.first_name as doctor_first_name, d.last_name as doctor_last_name,
                  u.username as patient_username, u2.username as doctor_username
           FROM appointments a
           JOIN patients p ON a.patient_id = p.patient_id
           JOIN doctors d ON a.doctor_id = d.doctor_id
           JOIN users u ON p.user_id = u.user_id
           JOIN users u2 ON d.user_id = u2.user_id
           ${whereClause}
           ORDER BY a.appointment_date DESC, a.appointment_time DESC
           LIMIT $${paramCount} OFFSET $${paramCount + 1}`,
          [...params, limit, offset]
        ),
        pool.query(`SELECT COUNT(*) as total FROM appointments a ${whereClause}`, params),
      ]);

      return {
        success: true,
        appointments: appointmentsResult.rows,
        pagination: {
          currentPage: page,
          totalPages: Math.ceil(countResult.rows[0].total / limit),
          totalAppointments: countResult.rows[0].total,
          hasNext: page * limit < countResult.rows[0].total,
          hasPrev: page > 1,
        },
      };
    } catch (error) {
      console.error("Error fetching appointments:", error);
      throw error;
    }
  },

  /**
   * Delete a user by ID
   * @param {number} userId - User ID to delete
   */
  async deleteUser(userId) {
    try {
      await pool.query('DELETE FROM users WHERE user_id = $1', [userId]);
      return { success: true, message: 'User deleted successfully' };
    } catch (error) {
      console.error("Error deleting user:", error);
      throw error;
    }
  },

  /**
   * Update user role
   * @param {number} userId - User ID
   * @param {string} newRole - New role to assign
   */
  async updateUserRole(userId, newRole) {
    try {
      const result = await pool.query(
        'UPDATE users SET role = $1 WHERE user_id = $2 RETURNING *',
        [newRole, userId]
      );
      return { success: true, user: result.rows[0] };
    } catch (error) {
      console.error("Error updating user role:", error);
      throw error;
    }
  },

  /**
   * Get all prescriptions with details
   * @param {Object} options - Query options
   * @returns {Array} List of prescriptions
   */
  async getAllPrescriptions(options = {}) {
    const { page = 1, limit = 20, status = null } = options;
    const offset = (page - 1) * limit;
    let params = [];
    let paramCount = 1;

    let whereClause = '';
    if (status) {
      whereClause = `WHERE p.status = $${paramCount}`;
      params.push(status);
      paramCount++;
    }

    try {
      const [prescriptionsResult, countResult] = await Promise.all([
        pool.query(
          `SELECT p.*, 
                  pt.first_name as patient_first_name, pt.last_name as patient_last_name,
                  d.first_name as doctor_first_name, d.last_name as doctor_last_name
           FROM prescriptions p
           LEFT JOIN patients pt ON p.patient_id = pt.patient_id
           LEFT JOIN doctors d ON p.doctor_license = d.doctor_license
           ${whereClause}
           ORDER BY p.prescription_date DESC
           LIMIT $${paramCount} OFFSET $${paramCount + 1}`,
          [...params, limit, offset]
        ),
        pool.query(`SELECT COUNT(*) as total FROM prescriptions p ${whereClause}`, params),
      ]);

      return {
        success: true,
        prescriptions: prescriptionsResult.rows,
        pagination: {
          currentPage: page,
          totalPages: Math.ceil(countResult.rows[0].total / limit),
          totalPrescriptions: countResult.rows[0].total,
          hasNext: page * limit < countResult.rows[0].total,
          hasPrev: page > 1,
        },
      };
    } catch (error) {
      console.error("Error fetching prescriptions:", error);
      throw error;
    }
  },
};

module.exports = AdminModel;