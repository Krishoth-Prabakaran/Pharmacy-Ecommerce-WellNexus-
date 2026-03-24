const PharmacyInventoryModel = require("../models/pharmacyInventoryModel");

// ============ MEDICINES ============
exports.createMedicine = async (req, res) => {
  try {
    const { name, manufacturer, brand } = req.body;

    if (!name) {
      return res.status(400).json({ success: false, message: "Medicine name is required" });
    }

    const medicine = await PharmacyInventoryModel.createMedicine({ name, manufacturer, brand });
    return res.status(201).json({ success: true, medicine });
  } catch (err) {
    console.error("ERROR CREATING MEDICINE:", err);
    return res.status(500).json({ success: false, message: "Server error creating medicine", error: err.message });
  }
};

exports.getMedicines = async (req, res) => {
  try {
    const medicines = await PharmacyInventoryModel.listMedicines();
    return res.status(200).json({ success: true, medicines });
  } catch (err) {
    console.error("ERROR GETTING MEDICINES:", err);
    return res.status(500).json({ success: false, message: "Server error fetching medicines", error: err.message });
  }
};

exports.updateMedicine = async (req, res) => {
  try {
    const { medicineId } = req.params;
    const medicine = await PharmacyInventoryModel.updateMedicine(medicineId, req.body);

    if (!medicine) {
      return res.status(404).json({ success: false, message: "Medicine not found" });
    }

    return res.status(200).json({ success: true, medicine });
  } catch (err) {
    console.error("ERROR UPDATING MEDICINE:", err);
    return res.status(500).json({ success: false, message: "Server error updating medicine", error: err.message });
  }
};

exports.deleteMedicine = async (req, res) => {
  try {
    const { medicineId } = req.params;
    const removed = await PharmacyInventoryModel.deleteMedicine(medicineId);

    if (!removed) return res.status(404).json({ success: false, message: "Medicine not found" });

    return res.status(200).json({ success: true, message: "Medicine deleted" });
  } catch (err) {
    console.error("ERROR DELETING MEDICINE:", err);
    return res.status(500).json({ success: false, message: "Server error deleting medicine", error: err.message });
  }
};

// ============ VARIANTS ============
exports.createVariant = async (req, res) => {
  try {
    const { medicine_id, strength, form, price } = req.body;
    if (!medicine_id) {
      return res.status(400).json({ success: false, message: "medicine_id is required" });
    }

    const variant = await PharmacyInventoryModel.createVariant({ medicine_id, strength, form, price });
    return res.status(201).json({ success: true, variant });
  } catch (err) {
    console.error("ERROR CREATING VARIANT:", err);
    return res.status(500).json({ success: false, message: "Server error creating variant", error: err.message });
  }
};

exports.getVariantsByMedicine = async (req, res) => {
  try {
    const { medicineId } = req.params;
    const variants = await PharmacyInventoryModel.listVariantsByMedicine(medicineId);
    return res.status(200).json({ success: true, variants });
  } catch (err) {
    console.error("ERROR GETTING VARIANTS:", err);
    return res.status(500).json({ success: false, message: "Server error fetching variants", error: err.message });
  }
};

exports.updateVariant = async (req, res) => {
  try {
    const { variantId } = req.params;
    const variant = await PharmacyInventoryModel.updateVariant(variantId, req.body);
    if (!variant) return res.status(404).json({ success: false, message: "Variant not found" });
    return res.status(200).json({ success: true, variant });
  } catch (err) {
    console.error("ERROR UPDATING VARIANT:", err);
    return res.status(500).json({ success: false, message: "Server error updating variant", error: err.message });
  }
};

exports.deleteVariant = async (req, res) => {
  try {
    const { variantId } = req.params;
    const removed = await PharmacyInventoryModel.deleteVariant(variantId);
    if (!removed) return res.status(404).json({ success: false, message: "Variant not found" });
    return res.status(200).json({ success: true, message: "Variant deleted" });
  } catch (err) {
    console.error("ERROR DELETING VARIANT:", err);
    return res.status(500).json({ success: false, message: "Server error deleting variant", error: err.message });
  }
};

