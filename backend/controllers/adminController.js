// backend/controllers/adminController.js
const AdminModel = require("../models/adminModel");
const pool = require("../config/db");

// ==================== DASHBOARD STATS ====================
exports.getDashboardStats = async (req, res) => {
  console.log("📊 Fetching admin dashboard stats...");

  try {
    const result = await AdminModel.getDashboardStats();
    res.json(result);
  } catch (err) {
    console.error("❌ Error fetching dashboard stats:", err.message);
    res.status(500).json({
      success: false,
      message: "Failed to fetch dashboard stats",
      error: err.message,
    });
  }
};

// ==================== GET ALL USERS ====================
exports.getAllUsers = async (req, res) => {
  console.log("👥 Fetching all users...");

  try {
    const { page, limit, role, search, sortBy, sortOrder } = req.query;
    const options = {
      page: parseInt(page) || 1,
      limit: parseInt(limit) || 20,
      role: role || null,
      search: search || null,
      sortBy: sortBy || 'created_at',
      sortOrder: sortOrder || 'DESC',
    };

    const result = await AdminModel.getAllUsers(options);
    res.json(result);
  } catch (err) {
    console.error("❌ Error fetching users:", err.message);
    res.status(500).json({
      success: false,
      message: "Failed to fetch users",
      error: err.message,
    });
  }
};

// ==================== GET ALL PATIENTS ====================
exports.getAllPatients = async (req, res) => {
  console.log("🏥 Fetching all patients...");

  try {
    const { page, limit, search } = req.query;
    const options = {
      page: parseInt(page) || 1,
      limit: parseInt(limit) || 20,
      search: search || null,
    };

    const result = await AdminModel.getAllPatients(options);
    res.json(result);
  } catch (err) {
    console.error("❌ Error fetching patients:", err.message);
    res.status(500).json({
      success: false,
      message: "Failed to fetch patients",
      error: err.message,
    });
  }
};

// ==================== GET ALL DOCTORS ====================
exports.getAllDoctors = async (req, res) => {
  console.log("👨‍⚕️ Fetching all doctors...");

  try {
    const { page, limit, search } = req.query;
    const options = {
      page: parseInt(page) || 1,
      limit: parseInt(limit) || 20,
      search: search || null,
    };

    const result = await AdminModel.getAllDoctors(options);
    res.json(result);
  } catch (err) {
    console.error("❌ Error fetching doctors:", err.message);
    res.status(500).json({
      success: false,
      message: "Failed to fetch doctors",
      error: err.message,
    });
  }
};

// ==================== GET ALL PHARMACIES ====================
exports.getAllPharmacies = async (req, res) => {
  console.log("🏪 Fetching all pharmacies...");

  try {
    const { page = 1, limit = 20, search = null } = req.query;
    const offset = (page - 1) * limit;
    let params = [];
    let paramCount = 1;

    let whereClause = '';
    if (search && search.trim() !== '') {
      whereClause = `WHERE p.pharmacy_name ILIKE $${paramCount} OR pb.address ILIKE $${paramCount} OR pb.phone ILIKE $${paramCount}`;
      params.push(`%${search}%`);
      paramCount++;
    }

    const pharmaciesQuery = `
      SELECT 
        p.pharmacy_id, 
        p.pharmacy_name, 
        p.is_verified, 
        p.verified_at, 
        p.verification_notes,
        u.user_id, 
        u.email, 
        u.username, 
        u.email_verified,
        pb.branch_id,
        pb.branch_name,
        pb.address,
        pb.phone,
        pb.latitude,
        pb.longitude,
        pb.open_time,
        pb.close_time,
        pb.is_main_branch
      FROM pharmacies p
      LEFT JOIN users u ON p.user_id = u.user_id
      LEFT JOIN pharmacy_branches pb ON p.pharmacy_id = pb.pharmacy_id
      ${whereClause}
      ORDER BY p.pharmacy_id DESC
      LIMIT $${paramCount} OFFSET $${paramCount + 1}
    `;

    const pharmaciesResult = await pool.query(pharmaciesQuery, [...params, parseInt(limit), offset]);

    const countQuery = `
      SELECT COUNT(DISTINCT p.pharmacy_id) as total 
      FROM pharmacies p
      LEFT JOIN pharmacy_branches pb ON p.pharmacy_id = pb.pharmacy_id
      ${whereClause}
    `;
    const countResult = await pool.query(countQuery, params);

    const pharmacies = pharmaciesResult.rows.map(row => {
      return {
        pharmacy_id: row.pharmacy_id,
        pharmacy_name: row.pharmacy_name,
        name: row.pharmacy_name,
        address: row.address || 'Address not provided',
        location: row.address || 'Location not provided',
        phone: row.phone || 'Phone not available',
        email: row.email || 'Email not available',
        username: row.username || 'N/A',
        is_verified: row.is_verified || false,
        verified_at: row.verified_at,
        verification_notes: row.verification_notes,
        open_time: row.open_time,
        close_time: row.close_time,
        latitude: row.latitude ? parseFloat(row.latitude) : null,
        longitude: row.longitude ? parseFloat(row.longitude) : null,
        is_main_branch: row.is_main_branch || false,
        branch_name: row.branch_name || 'Main Branch',
        branch_id: row.branch_id
      };
    });

    console.log(`✅ Found ${pharmacies.length} pharmacies`);

    res.json({
      success: true,
      pharmacies: pharmacies,
      pagination: {
        currentPage: parseInt(page),
        totalPages: Math.ceil((countResult.rows[0]?.total || 0) / limit),
        totalPharmacies: parseInt(countResult.rows[0]?.total || 0),
        hasNext: page * limit < (countResult.rows[0]?.total || 0),
        hasPrev: page > 1,
      },
    });
  } catch (err) {
    console.error("❌ Error fetching pharmacies:", err.message);
    console.error("Stack:", err.stack);
    res.status(500).json({
      success: false,
      message: "Failed to fetch pharmacies",
      error: err.message,
    });
  }
};

