// =====================================================
// PRESCRIPTION CONTROLLER
// =====================================================
// Handles HTTP requests for prescription operations
// Includes validation, error handling, and response formatting
// =====================================================

const PrescriptionModel = require("../models/prescriptionModel");
const Validators = require("../utils/validators");

/**
 * Create a new prescription
 * POST /api/prescriptions
 * Body: { patient_id, doctor_name, prescription_date, valid_until, status, medicine_name, doctor_license, items: [{variant_id, dosage, duration_days}] }
 */
exports.createPrescription = async (req, res) => {
  const {
    patient_id,
    doctor_name,
    prescription_date,
    valid_until,
    status,
    medicine_name,
    doctor_license,
    items
  } = req.body;

  console.log("📝 Creating prescription for patient:", patient_id);

  // ================ VALIDATION ================
  if (!patient_id || !doctor_name || !doctor_license) {
    console.log("❌ Missing required fields");
    return res.status(400).json({
      success: false,
      message: "Please provide: patient_id, doctor_name, doctor_license"
    });
  }

  // Validate doctor name
  const doctorNameValidation = Validators.validateName(doctor_name, 'Doctor name');
  if (!doctorNameValidation.valid) {
    return res.status(400).json({ success: false, message: doctorNameValidation.message });
  }

  // Validate dates if provided
  if (prescription_date) {
    const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
    if (!dateRegex.test(prescription_date)) {
      return res.status(400).json({
        success: false,
        message: "Prescription date must be in YYYY-MM-DD format"
      });
    }
  }

  if (valid_until) {
    const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
    if (!dateRegex.test(valid_until)) {
      return res.status(400).json({
        success: false,
        message: "Valid until date must be in YYYY-MM-DD format"
      });
    }
  }

  // Validate status if provided
  if (status && !['active', 'inactive', 'expired'].includes(status.toLowerCase())) {
    return res.status(400).json({ success: false, message: "Status must be 'active', 'inactive', or 'expired'" });
  }

  // Validate items if provided
  if (items && Array.isArray(items)) {
    for (const item of items) {
      if (!item.variant_id || !item.dosage || !item.duration_days) {
        return res.status(400).json({
          success: false,
          message: "Each prescription item must have variant_id, dosage, and duration_days"
        });
      }
      if (item.duration_days <= 0) {
        return res.status(400).json({
          success: false,
          message: "Duration days must be greater than 0"
        });
      }
    }
  }

  try {
    const prescriptionData = {
      patient_id,
      doctor_name,
      prescription_date,
      valid_until,
      status: status?.toLowerCase() || 'active',
      medicine_name,
      doctor_license,
      items: items || []
    };

    const prescription = await PrescriptionModel.create(prescriptionData);

    console.log("✅ Prescription created successfully:", prescription.prescription_id);

    res.status(201).json({
      success: true,
      message: "Prescription created successfully",
      prescription: {
        prescription_id: prescription.prescription_id,
        patient_id: prescription.patient_id,
        doctor_name: prescription.doctor_name,
        prescription_date: prescription.prescription_date,
        valid_until: prescription.valid_until,
        sms_code: prescription.sms_code,
        status: prescription.status,
        medicine_name: prescription.medicine_name,
        doctor_license: prescription.doctor_license
      }
    });

  } catch (error) {
    console.error("❌ Error creating prescription:", error);

    if (error.code === '23503') { // Foreign key violation
      return res.status(400).json({
        success: false,
        message: "Invalid patient ID or doctor license"
      });
    }

    res.status(500).json({
      success: false,
      message: "Failed to create prescription",
      error: error.message
    });
  }
};

/**
 * Get prescription by ID
 * GET /api/prescriptions/:id
 */
exports.getPrescription = async (req, res) => {
  const { id } = req.params;

  try {
    const prescription = await PrescriptionModel.getById(parseInt(id));

    if (!prescription) {
      return res.status(404).json({
        success: false,
        message: "Prescription not found"
      });
    }

    res.json({
      success: true,
      prescription
    });

  } catch (error) {
    console.error("❌ Error fetching prescription:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch prescription",
      error: error.message
    });
  }
};

/**
 * Get prescriptions by doctor
 * GET /api/prescriptions/doctor/:doctorLicense
 */
exports.getPrescriptionsByDoctor = async (req, res) => {
  const { doctorLicense } = req.params;

  try {
    const prescriptions = await PrescriptionModel.getByDoctor(parseInt(doctorLicense));

    res.json({
      success: true,
      prescriptions
    });

  } catch (error) {
    console.error("❌ Error fetching prescriptions by doctor:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch prescriptions",
      error: error.message
    });
  }
};

/**
 * Get prescriptions by patient
 * GET /api/prescriptions/patient/:patientId
 */
exports.getPrescriptionsByPatient = async (req, res) => {
  const { patientId } = req.params;

  try {
    const prescriptions = await PrescriptionModel.getByPatient(parseInt(patientId));

    res.json({
      success: true,
      prescriptions
    });

  } catch (error) {
    console.error("❌ Error fetching prescriptions by patient:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch prescriptions",
      error: error.message
    });
  }
};

/**
 * Update prescription status
 * PUT /api/prescriptions/:id/status
 * Body: { status }
 */
exports.updatePrescriptionStatus = async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;

  if (!status || !['active', 'inactive', 'expired'].includes(status.toLowerCase())) {
    return res.status(400).json({
      success: false,
      message: "Status must be 'active', 'inactive', or 'expired'"
    });
  }

  try {
    const prescription = await PrescriptionModel.updateStatus(parseInt(id), status.toLowerCase());

    if (!prescription) {
      return res.status(404).json({
        success: false,
        message: "Prescription not found"
      });
    }

    res.json({
      success: true,
      message: "Prescription status updated successfully",
      prescription
    });

  } catch (error) {
    console.error("❌ Error updating prescription status:", error);
    res.status(500).json({
      success: false,
      message: "Failed to update prescription status",
      error: error.message
    });
  }
};

/**
 * Delete prescription
 * DELETE /api/prescriptions/:id
 */
exports.deletePrescription = async (req, res) => {
  const { id } = req.params;

  try {
    await PrescriptionModel.delete(parseInt(id));

    res.json({
      success: true,
      message: "Prescription deleted successfully"
    });

  } catch (error) {
    console.error("❌ Error deleting prescription:", error);
    res.status(500).json({
      success: false,
      message: "Failed to delete prescription",
      error: error.message
    });
  }
};