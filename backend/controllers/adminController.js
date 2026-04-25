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

// ==================== GET ALL APPOINTMENTS ====================
exports.getAllAppointments = async (req, res) => {
  console.log("📅 Fetching all appointments...");

  try {
    const { page, limit, status } = req.query;
    const options = {
      page: parseInt(page) || 1,
      limit: parseInt(limit) || 20,
      status: status || null,
    };

    const result = await AdminModel.getAllAppointments(options);
    res.json(result);
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
    const { page, limit, status } = req.query;
    const options = {
      page: parseInt(page) || 1,
      limit: parseInt(limit) || 20,
      status: status || null,
    };

    const result = await AdminModel.getAllPrescriptions(options);
    res.json(result);
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
    // Validate role
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

// ==================== GET PHARMACIES ====================
exports.getAllPharmacies = async (req, res) => {
  console.log("🏪 Fetching all pharmacies...");

  try {
    const { page = 1, limit = 20, search = null } = req.query;
    const offset = (page - 1) * limit;
    let params = [];
    let paramCount = 1;

    let whereClause = '';
    if (search) {
      whereClause = `WHERE name ILIKE $${paramCount} OR location ILIKE $${paramCount} OR phone ILIKE $${paramCount}`;
      params.push(`%${search}%`);
      paramCount++;
    }

    const [pharmaciesResult, countResult] = await Promise.all([
      pool.query(
        `SELECT * FROM pharmacies 
         ${whereClause}
         ORDER BY pharmacy_id DESC 
         LIMIT $${paramCount} OFFSET $${paramCount + 1}`,
        [...params, parseInt(limit), offset]
      ),
      pool.query(`SELECT COUNT(*) as total FROM pharmacies ${whereClause}`, params),
    ]);

    res.json({
      success: true,
      pharmacies: pharmaciesResult.rows,
      pagination: {
        currentPage: parseInt(page),
        totalPages: Math.ceil(countResult.rows[0].total / limit),
        totalPharmacies: countResult.rows[0].total,
        hasNext: page * limit < countResult.rows[0].total,
        hasPrev: page > 1,
      },
    });
  } catch (err) {
    console.error("❌ Error fetching pharmacies:", err.message);
    res.status(500).json({
      success: false,
      message: "Failed to fetch pharmacies",
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
                ph.name as pharmacy_name
         FROM orders o
         LEFT JOIN patients p ON o.patient_id = p.patient_id
         LEFT JOIN pharmacies ph ON o.pharmacy_id = ph.pharmacy_id
         ${whereClause}
         ORDER BY o.created_at DESC
         LIMIT $${paramCount} OFFSET $${paramCount + 1}`,
        [...params, parseInt(limit), offset]
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

// ==================== VERIFY DOCTOR ====================
exports.verifyDoctor = async (req, res) => {
  const { doctorId } = req.params;
  const { isVerified, notes } = req.body;
  const adminId = req.user.user_id;

  console.log(`✅ Verifying doctor ${doctorId}: ${isVerified ? 'verified' : 'unverified'}`);

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