// ============ DEALERS ============
exports.createDealer = async (req, res) => {
  try {
    const { dealer_name, phone, email } = req.body;
    const dealer = await PharmacyInventoryModel.createDealer({ dealer_name, phone, email });
    return res.status(201).json({ success: true, dealer });
  } catch (err) {
    console.error("ERROR CREATING DEALER:", err);
    return res.status(500).json({ success: false, message: "Server error creating dealer", error: err.message });
  }
};

exports.getDealers = async (req, res) => {
  try {
    const dealers = await PharmacyInventoryModel.listDealers();
    return res.status(200).json({ success: true, dealers });
  } catch (err) {
    console.error("ERROR GETTING DEALERS:", err);
    return res.status(500).json({ success: false, message: "Server error fetching dealers", error: err.message });
  }
};

// ============ STOCK ============
exports.addStock = async (req, res) => {
  try {
    const { pharmacy_id, variant_id, quantity, stocking_date, expiry_date, dealer_id } = req.body;
    if (!pharmacy_id || !variant_id || quantity == null) {
      return res.status(400).json({ success: false, message: "pharmacy_id, variant_id and quantity are required" });
    }
    const stock = await PharmacyInventoryModel.addStock({ pharmacy_id, variant_id, quantity, stocking_date, expiry_date, dealer_id });
    return res.status(201).json({ success: true, stock });
  } catch (err) {
    console.error("ERROR ADDING STOCK:", err);
    return res.status(500).json({ success: false, message: "Server error adding stock", error: err.message });
  }
};

exports.getStockByPharmacy = async (req, res) => {
  try {
    const { pharmacyId } = req.params;
    const stock = await PharmacyInventoryModel.listStockByPharmacy(pharmacyId);
    return res.status(200).json({ success: true, stock });
  } catch (err) {
    console.error("ERROR GETTING STOCK:", err);
    return res.status(500).json({ success: false, message: "Server error fetching stock", error: err.message });
  }
};

exports.updateStock = async (req, res) => {
  try {
    const { stockId } = req.params;
    const stock = await PharmacyInventoryModel.updateStock(stockId, req.body);
    if (!stock) return res.status(404).json({ success: false, message: "Stock record not found" });
    return res.status(200).json({ success: true, stock });
  } catch (err) {
    console.error("ERROR UPDATING STOCK:", err);
    return res.status(500).json({ success: false, message: "Server error updating stock", error: err.message });
  }
};

exports.deleteStock = async (req, res) => {
  try {
    const { stockId } = req.params;
    const removed = await PharmacyInventoryModel.deleteStock(stockId);
    if (!removed) return res.status(404).json({ success: false, message: "Stock record not found" });
    return res.status(200).json({ success: true, message: "Stock record deleted" });
  } catch (err) {
    console.error("ERROR DELETING STOCK:", err);
    return res.status(500).json({ success: false, message: "Server error deleting stock", error: err.message });
  }
};

// ============ SALES/PRESCRIPTIONS ============
exports.recordSale = async (req, res) => {
  try {
    const { prescription_id, patient_id, pharmacy_id, sale_date } = req.body;
    if (!pharmacy_id || !patient_id) {
      return res.status(400).json({ success: false, message: "pharmacy_id and patient_id are required" });
    }
    const sale = await PharmacyInventoryModel.recordSale({ prescription_id, patient_id, pharmacy_id, sale_date });
    return res.status(201).json({ success: true, sale });
  } catch (err) {
    console.error("ERROR RECORDING SALE:", err);
    return res.status(500).json({ success: false, message: "Server error recording sale", error: err.message });
  }
};

exports.getSalesByPharmacy = async (req, res) => {
  try {
    const { pharmacyId } = req.params;
    const sales = await PharmacyInventoryModel.listSalesByPharmacy(pharmacyId);
    return res.status(200).json({ success: true, sales });
  } catch (err) {
    console.error("ERROR GETTING SALES:", err);
    return res.status(500).json({ success: false, message: "Server error fetching sales", error: err.message });
  }
};
