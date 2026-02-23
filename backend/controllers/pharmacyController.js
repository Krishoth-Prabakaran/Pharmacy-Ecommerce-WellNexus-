const bcrypt = require("bcrypt");
const PharmacyModel = require("../models/pharmacyModel");

// ==================== REGISTER PHARMACY ====================
exports.registerPharmacy = async (req, res) => {
  const {
    pharmacy_name,
    address,
    phone,
    latitude,
    longitude,
    open_time,
    close_time,
    email,
    password,
    username
  } = req.body;

  console.log("Registering pharmacy:", pharmacy_name);

  // Basic validation
  if (!pharmacy_name || !address || !phone || !email || !password || !username) {
    console.log("Missing required fields");
    return res.status(400).json({
      success: false,
      message: "Please provide pharmacy_name, address, phone, email, password, and username"
    });
  }

  try {
    // Check if email already exists
    const emailExists = await PharmacyModel.emailExists(email);
    if (emailExists) {
      return res.status(400).json({
        success: false,
        message: "Email already registered"
      });
    }

    // Check if username already exists
    const usernameExists = await PharmacyModel.usernameExists(username);
    if (usernameExists) {
      return res.status(400).json({
        success: false,
        message: "Username already taken"
      });
    }

    // Check if phone already exists
    const phoneExists = await PharmacyModel.phoneExists(phone);
    if (phoneExists) {
      return res.status(400).json({
        success: false,
        message: "Phone number already registered"
      });
    }

    // Hash password
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    // Create pharmacy
    const pharmacyData = {
      pharmacy_name,
      address,
      phone,
      latitude,
      longitude,
      open_time,
      close_time
    };

    const userData = {
      username,
      email,
      password_hash: hashedPassword
    };

    const newPharmacy = await PharmacyModel.create(pharmacyData, userData);

    console.log("Pharmacy registered successfully:", pharmacy_name);
    res.status(201).json({
      success: true,
      message: "Pharmacy registered successfully",
      pharmacy: newPharmacy
    });

  } catch (err) {
    console.error("ERROR REGISTERING PHARMACY:");
    console.error("Message:", err.message);
    console.error("Stack:", err.stack);
    
    res.status(500).json({
      success: false,
      message: "Server error while registering pharmacy",
      error: err.message
    });
  }
};

// ==================== GET PHARMACY BY ID ====================
exports.getPharmacyById = async (req, res) => {
  const { pharmacyId } = req.params;

  console.log("Fetching pharmacy details for ID:", pharmacyId);

  try {
    const pharmacy = await PharmacyModel.findById(pharmacyId);

    if (!pharmacy) {
      console.log("Pharmacy not found for ID:", pharmacyId);
      return res.status(404).json({
        success: false,
        message: "Pharmacy not found"
      });
    }

    console.log("Pharmacy details found for ID:", pharmacyId);
    res.status(200).json({
      success: true,
      message: "Pharmacy details retrieved successfully",
      pharmacy
    });
  } catch (err) {
    console.error("ERROR GETTING PHARMACY DETAILS:");
    console.error("Message:", err.message);
    res.status(500).json({
      success: false,
      message: "Server error while fetching pharmacy details",
      error: err.message
    });
  }
};

// ==================== GET PHARMACY BY EMAIL ====================
exports.getPharmacyByEmail = async (req, res) => {
  const { email } = req.params;

  console.log("Fetching pharmacy details for email:", email);

  try {
    const pharmacy = await PharmacyModel.findByEmail(email);

    if (!pharmacy) {
      console.log("Pharmacy not found for email:", email);
      return res.status(404).json({
        success: false,
        message: "Pharmacy not found"
      });
    }

    console.log("Pharmacy details found for email:", email);
    res.status(200).json({
      success: true,
      message: "Pharmacy details retrieved successfully",
      pharmacy
    });
  } catch (err) {
    console.error("ERROR GETTING PHARMACY BY EMAIL:");
    console.error("Message:", err.message);
    res.status(500).json({
      success: false,
      message: "Server error while fetching pharmacy",
      error: err.message
    });
  }
};

