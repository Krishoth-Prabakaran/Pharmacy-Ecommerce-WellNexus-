// =====================================================
// APPOINTMENT ROUTES
// =====================================================
// Routes for appointment management
// =====================================================

const express = require('express');
const router = express.Router();
const appointmentController = require('../controllers/appointmentController');
const { authenticate } = require('../middleware/authMiddleware');

// All appointment routes require authentication
router.use(authenticate);

// Create appointment
router.post('/', appointmentController.createAppointment);

// Get appointments by doctor (query param: doctor_id or doctor_license)
router.get('/doctor/:doctorId', appointmentController.getAppointmentsByDoctor);

// Get appointments by date range (query params: start_date, end_date)
router.get('/range', appointmentController.getAppointmentsByDateRange);

// Get appointment by ID
router.get('/:id', appointmentController.getAppointmentById);

// Update appointment status
router.put('/:id/status', appointmentController.updateAppointmentStatus);

// Delete appointment
router.delete('/:id', appointmentController.deleteAppointment);

module.exports = router;