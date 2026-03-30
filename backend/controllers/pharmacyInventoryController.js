const PharmacyInventoryModel = require('../models/pharmacyInventoryModel');

// ======= Medicines =======
exports.createMedicine = async (req, res) => {
  try {
    const medicine = await PharmacyInventoryModel.createMedicine(req.body);
    res.status(201).json({ success: true, medicine });
  } catch (err) {
    console.error('ERROR CREATING MEDICINE:', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.getMedicines = async (req, res) => {
  try {
    const medicines = await PharmacyInventoryModel.findMedicines();
    res.status(200).json({ success: true, medicines });
  } catch (err) {
    console.error('ERROR GETTING MEDICINES:', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.updateMedicine = async (req, res) => {
  try {
    const medicine = await PharmacyInventoryModel.updateMedicine(req.params.medicineId, req.body);
    res.status(200).json({ success: true, medicine });
  } catch (err) {
    console.error('ERROR UPDATING MEDICINE:', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.deleteMedicine = async (req, res) => {
  try {
    const deleted = await PharmacyInventoryModel.deleteMedicine(req.params.medicineId);
    if (!deleted) {
      return res.status(404).json({ success: false, message: 'Medicine not found' });
    }
    res.status(200).json({ success: true, message: 'Medicine deleted' });
  } catch (err) {
    console.error('ERROR DELETING MEDICINE:', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.getMedicineVariants = async (req, res) => {
  try {
    const variants = await PharmacyInventoryModel.findVariantsByMedicine(req.params.medicineId);
    res.status(200).json({ success: true, variants });
  } catch (err) {
    console.error('ERROR GETTING VARIANTS:', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.createVariant = async (req, res) => {
  try {
    const variant = await PharmacyInventoryModel.createVariant(req.body);
    res.status(201).json({ success: true, variant });
  } catch (err) {
    console.error('ERROR CREATING VARIANT:', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.updateVariant = async (req, res) => {
  try {
    const variant = await PharmacyInventoryModel.updateVariant(req.params.variantId, req.body);
    res.status(200).json({ success: true, variant });
  } catch (err) {
    console.error('ERROR UPDATING VARIANT:', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.deleteVariant = async (req, res) => {
  try {
    const deleted = await PharmacyInventoryModel.deleteVariant(req.params.variantId);
    if (!deleted) {
      return res.status(404).json({ success: false, message: 'Variant not found' });
    }
    res.status(200).json({ success: true, message: 'Variant deleted' });
  } catch (err) {
    console.error('ERROR DELETING VARIANT:', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
};

// ======= Dealers =======
exports.createDealer = async (req, res) => {
  try {
    const dealer = await PharmacyInventoryModel.createDealer(req.body);
    res.status(201).json({ success: true, dealer });
  } catch (err) {
    console.error('ERROR CREATING DEALER:', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.getDealers = async (req, res) => {
  try {
    const dealers = await PharmacyInventoryModel.findDealers();
    res.status(200).json({ success: true, dealers });
  } catch (err) {
    console.error('ERROR GETTING DEALERS:', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.updateDealer = async (req, res) => {
  try {
    const dealer = await PharmacyInventoryModel.updateDealer(req.params.dealerId, req.body);
    res.status(200).json({ success: true, dealer });
  } catch (err) {
    console.error('ERROR UPDATING DEALER:', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.deleteDealer = async (req, res) => {
  try {
    const deleted = await PharmacyInventoryModel.deleteDealer(req.params.dealerId);
    if (!deleted) {
      return res.status(404).json({ success: false, message: 'Dealer not found' });
    }
    res.status(200).json({ success: true, message: 'Dealer deleted' });
  } catch (err) {
    console.error('ERROR DELETING DEALER:', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
};

// ======= Stock =======
exports.createStock = async (req, res) => {
  try {
    const stock = await PharmacyInventoryModel.createStock(req.body);
    res.status(201).json({ success: true, stock });
  } catch (err) {
    console.error('ERROR CREATING STOCK:', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.getStockByPharmacy = async (req, res) => {
  try {
    const stock = await PharmacyInventoryModel.findStockByPharmacy(req.params.pharmacyId);
    res.status(200).json({ success: true, stock });
  } catch (err) {
    console.error('ERROR GETTING STOCK:', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.getAvailableStock = async (req, res) => {
  try {
    const searchQuery = req.query.q ? String(req.query.q) : '';
    const stock = await PharmacyInventoryModel.findAvailableStock(searchQuery);
    res.status(200).json({ success: true, stock });
  } catch (err) {
    console.error('ERROR GETTING AVAILABLE STOCK:', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.updateStock = async (req, res) => {
  try {
    const stock = await PharmacyInventoryModel.updateStock(req.params.stockId, req.body);
    res.status(200).json({ success: true, stock });
  } catch (err) {
    console.error('ERROR UPDATING STOCK:', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.deleteStock = async (req, res) => {
  try {
    const deleted = await PharmacyInventoryModel.deleteStock(req.params.stockId);
    if (!deleted) {
      return res.status(404).json({ success: false, message: 'Stock entry not found' });
    }
    res.status(200).json({ success: true, message: 'Stock entry deleted' });
  } catch (err) {
    console.error('ERROR DELETING STOCK:', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
};
