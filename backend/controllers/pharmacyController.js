const bcrypt = require("bcrypt");
const pool = require("../config/db");
const PharmacyModel = require("../models/pharmacyModel");
const Validators = require("../utils/validators");

// ==================== REGISTER PHARMACY ====================
exports.registerPharmacy = async (req, res) => {
  const {
    pharmacy_name,
    branches, // Array of branch objects
    email,
    password,
    username
  } = req.body;

  console.log("Registering pharmacy:", pharmacy_name);

  // Basic validation
  if (!pharmacy_name || !email || !username) {
    console.log("Missing required fields");
    return res.status(400).json({
      success: false,
      message: "Please provide pharmacy_name, email, and username"
    });
  }

  // Validate pharmacy name
  const pharmacyNameValidation = Validators.validateTextField(pharmacy_name, 'Pharmacy name', 2, 100);
  if (!pharmacyNameValidation.valid) {
    return res.status(400).json({ success: false, message: pharmacyNameValidation.message });
  }

  // Validate branches
  if (!branches || !Array.isArray(branches) || branches.length === 0) {
    return res.status(400).json({
      success: false,
      message: "At least one branch is required"
    });
  }

  for (let i = 0; i < branches.length; i++) {
    const branch = branches[i];

    if (!branch.address || !branch.phone) {
      return res.status(400).json({
        success: false,
        message: `Branch ${i + 1}: address and phone are required`
      });
    }

    // Validate address
    const addressValidation = Validators.validateTextField(branch.address, `Branch ${i + 1} address`, 5, 255);
    if (!addressValidation.valid) {
      return res.status(400).json({ success: false, message: addressValidation.message });
    }

    // Validate phone number
    const phoneValidation = Validators.validatePhoneNumber(branch.phone);
    if (!phoneValidation.valid) {
      return res.status(400).json({ success: false, message: phoneValidation.message });
    }

    // Validate latitude if provided
    if (branch.latitude) {
      const latValidation = Validators.validateLatitude(branch.latitude);
      if (!latValidation.valid) {
        return res.status(400).json({ success: false, message: latValidation.message });
      }
    }

    // Validate longitude if provided
    if (branch.longitude) {
      const lonValidation = Validators.validateLongitude(branch.longitude);
      if (!lonValidation.valid) {
        return res.status(400).json({ success: false, message: lonValidation.message });
      }
    }
  }

  // Validate email format
  const emailValidation = Validators.validateEmail(email);
  if (!emailValidation.valid) {
    return res.status(400).json({ success: false, message: emailValidation.message });
  }

  // Validate username
  const usernameValidation = Validators.validateUsername(username);
  if (!usernameValidation.valid) {
    return res.status(400).json({ success: false, message: usernameValidation.message });
  }

  try {
    let existingUser = null;

    if (req.body.user_id) {
      const userResult = await pool.query(
        'SELECT user_id, username, email, role, email_verified FROM users WHERE user_id = $1',
        [req.body.user_id]
      );
      existingUser = userResult.rows[0];
    } else if (email) {
      const userResult = await pool.query(
        'SELECT user_id, username, email, role, email_verified FROM users WHERE email = $1',
        [email.toLowerCase()]
      );
      existingUser = userResult.rows[0];
    }

    if (existingUser) {
      if (existingUser.role !== 'pharmacist') {
        return res.status(400).json({
          success: false,
          message: 'Existing account is not a pharmacist account'
        });
      }

      if (!existingUser.email_verified) {
        return res.status(400).json({
          success: false,
          message: 'Please verify your email before registering pharmacy details'
        });
      }
    }

    // Check if any branch phone already exists
    for (const branch of branches) {
      const phoneExists = await PharmacyModel.phoneExists(branch.phone);
      if (phoneExists) {
        return res.status(400).json({
          success: false,
          message: `Phone number ${branch.phone} already registered`
        });
      }
    }

    const pharmacyData = { pharmacy_name };

    let newPharmacy;
    if (existingUser) {
      const userData = {
        user_id: existingUser.user_id,
        username: existingUser.username,
        email: existingUser.email,
        role: existingUser.role
      };
      newPharmacy = await PharmacyModel.create(pharmacyData, userData, branches);
    } else {
      if (!password) {
        return res.status(400).json({
          success: false,
          message: 'Password is required for new account creation'
        });
      }

      // Validate password strength
      const passwordValidation = Validators.validatePassword(password);
      if (!passwordValidation.valid) {
        return res.status(400).json({ success: false, message: passwordValidation.message });
      }

      const emailExists = await PharmacyModel.emailExists(email);
      if (emailExists) {
        return res.status(400).json({
          success: false,
          message: 'Email already registered'
        });
      }

      const usernameExists = await PharmacyModel.usernameExists(username);
      if (usernameExists) {
        return res.status(400).json({
          success: false,
          message: 'Username already taken'
        });
      }

      const saltRounds = 10;
      const hashedPassword = await bcrypt.hash(password, saltRounds);

      const userData = {
        username,
        email,
        password_hash: hashedPassword,
        role: 'pharmacist'
      };
      newPharmacy = await PharmacyModel.create(pharmacyData, userData, branches);
    }

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

    // Validate branches if provided
    if (updateData.branches && Array.isArray(updateData.branches)) {
      for (let i = 0; i < updateData.branches.length; i++) {
        const branch = updateData.branches[i];

        if (!branch.address || !branch.phone) {
          return res.status(400).json({
            success: false,
            message: `Branch ${i + 1}: address and phone are required`
          });
        }

        // Validate address
        const addressValidation = Validators.validateTextField(branch.address, `Branch ${i + 1} address`, 5, 255);
        if (!addressValidation.valid) {
          return res.status(400).json({ success: false, message: addressValidation.message });
        }

        // Validate phone number
        const phoneValidation = Validators.validatePhoneNumber(branch.phone);
        if (!phoneValidation.valid) {
          return res.status(400).json({ success: false, message: phoneValidation.message });
        }

        // Check if phone is already taken by another branch
        const existingPhones = existingPharmacy.branches
          .filter(b => b.branch_id !== branch.branch_id)
          .map(b => b.phone);

        if (existingPhones.includes(branch.phone)) {
          return res.status(400).json({
            success: false,
            message: `Phone number ${branch.phone} already used by another branch`
          });
        }

        // Validate latitude if provided
        if (branch.latitude) {
          const latValidation = Validators.validateLatitude(branch.latitude);
          if (!latValidation.valid) {
            return res.status(400).json({ success: false, message: latValidation.message });
          }
        }

        // Validate longitude if provided
        if (branch.longitude) {
          const lonValidation = Validators.validateLongitude(branch.longitude);
          if (!lonValidation.valid) {
            return res.status(400).json({ success: false, message: lonValidation.message });
          }
        }
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

// ==================== BRANCH MANAGEMENT ====================

// ==================== CREATE BRANCH ====================
exports.createBranch = async (req, res) => {
  const { pharmacyId } = req.params;
  const branchData = req.body;

  console.log("Creating branch for pharmacy ID:", pharmacyId);

  // Validation
  if (!branchData.address || !branchData.phone) {
    return res.status(400).json({
      success: false,
      message: "Address and phone are required"
    });
  }

  // Validate address
  const addressValidation = Validators.validateTextField(branchData.address, 'Address', 5, 255);
  if (!addressValidation.valid) {
    return res.status(400).json({ success: false, message: addressValidation.message });
  }

  // Validate phone number
  const phoneValidation = Validators.validatePhoneNumber(branchData.phone);
  if (!phoneValidation.valid) {
    return res.status(400).json({ success: false, message: phoneValidation.message });
  }

  // Validate latitude if provided
  if (branchData.latitude) {
    const latValidation = Validators.validateLatitude(branchData.latitude);
    if (!latValidation.valid) {
      return res.status(400).json({ success: false, message: latValidation.message });
    }
  }

  // Validate longitude if provided
  if (branchData.longitude) {
    const lonValidation = Validators.validateLongitude(branchData.longitude);
    if (!lonValidation.valid) {
      return res.status(400).json({ success: false, message: lonValidation.message });
    }
  }

  try {
    // Check if pharmacy exists
    const pharmacy = await PharmacyModel.findById(pharmacyId);
    if (!pharmacy) {
      return res.status(404).json({
        success: false,
        message: "Pharmacy not found"
      });
    }

    // Check if phone already exists
    const phoneExists = await PharmacyModel.phoneExists(branchData.phone);
    if (phoneExists) {
      return res.status(400).json({
        success: false,
        message: "Phone number already registered"
      });
    }

    const newBranch = await PharmacyModel.createBranch(pharmacyId, branchData);

    console.log("Branch created successfully for pharmacy ID:", pharmacyId);
    res.status(201).json({
      success: true,
      message: "Branch created successfully",
      branch: newBranch
    });
  } catch (err) {
    console.error("ERROR CREATING BRANCH:");
    console.error("Message:", err.message);
    res.status(500).json({
      success: false,
      message: "Server error while creating branch",
      error: err.message
    });
  }
};

// ==================== UPDATE BRANCH ====================
exports.updateBranch = async (req, res) => {
  const { branchId } = req.params;
  const branchData = req.body;

  console.log("Updating branch ID:", branchId);

  try {
    // Check if branch exists by getting all branches for the pharmacy
    const branches = await PharmacyModel.getBranchesByBranchId(branchId);
    if (!branches || branches.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Branch not found"
      });
    }

    // Validate fields if provided
    if (branchData.address) {
      const addressValidation = Validators.validateTextField(branchData.address, 'Address', 5, 255);
      if (!addressValidation.valid) {
        return res.status(400).json({ success: false, message: addressValidation.message });
      }
    }

    if (branchData.phone) {
      const phoneValidation = Validators.validatePhoneNumber(branchData.phone);
      if (!phoneValidation.valid) {
        return res.status(400).json({ success: false, message: phoneValidation.message });
      }

      // Check if phone is already taken by another branch
      const phoneExists = await PharmacyModel.phoneExists(branchData.phone);
      if (phoneExists) {
        // Check if it's the same branch
        const existingBranch = branches[0];
        if (existingBranch.phone !== branchData.phone) {
          return res.status(400).json({
            success: false,
            message: "Phone number already registered"
          });
        }
      }
    }

    if (branchData.latitude) {
      const latValidation = Validators.validateLatitude(branchData.latitude);
      if (!latValidation.valid) {
        return res.status(400).json({ success: false, message: latValidation.message });
      }
    }

    if (branchData.longitude) {
      const lonValidation = Validators.validateLongitude(branchData.longitude);
      if (!lonValidation.valid) {
        return res.status(400).json({ success: false, message: lonValidation.message });
      }
    }

    const updatedBranch = await PharmacyModel.updateBranch(branchId, branchData);

    console.log("Branch updated successfully ID:", branchId);
    res.status(200).json({
      success: true,
      message: "Branch updated successfully",
      branch: updatedBranch
    });
  } catch (err) {
    console.error("ERROR UPDATING BRANCH:");
    console.error("Message:", err.message);
    res.status(500).json({
      success: false,
      message: "Server error while updating branch",
      error: err.message
    });
  }
};

// ==================== DELETE BRANCH ====================
exports.deleteBranch = async (req, res) => {
  const { branchId } = req.params;

  console.log("Deleting branch ID:", branchId);

  try {
    // Check if branch exists and get pharmacy info
    const branches = await PharmacyModel.getBranchesByBranchId(branchId);
    if (!branches || branches.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Branch not found"
      });
    }

    const branch = branches[0];

    // Check if it's the main branch
    if (branch.is_main_branch) {
      return res.status(400).json({
        success: false,
        message: "Cannot delete main branch"
      });
    }

    // Check if this is the last branch
    const allBranches = await PharmacyModel.getBranches(branch.pharmacy_id);
    if (allBranches.length <= 1) {
      return res.status(400).json({
        success: false,
        message: "Cannot delete the last branch. Pharmacy must have at least one branch."
      });
    }

    const deletedBranch = await PharmacyModel.deleteBranch(branchId);

    console.log("Branch deleted successfully ID:", branchId);
    res.status(200).json({
      success: true,
      message: "Branch deleted successfully",
      branch: deletedBranch
    });
  } catch (err) {
    console.error("ERROR DELETING BRANCH:");
    console.error("Message:", err.message);
    res.status(500).json({
      success: false,
      message: "Server error while deleting branch",
      error: err.message
    });
  }
};

