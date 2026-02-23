const express = require("express");
const router = express.Router();
const pharmacyController = require("../controllers/pharmacyController");

// Public routes (no authentication required)
// Register a new pharmacy
router.post("/register", pharmacyController.registerPharmacy);

// Get all pharmacies
router.get("/", pharmacyController.getAllPharmacies);

// Get nearby pharmacies by location
router.get("/nearby", pharmacyController.getNearbyPharmacies);

// Get pharmacy by ID
router.get("/id/:pharmacyId", pharmacyController.getPharmacyById);

// Get pharmacy by email
router.get("/email/:email", pharmacyController.getPharmacyByEmail);

// Get pharmacy by phone
router.get("/phone/:phone", pharmacyController.getPharmacyByPhone);

// Update pharmacy details
router.put("/:pharmacyId", pharmacyController.updatePharmacy);

// Delete pharmacy
router.delete("/:pharmacyId", pharmacyController.deletePharmacy);

module.exports = router;