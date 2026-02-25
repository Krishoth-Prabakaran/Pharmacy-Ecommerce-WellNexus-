const express = require("express");
const router = express.Router();
const patientController = require("../controllers/patientController");

// ==================== PATIENT ROUTES ====================

// POST /api/patients/details - Save patient details
// Body: { user_id, first_name, last_name, phone, date_of_birth, gender }
router.post("/details", patientController.savePatientDetails);

// GET /api/patients?email=xxx&user_id=xxx - Get patient details by email or user_id
router.get("/", patientController.getPatientDetails);

// GET /api/patients/phone/:phone - Get patient by phone number
router.get("/phone/:phone", patientController.getPatientByPhone);

// PUT /api/patients/:user_id - Update patient details by user_id
router.put("/:user_id", patientController.updatePatientDetails);

// GET /api/patients/:userId/check - Check if patient has details (FIXED: now uses userId)
router.get("/:userId/check", patientController.checkPatientDetails);

module.exports = router;