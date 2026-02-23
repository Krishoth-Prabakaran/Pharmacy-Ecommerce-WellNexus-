const express = require("express");
const router = express.Router();
const patientController = require("../controllers/patientController");

// Save patient details (POST) - using email to link with users table
router.post("/details", patientController.savePatientDetails);

// Get patient details by email (GET)
router.get("/:email", patientController.getPatientDetails);

// Get patient by phone (GET)
router.get("/phone/:phone", patientController.getPatientByPhone);

// Update patient details by email (PUT)
router.put("/:email", patientController.updatePatientDetails);

// Check if patient has details by email (GET)
router.get("/:email/check", patientController.checkPatientDetails);

module.exports = router;