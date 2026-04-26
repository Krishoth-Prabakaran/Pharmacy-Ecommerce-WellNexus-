// backend/routes/patientRoutes.js
const express = require("express");
const router = express.Router();
const patientController = require("../controllers/patientController");

// ==================== PATIENT ROUTES ====================

// POST /api/patients/details - Save patient details
// Body: { user_id, first_name, last_name, phone, date_of_birth, gender }
router.post("/details", patientController.savePatientDetails);

// GET /api/patients/dashboard/:userId - Get complete dashboard data
router.get("/dashboard/:userId", patientController.getPatientDashboard);

// GET /api/patients/phone/:phone - Get patient by phone number
router.get("/phone/:phone", patientController.getPatientByPhone);

// GET /api/patients/profile/:userId - Get patient profile
router.get("/profile/:userId", patientController.getPatientDetails);

// GET /api/patients/:userId/check - Check if patient has details
router.get("/:userId/check", patientController.checkPatientDetails);

// GET /api/patients - Get all patients (with optional search) - MUST BE AFTER SPECIFIC ROUTES
router.get("/", patientController.getAllPatients);

// POST /api/patients - Create new patient (for doctors)
router.post("/", patientController.createPatient);

// PUT /api/patients/profile/:userId - Update patient profile
router.put("/profile/:userId", patientController.updatePatientProfile);

// PUT /api/patients/:user_id - Update patient details by user_id
router.put("/:user_id", patientController.updatePatientDetails);

module.exports = router;