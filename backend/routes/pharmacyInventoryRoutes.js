const express = require('express');
const router = express.Router();
const inventoryController = require('../controllers/pharmacyInventoryController');

// Medicines
router.post('/medicines', inventoryController.createMedicine);
router.get('/medicines', inventoryController.getMedicines);
router.put('/medicines/:medicineId', inventoryController.updateMedicine);
router.delete('/medicines/:medicineId', inventoryController.deleteMedicine);
router.get('/medicines/:medicineId/variants', inventoryController.getMedicineVariants);

// Variants
router.post('/variants', inventoryController.createVariant);
router.put('/variants/:variantId', inventoryController.updateVariant);
router.delete('/variants/:variantId', inventoryController.deleteVariant);

// Dealers
router.post('/dealers', inventoryController.createDealer);
router.get('/dealers', inventoryController.getDealers);
router.put('/dealers/:dealerId', inventoryController.updateDealer);
router.delete('/dealers/:dealerId', inventoryController.deleteDealer);

// Pharmacy stock
router.post('/pharmacy-stock', inventoryController.createStock);
router.get('/pharmacy-stock/:pharmacyId', inventoryController.getStockByPharmacy);
router.put('/pharmacy-stock/:stockId', inventoryController.updateStock);
router.delete('/pharmacy-stock/:stockId', inventoryController.deleteStock);

module.exports = router;