// ==================== GET ALL APPOINTMENTS ====================
exports.getAllAppointments = async (req, res) => {
  console.log("📅 Fetching all appointments...");

  try {
    const { page = 1, limit = 20, status = null } = req.query;
    const offset = (page - 1) * limit;
    let params = [];
    let paramCount = 1;

    let whereClause = '';
    if (status) {
      whereClause = `WHERE a.status = $${paramCount}`;
      params.push(status);
      paramCount++;
    }

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

    res.json({
      success: true,
      appointments: appointmentsResult.rows,
      pagination: {
        currentPage: parseInt(page),
        totalPages: Math.ceil(countResult.rows[0].total / limit),
        totalAppointments: countResult.rows[0].total,
        hasNext: page * limit < countResult.rows[0].total,
        hasPrev: page > 1,
      },
    });
  } catch (err) {
    console.error("❌ Error fetching appointments:", err.message);
    res.status(500).json({
      success: false,
      message: "Failed to fetch appointments",
      error: err.message,
    });
  }
};

// ==================== GET ALL PRESCRIPTIONS ====================
exports.getAllPrescriptions = async (req, res) => {
  console.log("💊 Fetching all prescriptions...");

  try {
    const { page = 1, limit = 20, status = null } = req.query;
    const offset = (page - 1) * limit;
    let params = [];
    let paramCount = 1;

    let whereClause = '';
    if (status) {
      whereClause = `WHERE p.status = $${paramCount}`;
      params.push(status);
      paramCount++;
    }

    const [prescriptionsResult, countResult] = await Promise.all([
      pool.query(
        `SELECT p.*, 
                pt.first_name as patient_first_name, pt.last_name as patient_last_name,
                d.first_name as doctor_first_name, d.last_name as doctor_last_name
         FROM prescriptions p
         LEFT JOIN patients pt ON p.patient_id = pt.patient_id
         LEFT JOIN doctors d ON p.doctor_license = d.doctor_id
         ${whereClause}
         ORDER BY p.prescription_date DESC
         LIMIT $${paramCount} OFFSET $${paramCount + 1}`,
        [...params, limit, offset]
      ),
      pool.query(`SELECT COUNT(*) as total FROM prescriptions p ${whereClause}`, params),
    ]);

    res.json({
      success: true,
      prescriptions: prescriptionsResult.rows,
      pagination: {
        currentPage: parseInt(page),
        totalPages: Math.ceil(countResult.rows[0].total / limit),
        totalPrescriptions: countResult.rows[0].total,
        hasNext: page * limit < countResult.rows[0].total,
        hasPrev: page > 1,
      },
    });
  } catch (err) {
    console.error("❌ Error fetching prescriptions:", err.message);
    res.status(500).json({
      success: false,
      message: "Failed to fetch prescriptions",
      error: err.message,
    });
  }
};

// ==================== DELETE USER ====================
exports.deleteUser = async (req, res) => {
  const { userId } = req.params;
  console.log(`🗑️ Deleting user with ID: ${userId}`);

  try {
    const result = await AdminModel.deleteUser(userId);
    res.json(result);
  } catch (err) {
    console.error("❌ Error deleting user:", err.message);
    res.status(500).json({
      success: false,
      message: "Failed to delete user",
      error: err.message,
    });
  }
};

