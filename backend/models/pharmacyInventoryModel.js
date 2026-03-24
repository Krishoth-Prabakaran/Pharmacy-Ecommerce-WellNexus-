const pool = require("../config/db");

const PharmacyInventoryModel = {
  // ============ MEDICINES ============
  async createMedicine(medicineData) {
    const result = await pool.query(
      `INSERT INTO medicines (name, manufacturer, brand)
       VALUES ($1, $2, $3)
       RETURNING medicine_id, name, manufacturer, brand`,
      [medicineData.name, medicineData.manufacturer || null, medicineData.brand || '']
    );
    return result.rows[0];
  },

  async getMedicineById(medicineId) {
    const result = await pool.query(
      `SELECT medicine_id, name, manufacturer, brand FROM medicines WHERE medicine_id = $1`,
      [medicineId]
    );
    return result.rows[0];
  },

  async updateMedicine(medicineId, updateData) {
    const updates = [];
    const values = [];
    let idx = 1;

    ['name', 'manufacturer', 'brand'].forEach((field) => {
      if (updateData[field] !== undefined) {
        updates.push(`${field} = $${idx++}`);
        values.push(updateData[field]);
      }
    });

    if (updates.length === 0) {
      throw new Error('No medicine fields to update');
    }

    values.push(medicineId);

    const query = `
      UPDATE medicines
      SET ${updates.join(', ')}
      WHERE medicine_id = $${idx}
      RETURNING medicine_id, name, manufacturer, brand
    `;

    const result = await pool.query(query, values);
    return result.rows[0];
  },

  async deleteMedicine(medicineId) {
    const result = await pool.query(
      `DELETE FROM medicines WHERE medicine_id = $1`,
      [medicineId]
    );
    return result.rowCount > 0;
  },

  async listMedicines() {
    const result = await pool.query(
      `SELECT medicine_id, name, manufacturer, brand FROM medicines ORDER BY name`
    );
    return result.rows;
  },

  // ============ VARIANTS ============
  async createVariant(variantData) {
    const result = await pool.query(
      `INSERT INTO medicine_variants (medicine_id, strength, form, price)
       VALUES ($1, $2, $3, $4)
       RETURNING variant_id, medicine_id, strength, form, price`,
      [variantData.medicine_id, variantData.strength || null, variantData.form || null, variantData.price || null]
    );
    return result.rows[0];
  },

  async listVariantsByMedicine(medicineId) {
    const result = await pool.query(
      `SELECT variant_id, medicine_id, strength, form, price
       FROM medicine_variants
       WHERE medicine_id = $1
       ORDER BY variant_id`,
      [medicineId]
    );
    return result.rows;
  },

  async updateVariant(variantId, updateData) {
    const updates = [];
    const values = [];
    let idx = 1;

    ['strength', 'form', 'price'].forEach((field) => {
      if (updateData[field] !== undefined) {
        updates.push(`${field} = $${idx++}`);
        values.push(updateData[field]);
      }
    });

    if (updates.length === 0) {
      throw new Error('No variant fields to update');
    }

    values.push(variantId);

    const query = `
      UPDATE medicine_variants
      SET ${updates.join(', ')}
      WHERE variant_id = $${idx}
      RETURNING variant_id, medicine_id, strength, form, price
    `;
    const result = await pool.query(query, values);
    return result.rows[0];
  },

  async deleteVariant(variantId) {
    const result = await pool.query(
      `DELETE FROM medicine_variants WHERE variant_id = $1`,
      [variantId]
    );
    return result.rowCount > 0;
  },

  // ============ DEALERS ============
  async createDealer(dealerData) {
    const result = await pool.query(
      `INSERT INTO dealers (dealer_name, phone, email)
       VALUES ($1, $2, $3)
       RETURNING dealer_id, dealer_name, phone, email`,
      [dealerData.dealer_name, dealerData.phone || null, dealerData.email || null]
    );
    return result.rows[0];
  },

  async listDealers() {
    const result = await pool.query(
      `SELECT dealer_id, dealer_name, phone, email FROM dealers ORDER BY dealer_name`
    );
    return result.rows;
  },

  // ============ STOCK ============
  async addStock(stockData) {
    const result = await pool.query(
      `INSERT INTO pharmacy_stock (pharmacy_id, variant_id, quantity, stocking_date, expiry_date, dealer_id)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING stock_id, pharmacy_id, variant_id, quantity, stocking_date, expiry_date, dealer_id`,
      [stockData.pharmacy_id, stockData.variant_id, stockData.quantity, stockData.stocking_date || null, stockData.expiry_date || null, stockData.dealer_id || null]
    );
    return result.rows[0];
  },

  async updateStock(stockId, updateData) {
    const updates = [];
    const values = [];
    let idx = 1;

    ['pharmacy_id', 'variant_id', 'quantity', 'stocking_date', 'expiry_date', 'dealer_id'].forEach((field) => {
      if (updateData[field] !== undefined) {
        updates.push(`${field} = $${idx++}`);
        values.push(updateData[field]);
      }
    });

    if (updates.length === 0) {
      throw new Error('No stock fields to update');
    }

    values.push(stockId);

    const query = `
      UPDATE pharmacy_stock
      SET ${updates.join(', ')}
      WHERE stock_id = $${idx}
      RETURNING stock_id, pharmacy_id, variant_id, quantity, stocking_date, expiry_date, dealer_id
    `;

    const result = await pool.query(query, values);
    return result.rows[0];
  },

  async deleteStock(stockId) {
    const result = await pool.query(
      `DELETE FROM pharmacy_stock WHERE stock_id = $1`,
      [stockId]
    );
    return result.rowCount > 0;
  },

  async listStockByPharmacy(pharmacyId) {
    const result = await pool.query(
      `SELECT ps.stock_id, ps.pharmacy_id, ps.variant_id, ps.quantity, ps.stocking_date, ps.expiry_date, ps.dealer_id,
              mv.strength, mv.form, mv.price, m.name AS medicine_name,
              d.dealer_name
       FROM pharmacy_stock ps
       JOIN medicine_variants mv ON ps.variant_id = mv.variant_id
       JOIN medicines m ON mv.medicine_id = m.medicine_id
       LEFT JOIN dealers d ON ps.dealer_id = d.dealer_id
       WHERE ps.pharmacy_id = $1
       ORDER BY ps.stock_id DESC`,
      [pharmacyId]
    );
    return result.rows;
  },

  // ============ SALES / PRESCRIPTIONS ============
  async recordSale(saleData) {
    const result = await pool.query(
      `INSERT INTO sales (prescription_id, patient_id, pharmacy_id, sale_date)
       VALUES ($1, $2, $3, COALESCE($4, NOW()))
       RETURNING sale_id, prescription_id, patient_id, pharmacy_id, sale_date`,
      [saleData.prescription_id, saleData.patient_id, saleData.pharmacy_id, saleData.sale_date || null]
    );
    return result.rows[0];
  },

  async listSalesByPharmacy(pharmacyId) {
    const result = await pool.query(
      `SELECT sale_id, prescription_id, patient_id, pharmacy_id, sale_date
       FROM sales
       WHERE pharmacy_id = $1
       ORDER BY sale_date DESC`,
      [pharmacyId]
    );
    return result.rows;
  }
};

module.exports = PharmacyInventoryModel;
