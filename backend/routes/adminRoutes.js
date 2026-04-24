// backend/routes/adminRoutes.js
const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');

// ==================== ADMIN AUTHENTICATION MIDDLEWARE ====================
// This middleware checks if the user is an admin
const adminAuth = (req, res, next) => {
  // Get token from header
  const token = req.headers.authorization?.split(' ')[1];
  
  if (!token) {
    return res.status(401).json({
      success: false,
      message: 'No token provided. Please login first.',
    });
  }

  try {
    const jwt = require('jsonwebtoken');
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'secret');
    
    // Check if user is admin
    if (decoded.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied. Admin privileges required.',
      });
    }

    // Attach user info to request
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(401).json({
      success: false,
      message: 'Invalid or expired token.',
    });
  }
};

// ==================== ROUTES ====================

// Dashboard Stats
router.get('/stats', adminAuth, adminController.getDashboardStats);

// User Management
router.get('/users', adminAuth, adminController.getAllUsers);
router.put('/users/:userId/role', adminAuth, adminController.updateUserRole);
router.delete('/users/:userId', adminAuth, adminController.deleteUser);

// Patient Management
router.get('/patients', adminAuth, adminController.getAllPatients);

// Doctor Management
router.get('/doctors', adminAuth, adminController.getAllDoctors);

// Pharmacy Management
router.get('/pharmacies', adminAuth, adminController.getAllPharmacies);

// Appointment Management
router.get('/appointments', adminAuth, adminController.getAllAppointments);
router.put('/appointments/:appointmentId/status', adminAuth, adminController.updateAppointmentStatus);

// Prescription Management
router.get('/prescriptions', adminAuth, adminController.getAllPrescriptions);
router.put('/prescriptions/:prescriptionId/status', adminAuth, adminController.updatePrescriptionStatus);

// Order Management
router.get('/orders', adminAuth, adminController.getAllOrders);

module.exports = router;