// ==================== GET ALL PHARMACIES ====================
exports.getAllPharmacies = async (req, res) => {
  console.log("Fetching all pharmacies");

  try {
    const pharmacies = await PharmacyModel.findAll();

    console.log(`Found ${pharmacies.length} pharmacies`);
    res.status(200).json({
      success: true,
      message: "Pharmacies retrieved successfully",
      pharmacies,
      count: pharmacies.length
    });
  } catch (err) {
    console.error("ERROR GETTING ALL PHARMACIES:");
    console.error("Message:", err.message);
    res.status(500).json({
      success: false,
      message: "Server error while fetching pharmacies",
      error: err.message
    });
  }
};

// ==================== UPDATE PHARMACY ====================
exports.updatePharmacy = async (req, res) => {
  const { pharmacyId } = req.params;
  const updateData = req.body;

  console.log("Updating pharmacy details for ID:", pharmacyId);

  try {
    // Check if pharmacy exists
    const existingPharmacy = await PharmacyModel.findById(pharmacyId);
    if (!existingPharmacy) {
      console.log("Pharmacy not found for ID:", pharmacyId);
      return res.status(404).json({
        success: false,
        message: "Pharmacy not found"
      });
    }

    // If phone is being updated, check if it's already taken
    if (updateData.phone && updateData.phone !== existingPharmacy.phone) {
      const phoneExists = await PharmacyModel.phoneExists(updateData.phone);
      if (phoneExists) {
        return res.status(400).json({
          success: false,
          message: "Phone number already registered"
        });
      }
    }

    const updatedPharmacy = await PharmacyModel.update(pharmacyId, updateData);

    console.log("Pharmacy details updated for ID:", pharmacyId);
    res.status(200).json({
      success: true,
      message: "Pharmacy details updated successfully",
      pharmacy: updatedPharmacy
    });
  } catch (err) {
    console.error("ERROR UPDATING PHARMACY:");
    console.error("Message:", err.message);
    
    res.status(500).json({
      success: false,
      message: "Server error while updating pharmacy",
      error: err.message
    });
  }
};

// ==================== DELETE PHARMACY ====================
exports.deletePharmacy = async (req, res) => {
  const { pharmacyId } = req.params;

  console.log("Deleting pharmacy with ID:", pharmacyId);

  try {
    await PharmacyModel.delete(pharmacyId);

    console.log("Pharmacy deleted successfully with ID:", pharmacyId);
    res.status(200).json({
      success: true,
      message: "Pharmacy deleted successfully"
    });
  } catch (err) {
    console.error("ERROR DELETING PHARMACY:");
    console.error("Message:", err.message);
    
    if (err.message === 'Pharmacy not found') {
      return res.status(404).json({
        success: false,
        message: "Pharmacy not found"
      });
    }
    
    res.status(500).json({
      success: false,
      message: "Server error while deleting pharmacy",
      error: err.message
    });
  }
};

// ==================== GET NEARBY PHARMACIES ====================
exports.getNearbyPharmacies = async (req, res) => {
  const { latitude, longitude, radius = 10 } = req.query;

  console.log("Finding nearby pharmacies");

  if (!latitude || !longitude) {
    return res.status(400).json({
      success: false,
      message: "Please provide latitude and longitude"
    });
  }

  try {
    const pharmacies = await PharmacyModel.findNearby(latitude, longitude, radius);

    console.log(`Found ${pharmacies.length} nearby pharmacies`);
    res.status(200).json({
      success: true,
      message: "Nearby pharmacies retrieved successfully",
      pharmacies,
      count: pharmacies.length
    });
  } catch (err) {
    console.error("ERROR GETTING NEARBY PHARMACIES:");
    console.error("Message:", err.message);
    res.status(500).json({
      success: false,
      message: "Server error while finding nearby pharmacies",
      error: err.message
    });
  }
};

// ==================== GET PHARMACY BY PHONE ====================
exports.getPharmacyByPhone = async (req, res) => {
  const { phone } = req.params;

  console.log("Fetching pharmacy details for phone:", phone);

  try {
    const pharmacy = await PharmacyModel.findByPhone(phone);

    if (!pharmacy) {
      console.log("Pharmacy not found for phone:", phone);
      return res.status(404).json({
        success: false,
        message: "Pharmacy not found"
      });
    }

    console.log("Pharmacy details found for phone:", phone);
    res.status(200).json({
      success: true,
      message: "Pharmacy details retrieved successfully",
      pharmacy
    });
  } catch (err) {
    console.error("ERROR GETTING PHARMACY BY PHONE:");
    console.error("Message:", err.message);
    res.status(500).json({
      success: false,
      message: "Server error while fetching pharmacy",
      error: err.message
    });
  }
};