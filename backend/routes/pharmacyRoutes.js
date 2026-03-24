const express = require("express");
const router = express.Router();
const pharmacyController = require("../controllers/pharmacyController");
const pharmacyInventoryController = require("../controllers/pharmacyInventoryController");

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

// ==================== PHARMACY INVENTORY ROUTES ====================
// Medicines
router.post("/medicines", pharmacyInventoryController.createMedicine);
router.get("/medicines", pharmacyInventoryController.getMedicines);
router.put("/medicines/:medicineId", pharmacyInventoryController.updateMedicine);
router.delete("/medicines/:medicineId", pharmacyInventoryController.deleteMedicine);

// Variants
router.post("/variants", pharmacyInventoryController.createVariant);
router.get("/medicines/:medicineId/variants", pharmacyInventoryController.getVariantsByMedicine);
router.put("/variants/:variantId", pharmacyInventoryController.updateVariant);
router.delete("/variants/:variantId", pharmacyInventoryController.deleteVariant);

// Dealers
router.post("/dealers", pharmacyInventoryController.createDealer);
router.get("/dealers", pharmacyInventoryController.getDealers);

// Stock
router.post("/stock", pharmacyInventoryController.addStock);
router.get("/:pharmacyId/stock", pharmacyInventoryController.getStockByPharmacy);
router.put("/stock/:stockId", pharmacyInventoryController.updateStock);
router.delete("/stock/:stockId", pharmacyInventoryController.deleteStock);

// Sales/Prescriptions
router.post("/sales", pharmacyInventoryController.recordSale);
router.get("/:pharmacyId/sales", pharmacyInventoryController.getSalesByPharmacy);

module.exports = router;