// ==================== UPDATE USER ROLE ====================
exports.updateUserRole = async (req, res) => {
  const { userId } = req.params;
  const { role } = req.body;
  console.log(`🔄 Updating role for user ID: ${userId} to: ${role}`);

  try {
    const validRoles = ['patient', 'doctor', 'pharmacist', 'admin'];
    if (!validRoles.includes(role)) {
      return res.status(400).json({
        success: false,
        message: `Invalid role. Must be one of: ${validRoles.join(', ')}`,
      });
    }

    const result = await AdminModel.updateUserRole(userId, role);
    res.json(result);
  } catch (err) {
    console.error("❌ Error updating user role:", err.message);
    res.status(500).json({
      success: false,
      message: "Failed to update user role",
      error: err.message,
    });
  }
};

// ==================== GET ORDERS ====================
exports.getAllOrders = async (req, res) => {
  console.log("📦 Fetching all orders...");

  try {
    const { page = 1, limit = 20, status = null } = req.query;
    const offset = (page - 1) * limit;
    let params = [];
    let paramCount = 1;

    let whereClause = '';
    if (status) {
      whereClause = `WHERE o.status = $${paramCount}`;
      params.push(status);
      paramCount++;
    }

    const [ordersResult, countResult] = await Promise.all([
      pool.query(
        `SELECT o.*, 
                p.first_name as patient_first_name, p.last_name as patient_last_name,
                ph.pharmacy_name
         FROM orders o
         LEFT JOIN patients p ON o.patient_id = p.patient_id
         LEFT JOIN pharmacies ph ON o.pharmacy_id = ph.pharmacy_id
         ${whereClause}
         ORDER BY o.created_at DESC
         LIMIT $${paramCount} OFFSET $${paramCount + 1}`,
        [...params, limit, offset]
      ),
      pool.query(`SELECT COUNT(*) as total FROM orders o ${whereClause}`, params),
    ]);

    res.json({
      success: true,
      orders: ordersResult.rows,
      pagination: {
        currentPage: parseInt(page),
        totalPages: Math.ceil(countResult.rows[0].total / limit),
        totalOrders: countResult.rows[0].total,
        hasNext: page * limit < countResult.rows[0].total,
        hasPrev: page > 1,
      },
    });
  } catch (err) {
    console.error("❌ Error fetching orders:", err.message);
    res.status(500).json({
      success: false,
      message: "Failed to fetch orders",
      error: err.message,
    });
  }
};

// ==================== UPDATE APPOINTMENT STATUS ====================
exports.updateAppointmentStatus = async (req, res) => {
  const { appointmentId } = req.params;
  const { status } = req.body;
  console.log(`🔄 Updating appointment ${appointmentId} status to: ${status}`);

  try {
    const validStatuses = ['scheduled', 'confirmed', 'in_progress', 'completed', 'cancelled', 'no_show'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: `Invalid status. Must be one of: ${validStatuses.join(', ')}`,
      });
    }

    const result = await pool.query(
      'UPDATE appointments SET status = $1, updated_at = NOW() WHERE appointment_id = $2 RETURNING *',
      [status, appointmentId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Appointment not found',
      });
    }

    res.json({
      success: true,
      appointment: result.rows[0],
    });
  } catch (err) {
    console.error("❌ Error updating appointment status:", err.message);
    res.status(500).json({
      success: false,
      message: "Failed to update appointment status",
      error: err.message,
    });
  }
};

// ==================== UPDATE PRESCRIPTION STATUS ====================
exports.updatePrescriptionStatus = async (req, res) => {
  const { prescriptionId } = req.params;
  const { status } = req.body;
  console.log(`🔄 Updating prescription ${prescriptionId} status to: ${status}`);

  try {
    const validStatuses = ['active', 'filled', 'expired', 'cancelled'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: `Invalid status. Must be one of: ${validStatuses.join(', ')}`,
      });
    }

    const result = await pool.query(
      'UPDATE prescriptions SET status = $1 WHERE prescription_id = $2 RETURNING *',
      [status, prescriptionId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Prescription not found',
      });
    }

    res.json({
      success: true,
      prescription: result.rows[0],
    });
  } catch (err) {
    console.error("❌ Error updating prescription status:", err.message);
    res.status(500).json({
      success: false,
      message: "Failed to update prescription status",
      error: err.message,
    });
  }
};

// In controllers/adminController.js, update the verifyDoctor and verifyPharmacy methods:

// ==================== VERIFY DOCTOR ====================
exports.verifyDoctor = async (req, res) => {
  const { doctorId } = req.params;
  const { isVerified, notes } = req.body;
  const adminId = req.user.user_id;

  console.log(`✅ Verifying doctor ${doctorId}: ${isVerified ? 'verified' : 'unverified'}`);
  console.log(`   Admin ID: ${adminId} (${typeof adminId})`);

  try {
    const result = await AdminModel.verifyDoctor(doctorId, isVerified, adminId, notes);
    res.json(result);
  } catch (err) {
    console.error("❌ Error verifying doctor:", err.message);
    res.status(500).json({
      success: false,
      message: "Failed to verify doctor",
      error: err.message,
    });
  }
};

