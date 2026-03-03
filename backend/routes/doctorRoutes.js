// =====================================================
// DOCTOR ROUTES
// =====================================================
// Defines all API endpoints for doctor operations
// Some routes may require authentication middleware
// =====================================================

const express = require("express");
const router = express.Router();
const doctorController = require("../controllers/doctorController");

/**
 * @route   POST /api/doctors/register
 * @desc    Register a new doctor (creates user + doctor profile)
 * @access  Public
 */
router.post("/register", doctorController.registerDoctor);

/**
 * @route   GET /api/doctors
 * @desc    Get all doctors
 * @access  Public (or protected - adjust as needed)
 */
router.get("/", doctorController.getAllDoctors);

/**
 * @route   GET /api/doctors/specialization/:specialization
 * @desc    Get doctors by specialization
 * @access  Public
 */
router.get("/specialization/:specialization", doctorController.getDoctorsBySpecialization);

/**
 * @route   GET /api/doctors/id/:doctorId
 * @desc    Get doctor by ID
 * @access  Public
 */
router.get("/id/:doctorId", doctorController.getDoctorById);

/**
 * @route   GET /api/doctors/email/:email
 * @desc    Get doctor by email
 * @access  Public
 */
router.get("/email/:email", doctorController.getDoctorByEmail);

/**
 * @route   PUT /api/doctors/:doctorId
 * @desc    Update doctor details
 * @access  Protected (should add auth middleware)
 */
router.put("/:doctorId", doctorController.updateDoctor);

/**
 * @route   DELETE /api/doctors/:doctorId
 * @desc    Delete doctor
 * @access  Protected (should add auth middleware)
 */
router.delete("/:doctorId", doctorController.deleteDoctor);

module.exports = router;