// =====================================================
// DOCTOR CONTROLLER
// =====================================================
// Handles HTTP requests for doctor operations
// Includes validation, error handling, and response formatting
// =====================================================

const bcrypt = require("bcrypt");
const DoctorModel = require("../models/doctorModel");

/**
 * Register a new doctor
 * POST /api/doctors/register
 * Body: { first_name, last_name, specialization, license_number, phone, 
 *         consultation_fee, experience_years, available_from, available_to,
 *         education, clinic_address, email, password, username }
 */
exports.registerDoctor = async (req, res) => {
  const {
    first_name,
    last_name,
    specialization,
    license_number,
    phone,
    consultation_fee,
    experience_years,
    available_from,
    available_to,
    education,
    clinic_address,
    email,
    password,
    username,
    user_id
  } = req.body;

  console.log("📝 Registering doctor:", first_name, last_name);

  // ================ VALIDATION ================
  if (!first_name || !last_name || !specialization || !license_number || !phone) {
    console.log("❌ Missing required fields");
    return res.status(400).json({
      success: false,
      message: "Please provide: first_name, last_name, specialization, license_number, phone"
    });
  }

  const isExistingUser = Boolean(user_id);
  if (!isExistingUser && (!email || !password || !username)) {
    console.log("❌ Missing authentication fields for new user creation");
    return res.status(400).json({
      success: false,
      message: "Please provide email, password, and username when creating a new doctor account"
    });
  }

  try {
    // ================ UNIQUENESS CHECKS ================
    if (!isExistingUser) {
      const emailExists = await DoctorModel.emailExists(email);
      if (emailExists) {
        return res.status(400).json({
          success: false,
          message: "Email already registered"
        });
      }

      const usernameExists = await DoctorModel.usernameExists(username);
      if (usernameExists) {
        return res.status(400).json({
          success: false,
          message: "Username already taken"
        });
      }
    }

    const licenseExists = await DoctorModel.licenseExists(license_number);
    if (licenseExists) {
      return res.status(400).json({
        success: false,
        message: "License number already registered"
      });
    }

    const phoneExists = await DoctorModel.phoneExists(phone);
    if (phoneExists) {
      return res.status(400).json({
        success: false,
        message: "Phone number already registered"
      });
    }

    // ================ CREATE DOCTOR ================
    const doctorData = {
      first_name,
      last_name,
      specialization,
      license_number,
      phone,
      consultation_fee,
      experience_years,
      available_from,
      available_to,
      education,
      clinic_address
    };

    let userData;
    if (isExistingUser) {
      userData = { user_id };
    } else {
      const saltRounds = 10;
      const hashedPassword = await bcrypt.hash(password, saltRounds);
      userData = {
        username,
        email,
        password_hash: hashedPassword
      };
    }

    const newDoctor = await DoctorModel.create(doctorData, userData);

    console.log("✅ Doctor registered successfully:", first_name, last_name);
    res.status(201).json({
      success: true,
      message: "Doctor registered successfully",
      doctor: newDoctor
    });

  } catch (err) {
    console.error("❌ ERROR REGISTERING DOCTOR:");
    console.error("Message:", err.message);
    console.error("Stack:", err.stack);
    
    res.status(500).json({
      success: false,
      message: "Server error while registering doctor",
      error: err.message
    });
  }
};

/**
 * Get doctor by ID
 * GET /api/doctors/id/:doctorId
 */
exports.getDoctorById = async (req, res) => {
  const { doctorId } = req.params;

  console.log("🔍 Fetching doctor details for ID:", doctorId);

  try {
    const doctor = await DoctorModel.findById(doctorId);

    if (!doctor) {
      console.log("❌ Doctor not found for ID:", doctorId);
      return res.status(404).json({
        success: false,
        message: "Doctor not found"
      });
    }

    console.log("✅ Doctor details found for ID:", doctorId);
    res.status(200).json({
      success: true,
      message: "Doctor details retrieved successfully",
      doctor
    });
  } catch (err) {
    console.error("❌ ERROR GETTING DOCTOR DETAILS:", err.message);
    res.status(500).json({
      success: false,
      message: "Server error while fetching doctor details",
      error: err.message
    });
  }
};

/**
 * Get doctor by email
 * GET /api/doctors/email/:email
 */