// ==================== VERIFY PHARMACY ====================
exports.verifyPharmacy = async (req, res) => {
  const { pharmacyId } = req.params;
  const { isVerified, notes } = req.body;
  const adminId = req.user.user_id;

  console.log(`🏪 Verifying pharmacy ${pharmacyId}: ${isVerified ? 'verified' : 'unverified'}`);
  console.log(`   Admin ID: ${adminId} (${typeof adminId})`);

  try {
    const result = await AdminModel.verifyPharmacy(pharmacyId, isVerified, adminId, notes);
    res.json(result);
  } catch (err) {
    console.error("❌ Error verifying pharmacy:", err.message);
    res.status(500).json({
      success: false,
      message: "Failed to verify pharmacy",
      error: err.message,
    });
  }
};

// ==================== GET ANALYTICS ====================
exports.getAnalytics = async (req, res) => {
  console.log("📊 Fetching system analytics...");

  try {
    const result = await AdminModel.getAnalytics();
    res.json(result);
  } catch (err) {
    console.error("❌ Error fetching analytics:", err.message);
    res.status(500).json({
      success: false,
      message: "Failed to fetch analytics",
      error: err.message,
    });
  }
};

// ==================== GET DISPUTES ====================
exports.getAllDisputes = async (req, res) => {
  console.log("⚖️ Fetching all disputes...");

  try {
    const { page, limit, status, type } = req.query;
    const options = {
      page: parseInt(page) || 1,
      limit: parseInt(limit) || 20,
      status: status || null,
      type: type || null,
    };

    const result = await AdminModel.getAllDisputes(options);
    res.json(result);
  } catch (err) {
    console.error("❌ Error fetching disputes:", err.message);
    res.status(500).json({
      success: false,
      message: "Failed to fetch disputes",
      error: err.message,
    });
  }
};

// ==================== CREATE DISPUTE ====================
exports.createDispute = async (req, res) => {
  const { disputeType, relatedId, description, priority } = req.body;
  const userId = req.user.user_id;

  console.log(`⚖️ Creating dispute for user ${userId}: ${disputeType}`);

  try {
    const result = await AdminModel.createDispute({
      userId,
      disputeType,
      relatedId,
      description,
      priority: priority || 'medium',
    });
    res.json(result);
  } catch (err) {
    console.error("❌ Error creating dispute:", err.message);
    res.status(500).json({
      success: false,
      message: "Failed to create dispute",
      error: err.message,
    });
  }
};

// ==================== UPDATE DISPUTE STATUS ====================
exports.updateDisputeStatus = async (req, res) => {
  const { disputeId } = req.params;
  const { status, resolutionNotes } = req.body;
  const adminId = req.user.user_id;

  console.log(`🔄 Updating dispute ${disputeId} status to: ${status}`);

  try {
    const validStatuses = ['pending', 'investigating', 'resolved', 'dismissed'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: `Invalid status. Must be one of: ${validStatuses.join(', ')}`,
      });
    }

    const result = await AdminModel.updateDisputeStatus(disputeId, status, adminId, resolutionNotes);
    res.json(result);
  } catch (err) {
    console.error("❌ Error updating dispute status:", err.message);
    res.status(500).json({
      success: false,
      message: "Failed to update dispute status",
      error: err.message,
    });
  }
};

// ==================== DEACTIVATE/ACTIVATE USER ====================
exports.deactivateUser = async (req, res) => {
  const { userId } = req.params;
  const { isActive } = req.body;
  console.log(`🔘 Setting user ${userId} active status to: ${isActive}`);

  try {
    const result = await AdminModel.setUserActiveStatus(userId, isActive);
    res.json(result);
  } catch (err) {
    console.error("❌ Error updating user status:", err.message);
    res.status(500).json({
      success: false,
      message: "Failed to update user status",
      error: err.message,
    });
  }
};

// ==================== RESET USER PASSWORD (ADMIN) ====================
exports.adminResetPassword = async (req, res) => {
  const { userId } = req.params;
  const { newPassword } = req.body;
  console.log(`🔐 Admin resetting password for user ${userId}`);

  if (!newPassword || newPassword.length < 8) {
    return res.status(400).json({
      success: false,
      message: "Password must be at least 8 characters",
    });
  }

  try {
    const bcrypt = require("bcrypt");
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newPassword, salt);
    
    const result = await AdminModel.resetUserPassword(userId, hashedPassword);
    res.json(result);
  } catch (err) {
    console.error("❌ Error resetting password:", err.message);
    res.status(500).json({
      success: false,
      message: "Failed to reset password",
      error: err.message,
    });
  }
};