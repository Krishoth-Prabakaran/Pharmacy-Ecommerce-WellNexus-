// =====================================================
// PRESCRIPTION ROUTES
// =====================================================
// Routes for prescription management
// =====================================================

const express = require('express');
const router = express.Router();
const prescriptionController = require('../controllers/prescriptionController');

// Create prescription
router.post('/', prescriptionController.createPrescription);

// Get prescription by ID
router.get('/:id', prescriptionController.getPrescription);

// Get prescriptions by doctor
router.get('/doctor/:doctorLicense', prescriptionController.getPrescriptionsByDoctor);

// Get prescriptions by patient
router.get('/patient/:patientId', prescriptionController.getPrescriptionsByPatient);

// Update prescription status
router.put('/:id/status', prescriptionController.updatePrescriptionStatus);

// Delete prescription
router.delete('/:id', prescriptionController.deletePrescription);

module.exports = router;