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
      const [users, patients, doctors, pharmacists, appointments, prescriptions, orders] = await Promise.all([
        pool.query("SELECT COUNT(*) as total FROM users WHERE email_verified = true"),
        pool.query("SELECT COUNT(*) as total FROM patients"),
        pool.query("SELECT COUNT(*) as total FROM doctors"),
        pool.query("SELECT COUNT(*) as total FROM pharmacies"),
        pool.query("SELECT COUNT(*) as total FROM appointments"),
        pool.query("SELECT COUNT(*) as total FROM prescriptions"),
        pool.query("SELECT COUNT(*) as total FROM orders"),
      ]);

      // Get revenue statistics from orders
      const revenue = await pool.query(`
        SELECT COALESCE(SUM(total_amount), 0) as total_revenue
        FROM orders 
        WHERE status = 'completed'
      `);

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
        
        UNION ALL
        
        (SELECT 
          'order' as type,
          o.order_id as id,
          CONCAT('Order #', o.order_number, ' - ', ph.pharmacy_name) as description,
          o.created_at as timestamp
        FROM orders o
        LEFT JOIN pharmacies ph ON o.pharmacy_id = ph.pharmacy_id
        ORDER BY o.created_at DESC LIMIT 5)
        
        ORDER BY timestamp DESC LIMIT 10
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
          totalOrders: parseInt(orders.rows[0]?.total || 0),
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
   * Get all pharmacies with their details
   * @param {Object} options - Query options
   * @returns {Array} List of pharmacies
   */
  async getAllPharmacies(options = {}) {
    const { page = 1, limit = 20, search = null } = options;
    const offset = (page - 1) * limit;
    let params = [];
    let paramCount = 1;

    let whereClause = '';
    if (search) {
      whereClause = `WHERE p.pharmacy_name ILIKE $${paramCount} OR pb.address ILIKE $${paramCount} OR pb.phone ILIKE $${paramCount}`;
      params.push(`%${search}%`);
      paramCount++;
    }

    try {
      const [pharmaciesResult, countResult] = await Promise.all([
        pool.query(
          `SELECT DISTINCT 
            p.pharmacy_id, p.pharmacy_name, p.is_verified, p.verified_at, p.verification_notes,
            u.user_id, u.email, u.username, u.email_verified,
            (SELECT json_agg(json_build_object(
              'branch_id', pb.branch_id,
              'branch_name', pb.branch_name,
              'address', pb.address,
              'phone', pb.phone,
              'latitude', pb.latitude,
              'longitude', pb.longitude,
              'open_time', pb.open_time,
              'close_time', pb.close_time,
              'is_main_branch', pb.is_main_branch
            )) as branches
           FROM pharmacies p
           LEFT JOIN users u ON p.user_id = u.user_id
           LEFT JOIN pharmacy_branches pb ON p.pharmacy_id = pb.pharmacy_id
           ${whereClause}
           GROUP BY p.pharmacy_id, p.pharmacy_name, p.is_verified, p.verified_at, p.verification_notes,
                    u.user_id, u.email, u.username, u.email_verified
           ORDER BY p.pharmacy_id DESC
           LIMIT $${paramCount} OFFSET $${paramCount + 1}`,
          [...params, limit, offset]
        ),
        pool.query(`SELECT COUNT(DISTINCT p.pharmacy_id) as total FROM pharmacies p ${whereClause.replace(/pb\./g, 'p.')}`, params.filter(p => !p.includes('%'))),
      ]);

      return {
        success: true,
        pharmacies: pharmaciesResult.rows,
        pagination: {
          currentPage: page,
          totalPages: Math.ceil((countResult.rows[0]?.total || 0) / limit),
          totalPharmacies: parseInt(countResult.rows[0]?.total || 0),
          hasNext: page * limit < (countResult.rows[0]?.total || 0),
          hasPrev: page > 1,
        },
      };
    } catch (error) {
      console.error("Error fetching pharmacies:", error);
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
           LEFT JOIN patients p ON a.patient_id = p.user_id
           LEFT JOIN doctors d ON a.doctor_id = d.user_id
           LEFT JOIN users u ON p.user_id = u.user_id
           LEFT JOIN users u2 ON d.user_id = u2.user_id
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
   * Get all orders with details
   * @param {Object} options - Query options
   * @returns {Array} List of orders
   */
  async getAllOrders(options = {}) {
    const { page = 1, limit = 20, status = null } = options;
    const offset = (page - 1) * limit;
    let params = [];
    let paramCount = 1;

    let whereClause = '';
    if (status) {
      whereClause = `WHERE o.status = $${paramCount}`;
      params.push(status);
      paramCount++;
    }

    try {
      const [ordersResult, countResult] = await Promise.all([
        pool.query(
          `SELECT o.order_id, o.order_number, o.status, o.total_amount, 
                  o.payment_method, o.payment_status, o.shipping_address, o.notes,
                  o.created_at, o.updated_at,
                  p.patient_id, p.first_name as patient_first_name, p.last_name as patient_last_name,
                  ph.pharmacy_id, ph.pharmacy_name,
                  (SELECT json_agg(json_build_object(
                    'order_item_id', oi.order_item_id,
                    'variant_id', oi.variant_id,
                    'quantity', oi.quantity,
                    'unit_price', oi.unit_price,
                    'total_price', oi.total_price,
                    'medicine_name', m.name,
                    'strength', mv.strength,
                    'form', mv.form
                  )) as items
           FROM orders o
           LEFT JOIN patients p ON o.patient_id = p.patient_id
           LEFT JOIN pharmacies ph ON o.pharmacy_id = ph.pharmacy_id
           LEFT JOIN order_items oi ON o.order_id = oi.order_id
           LEFT JOIN medicine_variants mv ON oi.variant_id = mv.variant_id
           LEFT JOIN medicines m ON mv.medicine_id = m.medicine_id
           ${whereClause}
           GROUP BY o.order_id, o.order_number, o.status, o.total_amount, 
                    o.payment_method, o.payment_status, o.shipping_address, o.notes,
                    o.created_at, o.updated_at,
                    p.patient_id, p.first_name, p.last_name,
                    ph.pharmacy_id, ph.pharmacy_name
           ORDER BY o.created_at DESC
           LIMIT $${paramCount} OFFSET $${paramCount + 1}`,
          [...params, limit, offset]
        ),
        pool.query(`SELECT COUNT(*) as total FROM orders o ${whereClause}`, params),
      ]);

      return {
        success: true,
        orders: ordersResult.rows,
        pagination: {
          currentPage: page,
          totalPages: Math.ceil(countResult.rows[0].total / limit),
          totalOrders: countResult.rows[0].total,
          hasNext: page * limit < countResult.rows[0].total,
          hasPrev: page > 1,
        },
      };
    } catch (error) {
      console.error("Error fetching orders:", error);
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
                  d.first_name as doctor_first_name, d.last_name as doctor_last_name,
                  (SELECT json_agg(json_build_object(
                    'item_id', pi.item_id,
                    'variant_id', pi.variant_id,
                    'dosage', pi.dosage,
                    'duration_days', pi.duration_days,
                    'medicine_name', m.name,
                    'strength', mv.strength,
                    'form', mv.form
                  )) as items
           FROM prescriptions p
           LEFT JOIN patients pt ON p.patient_id = pt.patient_id
           LEFT JOIN doctors d ON p.doctor_license = d.doctor_license
           LEFT JOIN prescription_items pi ON p.prescription_id = pi.prescription_id
           LEFT JOIN medicine_variants mv ON pi.variant_id = mv.variant_id
           LEFT JOIN medicines m ON mv.medicine_id = m.medicine_id
           ${whereClause}
           GROUP BY p.prescription_id, p.patient_id, p.doctor_name, p.prescription_date,
                    p.valid_until, p.sms_code, p.status, p.medicine_name, p.doctor_license,
                    pt.first_name, pt.last_name, pt.patient_id,
                    d.first_name, d.last_name, d.doctor_id
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
   * Deactivate or activate a user account
   * @param {number} userId - User ID
   * @param {boolean} isActive - Active status
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
   * @param {number} userId - User ID
   * @param {string} hashedPassword - New hashed password
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
   * Verify or unverify a doctor
   * @param {number} doctorId - Doctor ID
   * @param {boolean} isVerified - Verification status
   * @param {number} adminId - Admin user ID performing the action
   * @param {string} notes - Optional verification notes
   */
  async verifyDoctor(doctorId, isVerified, adminId, notes = null) {
    try {
      const result = await pool.query(
        `UPDATE doctors
         SET is_verified = $1,
             verified_at = CASE WHEN $1 THEN NOW() ELSE NULL END,
             verified_by = CASE WHEN $1 THEN $3 ELSE NULL END,
             verification_notes = CASE WHEN $4 IS NOT NULL THEN $4 ELSE verification_notes END
         WHERE doctor_id = $2
         RETURNING *`,
        [isVerified, doctorId, adminId, notes]
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
   * Verify or unverify a pharmacy
   * @param {number} pharmacyId - Pharmacy ID
   * @param {boolean} isVerified - Verification status
   * @param {number} adminId - Admin user ID performing the action
   * @param {string} notes - Optional verification notes
   */
  async verifyPharmacy(pharmacyId, isVerified, adminId, notes = null) {
    try {
      const result = await pool.query(
        `UPDATE pharmacies
         SET is_verified = $1,
             verified_at = CASE WHEN $1 THEN NOW() ELSE NULL END,
             verified_by = CASE WHEN $1 THEN $3 ELSE NULL END,
             verification_notes = CASE WHEN $4 IS NOT NULL THEN $4 ELSE verification_notes END
         WHERE pharmacy_id = $2
         RETURNING *`,
        [isVerified, pharmacyId, adminId, notes]
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
   * Get analytics data for most used medicines and pharmacy activity
   * @returns {Object} Analytics data
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

      // Pharmacy activity (orders and prescriptions filled)
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

      // Monthly trends for prescriptions and orders
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
   * @param {Object} options - Query options
   * @returns {Object} Paginated disputes list
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
   * @param {Object} disputeData - Dispute information
   * @returns {Object} Created dispute
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
   * @param {number} disputeId - Dispute ID
   * @param {string} status - New status
   * @param {number} adminId - Admin resolving the dispute
   * @param {string} resolutionNotes - Resolution notes
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