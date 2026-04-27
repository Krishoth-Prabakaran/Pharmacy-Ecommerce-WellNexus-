// backend/models/adminModel.js
// =====================================================
// ADMIN MODEL
// =====================================================

const pool = require("../config/db");

const AdminModel = {
  /**
   * Get system-wide statistics for admin dashboard
   * @returns {Object} System statistics
   */
  async getDashboardStats() {
    try {
      // Get total counts - FIXED: Check if tables exist first
      let appointmentsCount = 0;
      let prescriptionsCount = 0;
      let ordersCount = 0;
      
      try {
        const appointments = await pool.query("SELECT COUNT(*) as total FROM appointments");
        appointmentsCount = parseInt(appointments.rows[0]?.total || 0);
      } catch (e) {
        console.log("Appointments table not found, using 0");
      }
      
      try {
        const prescriptions = await pool.query("SELECT COUNT(*) as total FROM prescriptions");
        prescriptionsCount = parseInt(prescriptions.rows[0]?.total || 0);
      } catch (e) {
        console.log("Prescriptions table not found, using 0");
      }
      
      try {
        const orders = await pool.query("SELECT COUNT(*) as total FROM orders");
        ordersCount = parseInt(orders.rows[0]?.total || 0);
      } catch (e) {
        console.log("Orders table not found, using 0");
      }
      
      const [users, patients, doctors, pharmacists, revenue] = await Promise.all([
        pool.query("SELECT COUNT(*) as total FROM users WHERE email_verified = true"),
        pool.query("SELECT COUNT(*) as total FROM patients"),
        pool.query("SELECT COUNT(*) as total FROM doctors"),
        pool.query("SELECT COUNT(*) as total FROM pharmacies"),
        pool.query(`SELECT COALESCE(SUM(total_amount), 0) as total_revenue FROM orders WHERE status = 'completed'`).catch(() => ({ rows: [{ total_revenue: 0 }] })),
      ]);

      // Get recent activities - simplified to avoid missing tables
      let recentActivities = [];
      try {
        recentActivities = await pool.query(`
          (SELECT 
            'appointment' as type,
            a.appointment_id as id,
            CONCAT(u.username, ' - Appointment') as description,
            a.created_at as timestamp
          FROM appointments a
          JOIN users u ON a.patient_id = u.user_id
          ORDER BY a.created_at DESC LIMIT 5)
          ORDER BY timestamp DESC LIMIT 10
        `);
      } catch (e) {
        console.log("Could not fetch recent activities");
        recentActivities = { rows: [] };
      }

      return {
        success: true,
        stats: {
          totalUsers: parseInt(users.rows[0]?.total || 0),
          totalPatients: parseInt(patients.rows[0]?.total || 0),
          totalDoctors: parseInt(doctors.rows[0]?.total || 0),
          totalPharmacists: parseInt(pharmacists.rows[0]?.total || 0),
          totalAppointments: appointmentsCount,
          totalPrescriptions: prescriptionsCount,
          totalOrders: ordersCount,
          totalRevenue: parseFloat(revenue.rows[0]?.total_revenue || 0),
        },
        recentActivities: recentActivities.rows || [],
      };
    } catch (error) {
      console.error("Error fetching dashboard stats:", error);
      throw error;
    }
  },

  /**
   * Get all users with pagination and filtering
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
        pool.query(`SELECT COUNT(*) as total FROM patients p ${whereClause}`, params),
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
        pool.query(`SELECT COUNT(*) as total FROM doctors d ${whereClause}`, params),
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
   * Delete a user by ID
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
   * Deactivate or activate a user account
   */
  async setUserActiveStatus(userId, isActive) {
    try {
      const result = await pool.query(
        'UPDATE users SET is_active = $1 WHERE user_id = $2 RETURNING *',
        [isActive, userId]
      );
      if (result.rows.length === 0) {
        throw new Error('User not found');
      }
      return { 
        success: true, 
        message: `User ${isActive ? 'activated' : 'deactivated'} successfully`,
        user: result.rows[0]
      };
    } catch (error) {
      console.error("Error updating user status:", error);
      throw error;
    }
  },

  /**
   * Reset user password (admin forced reset)
   */
  async resetUserPassword(userId, hashedPassword) {
    try {
      const result = await pool.query(
        'UPDATE users SET password_hash = $1 WHERE user_id = $2 RETURNING user_id, username, email',
        [hashedPassword, userId]
      );
      if (result.rows.length === 0) {
        throw new Error('User not found');
      }
      return { 
        success: true, 
        message: 'Password reset successfully',
        user: result.rows[0]
      };
    } catch (error) {
      console.error("Error resetting user password:", error);
      throw error;
    }
  },

  /**
   * Verify or unverify a doctor - FIXED: Proper integer casting
   */
  async verifyDoctor(doctorId, isVerified, adminId, notes = null) {
    try {
      const adminIdInt = parseInt(adminId);
      if (isNaN(adminIdInt)) {
        throw new Error('Invalid admin ID');
      }

      const result = await pool.query(
        `UPDATE doctors
         SET is_verified = $1,
             verified_at = CASE WHEN $1 THEN NOW() ELSE NULL END,
             verified_by = CASE WHEN $1 THEN $3::integer ELSE NULL END,
             verification_notes = $4
         WHERE doctor_id = $2
         RETURNING *`,
        [isVerified, doctorId, adminIdInt, notes || null]
      );

      if (result.rows.length === 0) {
        throw new Error('Doctor not found');
      }

      return { success: true, doctor: result.rows[0] };
    } catch (error) {
      console.error("Error verifying doctor:", error);
      throw error;
    }
  },

  /**
   * Verify or unverify a pharmacy - FIXED: Proper integer casting
   */
  async verifyPharmacy(pharmacyId, isVerified, adminId, notes = null) {
    try {
      const adminIdInt = parseInt(adminId);
      if (isNaN(adminIdInt)) {
        throw new Error('Invalid admin ID');
      }

      const result = await pool.query(
        `UPDATE pharmacies
         SET is_verified = $1,
             verified_at = CASE WHEN $1 THEN NOW() ELSE NULL END,
             verified_by = CASE WHEN $1 THEN $3::integer ELSE NULL END,
             verification_notes = $4
         WHERE pharmacy_id = $2
         RETURNING *`,
        [isVerified, pharmacyId, adminIdInt, notes || null]
      );

      if (result.rows.length === 0) {
        throw new Error('Pharmacy not found');
      }

      return { success: true, pharmacy: result.rows[0] };
    } catch (error) {
      console.error("Error verifying pharmacy:", error);
      throw error;
    }
  },

  /**
   * Get analytics data - FIXED: Proper table aliases
   */
  async getAnalytics() {
    try {
      // Most used medicines (from prescriptions)
      const mostUsedMedicines = await pool.query(`
        SELECT
          m.name as medicine_name,
          COUNT(DISTINCT p.prescription_id) as prescription_count,
          COUNT(DISTINCT p.patient_id) as unique_patients
        FROM prescriptions p
        LEFT JOIN prescription_items pi ON p.prescription_id = pi.prescription_id
        LEFT JOIN medicine_variants mv ON pi.variant_id = mv.variant_id
        LEFT JOIN medicines m ON mv.medicine_id = m.medicine_id
        WHERE p.status = 'active' OR p.status = 'filled'
        GROUP BY m.name
        ORDER BY prescription_count DESC
        LIMIT 10
      `);

      // Pharmacy activity - FIXED: Use correct table alias
      const pharmacyActivity = await pool.query(`
        SELECT
          ph.pharmacy_name,
          ph.pharmacy_id,
          COUNT(DISTINCT o.order_id) as total_orders,
          COUNT(DISTINCT p.prescription_id) as prescriptions_filled,
          COALESCE(SUM(o.total_amount), 0) as total_revenue,
          AVG(o.total_amount) as avg_order_value
        FROM pharmacies ph
        LEFT JOIN orders o ON ph.pharmacy_id = o.pharmacy_id AND o.status = 'completed'
        LEFT JOIN prescriptions p ON ph.pharmacy_id = p.pharmacy_id AND p.status = 'filled'
        GROUP BY ph.pharmacy_id, ph.pharmacy_name
        ORDER BY total_orders DESC
        LIMIT 10
      `);

      // Monthly trends
      const monthlyTrends = await pool.query(`
        SELECT
          TO_CHAR(date_trunc, 'YYYY-MM') as month,
          COALESCE(SUM(completed_orders), 0) as completed_orders,
          COALESCE(SUM(filled_prescriptions), 0) as filled_prescriptions
        FROM (
          SELECT 
            DATE_TRUNC('month', created_at) as date_trunc,
            COUNT(*) as completed_orders,
            0 as filled_prescriptions
          FROM orders
          WHERE status = 'completed'
          GROUP BY DATE_TRUNC('month', created_at)
          
          UNION ALL
          
          SELECT 
            DATE_TRUNC('month', prescription_date) as date_trunc,
            0 as completed_orders,
            COUNT(*) as filled_prescriptions
          FROM prescriptions
          WHERE status = 'filled'
          GROUP BY DATE_TRUNC('month', prescription_date)
        ) combined
        WHERE date_trunc >= DATE_TRUNC('month', NOW() - INTERVAL '12 months')
        GROUP BY date_trunc
        ORDER BY date_trunc DESC
      `);

      return {
        success: true,
        analytics: {
          mostUsedMedicines: mostUsedMedicines.rows,
          pharmacyActivity: pharmacyActivity.rows,
          monthlyTrends: monthlyTrends.rows,
        },
      };
    } catch (error) {
      console.error("Error fetching analytics:", error);
      throw error;
    }
  },

  /**
   * Get all disputes with pagination
   */
  async getAllDisputes(options = {}) {
    const { page = 1, limit = 20, status = null, type = null } = options;
    const offset = (page - 1) * limit;
    let whereConditions = [];
    let params = [];
    let paramCount = 1;

    if (status) {
      whereConditions.push(`status = $${paramCount}`);
      params.push(status);
      paramCount++;
    }

    if (type) {
      whereConditions.push(`dispute_type = $${paramCount}`);
      params.push(type);
      paramCount++;
    }

    const whereClause = whereConditions.length > 0 ? `WHERE ${whereConditions.join(' AND ')}` : '';

    try {
      const [disputesResult, countResult] = await Promise.all([
        pool.query(
          `SELECT d.*,
                  u.username, u.email,
                  r.username as resolved_by_username
           FROM disputes d
           JOIN users u ON d.user_id = u.user_id
           LEFT JOIN users r ON d.resolved_by = r.user_id
           ${whereClause}
           ORDER BY d.created_at DESC
           LIMIT $${paramCount} OFFSET $${paramCount + 1}`,
          [...params, limit, offset]
        ),
        pool.query(`SELECT COUNT(*) as total FROM disputes d ${whereClause}`, params),
      ]);

      return {
        success: true,
        disputes: disputesResult.rows,
        pagination: {
          currentPage: page,
          totalPages: Math.ceil(countResult.rows[0].total / limit),
          totalDisputes: countResult.rows[0].total,
          hasNext: page * limit < countResult.rows[0].total,
          hasPrev: page > 1,
        },
      };
    } catch (error) {
      console.error("Error fetching disputes:", error);
      throw error;
    }
  },

  /**
   * Create a new dispute
   */
  async createDispute(disputeData) {
    const { userId, disputeType, relatedId, description, priority = 'medium' } = disputeData;

    try {
      const result = await pool.query(
        `INSERT INTO disputes (user_id, dispute_type, related_id, description, priority)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING *`,
        [userId, disputeType, relatedId, description, priority]
      );

      return { success: true, dispute: result.rows[0] };
    } catch (error) {
      console.error("Error creating dispute:", error);
      throw error;
    }
  },

  /**
   * Update dispute status
   */
  async updateDisputeStatus(disputeId, status, adminId, resolutionNotes = null) {
    try {
      const result = await pool.query(
        `UPDATE disputes
         SET status = $1,
             resolved_by = $2,
             resolution_notes = $3,
             updated_at = NOW()
         WHERE dispute_id = $4
         RETURNING *`,
        [status, adminId, resolutionNotes, disputeId]
      );

      if (result.rows.length === 0) {
        throw new Error('Dispute not found');
      }

      return { success: true, dispute: result.rows[0] };
    } catch (error) {
      console.error("Error updating dispute status:", error);
      throw error;
    }
  },
};

module.exports = AdminModel;