exports.getDoctorByEmail = async (req, res) => {
  const { email } = req.params;

  console.log("🔍 Fetching doctor details for email:", email);

  try {
    const doctor = await DoctorModel.findByEmail(email);

    if (!doctor) {
      console.log("❌ Doctor not found for email:", email);
      return res.status(404).json({
        success: false,
        message: "Doctor not found"
      });
    }

    console.log("✅ Doctor details found for email:", email);
    res.status(200).json({
      success: true,
      message: "Doctor details retrieved successfully",
      doctor
    });
  } catch (err) {
    console.error("❌ ERROR GETTING DOCTOR BY EMAIL:", err.message);
    res.status(500).json({
      success: false,
      message: "Server error while fetching doctor",
      error: err.message
    });
  }
};

/**
 * Get all doctors
 * GET /api/doctors
 */
exports.getAllDoctors = async (req, res) => {
  console.log("🔍 Fetching all doctors");

  try {
    const doctors = await DoctorModel.findAll();

    console.log(`✅ Found ${doctors.length} doctors`);
    res.status(200).json({
      success: true,
      message: "Doctors retrieved successfully",
      doctors,
      count: doctors.length
    });
  } catch (err) {
    console.error("❌ ERROR GETTING ALL DOCTORS:", err.message);
    res.status(500).json({
      success: false,
      message: "Server error while fetching doctors",
      error: err.message
    });
  }
};

/**
 * Update doctor details
 * PUT /api/doctors/:doctorId
 */
exports.updateDoctor = async (req, res) => {
  const { doctorId } = req.params;
  const updateData = req.body;

  console.log("✏️ Updating doctor details for ID:", doctorId);

  try {
    // Check if doctor exists
    const existingDoctor = await DoctorModel.findById(doctorId);
    if (!existingDoctor) {
      console.log("❌ Doctor not found for ID:", doctorId);
      return res.status(404).json({
        success: false,
        message: "Doctor not found"
      });
    }

    // Check uniqueness for updated fields
    if (updateData.phone && updateData.phone !== existingDoctor.phone) {
      const phoneExists = await DoctorModel.phoneExists(updateData.phone);
      if (phoneExists) {
        return res.status(400).json({
          success: false,
          message: "Phone number already registered"
        });
      }
    }

    if (updateData.license_number && updateData.license_number !== existingDoctor.license_number) {
      const licenseExists = await DoctorModel.licenseExists(updateData.license_number);
      if (licenseExists) {
        return res.status(400).json({
          success: false,
          message: "License number already registered"
        });
      }
    }

    const updatedDoctor = await DoctorModel.update(doctorId, updateData);

    console.log("✅ Doctor details updated for ID:", doctorId);
    res.status(200).json({
      success: true,
      message: "Doctor details updated successfully",
      doctor: updatedDoctor
    });
  } catch (err) {
    console.error("❌ ERROR UPDATING DOCTOR:", err.message);
    
    res.status(500).json({
      success: false,
      message: "Server error while updating doctor",
      error: err.message
    });
  }
};

/**
 * Delete doctor
 * DELETE /api/doctors/:doctorId
 */
exports.deleteDoctor = async (req, res) => {
  const { doctorId } = req.params;

  console.log("🗑️ Deleting doctor with ID:", doctorId);

  try {
    await DoctorModel.delete(doctorId);

    console.log("✅ Doctor deleted successfully with ID:", doctorId);
    res.status(200).json({
      success: true,
      message: "Doctor deleted successfully"
    });
  } catch (err) {
    console.error("❌ ERROR DELETING DOCTOR:", err.message);
    
    if (err.message === 'Doctor not found') {
      return res.status(404).json({
        success: false,
        message: "Doctor not found"
      });
    }
    
    res.status(500).json({
      success: false,
      message: "Server error while deleting doctor",
      error: err.message
    });
  }
};

/**
 * Get doctors by specialization
 * GET /api/doctors/specialization/:specialization
 */
exports.getDoctorsBySpecialization = async (req, res) => {
  const { specialization } = req.params;

  console.log("🔍 Fetching doctors by specialization:", specialization);

  try {
    const doctors = await DoctorModel.findBySpecialization(specialization);

    console.log(`✅ Found ${doctors.length} doctors with specialization:`, specialization);
    res.status(200).json({
      success: true,
      message: "Doctors retrieved successfully",
      doctors,
      count: doctors.length
    });
  } catch (err) {
    console.error("❌ ERROR GETTING DOCTORS BY SPECIALIZATION:", err.message);
    res.status(500).json({
      success: false,
      message: "Server error while fetching doctors",
      error: err.message
    });
  }
};