// ==================== SET MAIN BRANCH ====================
exports.setMainBranch = async (req, res) => {
  const { pharmacyId, branchId } = req.params;

  console.log("Setting main branch for pharmacy ID:", pharmacyId, "branch ID:", branchId);

  try {
    // Check if pharmacy exists
    const pharmacy = await PharmacyModel.findById(pharmacyId);
    if (!pharmacy) {
      return res.status(404).json({
        success: false,
        message: "Pharmacy not found"
      });
    }

    // Check if branch exists and belongs to this pharmacy
    const branches = await PharmacyModel.getBranches(pharmacyId);
    const branch = branches.find(b => b.branch_id == branchId);
    if (!branch) {
      return res.status(404).json({
        success: false,
        message: "Branch not found or does not belong to this pharmacy"
      });
    }

    // Update main branch
    await PharmacyModel.setMainBranch(pharmacyId, branchId);

    console.log("Main branch updated successfully for pharmacy ID:", pharmacyId);
    res.status(200).json({
      success: true,
      message: "Main branch updated successfully"
    });
  } catch (err) {
    console.error("ERROR SETTING MAIN BRANCH:");
    console.error("Message:", err.message);
    res.status(500).json({
      success: false,
      message: "Server error while setting main branch",
      error: err.message
    });
  }
};

// ==================== GET BRANCHES ====================
exports.getBranches = async (req, res) => {
  const { pharmacyId } = req.params;

  console.log("Getting branches for pharmacy ID:", pharmacyId);

  try {
    // Check if pharmacy exists
    const pharmacy = await PharmacyModel.findById(pharmacyId);
    if (!pharmacy) {
      return res.status(404).json({
        success: false,
        message: "Pharmacy not found"
      });
    }

    const branches = await PharmacyModel.getBranches(pharmacyId);

    console.log(`Found ${branches.length} branches for pharmacy ID:`, pharmacyId);
    res.status(200).json({
      success: true,
      message: "Branches retrieved successfully",
      branches,
      count: branches.length
    });
  } catch (err) {
    console.error("ERROR GETTING BRANCHES:");
    console.error("Message:", err.message);
    res.status(500).json({
      success: false,
      message: "Server error while fetching branches",
      error: err.message
    });
  }
};