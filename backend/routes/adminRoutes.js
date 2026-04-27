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
    if (!process.env.JWT_SECRET) {
      throw new Error('JWT_SECRET environment variable is not configured');
    }
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
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

// Professional Verification
router.put('/doctors/:doctorId/verify', adminAuth, adminController.verifyDoctor);
router.put('/pharmacies/:pharmacyId/verify', adminAuth, adminController.verifyPharmacy);

// Analytics
router.get('/analytics', adminAuth, adminController.getAnalytics);

// Dispute Management
router.get('/disputes', adminAuth, adminController.getAllDisputes);
router.post('/disputes', adminAuth, adminController.createDispute);
router.put('/disputes/:disputeId/status', adminAuth, adminController.updateDisputeStatus);

module.exports = router;

// ==================== ADD THESE ROUTES ====================

// User Management - Additional
router.put('/users/:userId/deactivate', adminAuth, adminController.deactivateUser);
router.post('/users/:userId/reset-password', adminAuth, adminController.adminResetPassword);

// Order Management
router.get('/orders', adminAuth, adminController.getAllOrders);