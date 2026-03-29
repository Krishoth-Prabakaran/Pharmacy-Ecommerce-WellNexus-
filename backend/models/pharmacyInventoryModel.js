const pool = require('../config/db');

const PharmacyInventoryModel = {
  // ======= Medicines =======
  async createMedicine(data) {
    const result = await pool.query(
      `INSERT INTO medicines (name, manufacturer, brand)
       VALUES ($1, $2, $3)
       RETURNING medicine_id, name, manufacturer, brand`,
      [data.name, data.manufacturer || null, data.brand || '']
    );
    return result.rows[0];
  },

  async updateMedicine(medicineId, data) {
    const fields = [];
    const values = [];
    let index = 1;

    if (data.name !== undefined) {
      fields.push(`name = $${index++}`);
      values.push(data.name);
    }
    if (data.manufacturer !== undefined) {
      fields.push(`manufacturer = $${index++}`);
      values.push(data.manufacturer);
    }
    if (data.brand !== undefined) {
      fields.push(`brand = $${index++}`);
      values.push(data.brand);
    }

    if (fields.length === 0) {
      throw new Error('No fields provided for medicine update');
    }

    values.push(medicineId);
    const result = await pool.query(
      `UPDATE medicines SET ${fields.join(', ')} WHERE medicine_id = $${index}
       RETURNING medicine_id, name, manufacturer, brand`,
      values
    );
    return result.rows[0];
  },

  async deleteMedicine(medicineId) {
    const result = await pool.query(
      'DELETE FROM medicines WHERE medicine_id = $1 RETURNING medicine_id',
      [medicineId]
    );
    return result.rows.length > 0;
  },

  async findMedicines() {
    const result = await pool.query(
      `SELECT medicine_id, name, manufacturer, brand
       FROM medicines
       ORDER BY name`
    );
    return result.rows;
  },

  async findMedicineById(medicineId) {
    const result = await pool.query(
      `SELECT medicine_id, name, manufacturer, brand
       FROM medicines
       WHERE medicine_id = $1`,
      [medicineId]
    );
    return result.rows[0];
  },

  // ======= Variants =======
  async createVariant(data) {
    const result = await pool.query(
      `INSERT INTO medicine_variants (medicine_id, strength, form, price)
       VALUES ($1, $2, $3, $4)
       RETURNING variant_id, medicine_id, strength, form, price`,
      [data.medicine_id, data.strength || null, data.form || null, data.price || null]
    );
    return result.rows[0];
  },

  async updateVariant(variantId, data) {
    const fields = [];
    const values = [];
    let index = 1;

    if (data.strength !== undefined) {
      fields.push(`strength = $${index++}`);
      values.push(data.strength);
    }
    if (data.form !== undefined) {
      fields.push(`form = $${index++}`);
      values.push(data.form);
    }
    if (data.price !== undefined) {
      fields.push(`price = $${index++}`);
      values.push(data.price);
    }

    if (fields.length === 0) {
      throw new Error('No fields provided for variant update');
    }

    values.push(variantId);
    const result = await pool.query(
      `UPDATE medicine_variants SET ${fields.join(', ')} WHERE variant_id = $${index}
       RETURNING variant_id, medicine_id, strength, form, price`,
      values
    );
    return result.rows[0];
  },

  async deleteVariant(variantId) {
    const result = await pool.query(
      'DELETE FROM medicine_variants WHERE variant_id = $1 RETURNING variant_id',
      [variantId]
    );
    return result.rows.length > 0;
  },

  async findVariantsByMedicine(medicineId) {
    const result = await pool.query(
      `SELECT variant_id, medicine_id, strength, form, price
       FROM medicine_variants
       WHERE medicine_id = $1
       ORDER BY variant_id`,
      [medicineId]
    );
    return result.rows;
  },

  async findVariantById(variantId) {
    const result = await pool.query(
      `SELECT variant_id, medicine_id, strength, form, price
       FROM medicine_variants
       WHERE variant_id = $1`,
      [variantId]
    );
    return result.rows[0];
  },

  // ======= Dealers =======
  async createDealer(data) {
    const result = await pool.query(
      `INSERT INTO dealers (dealer_name, phone, email)
       VALUES ($1, $2, $3)
       RETURNING dealer_id, dealer_name, phone, email`,
      [data.dealer_name || null, data.phone || null, data.email || null]
    );
    return result.rows[0];
  },

  async updateDealer(dealerId, data) {
    const fields = [];
    const values = [];
    let index = 1;

    if (data.dealer_name !== undefined) {
      fields.push(`dealer_name = $${index++}`);
      values.push(data.dealer_name);
    }
    if (data.phone !== undefined) {
      fields.push(`phone = $${index++}`);
      values.push(data.phone);
    }
    if (data.email !== undefined) {
      fields.push(`email = $${index++}`);
      values.push(data.email);
    }

    if (fields.length === 0) {
      throw new Error('No fields provided for dealer update');
    }

    values.push(dealerId);
    const result = await pool.query(
      `UPDATE dealers SET ${fields.join(', ')} WHERE dealer_id = $${index}
       RETURNING dealer_id, dealer_name, phone, email`,
      values
    );
    return result.rows[0];
  },

  async deleteDealer(dealerId) {
    const result = await pool.query(
      'DELETE FROM dealers WHERE dealer_id = $1 RETURNING dealer_id',
      [dealerId]
    );
    return result.rows.length > 0;
  },

  async findDealers() {
    const result = await pool.query(
      `SELECT dealer_id, dealer_name, phone, email
       FROM dealers
       ORDER BY dealer_name`);
    return result.rows;
  },

  async findDealerById(dealerId) {
    const result = await pool.query(
      `SELECT dealer_id, dealer_name, phone, email
       FROM dealers
       WHERE dealer_id = $1`,
      [dealerId]
    );
    return result.rows[0];
  },

  // ======= Pharmacy stock =======
  async createStock(data) {
    const result = await pool.query(
      `INSERT INTO pharmacy_stock (pharmacy_id, variant_id, quantity, stocking_date, expiry_date, dealer_id)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING stock_id, pharmacy_id, variant_id, quantity, stocking_date, expiry_date, dealer_id`,
      [
        data.pharmacy_id,
        data.variant_id,
        data.quantity || null,
        data.stocking_date || null,
        data.expiry_date || null,
        data.dealer_id || null,
      ]
    );
    return result.rows[0];
  },

  async updateStock(stockId, data) {
    const fields = [];
    const values = [];
    let index = 1;

    if (data.variant_id !== undefined) {
      fields.push(`variant_id = $${index++}`);
      values.push(data.variant_id);
    }
    if (data.quantity !== undefined) {
      fields.push(`quantity = $${index++}`);
      values.push(data.quantity);
    }
    if (data.stocking_date !== undefined) {
      fields.push(`stocking_date = $${index++}`);
      values.push(data.stocking_date);
    }
    if (data.expiry_date !== undefined) {
      fields.push(`expiry_date = $${index++}`);
      values.push(data.expiry_date);
    }
    if (data.dealer_id !== undefined) {
      fields.push(`dealer_id = $${index++}`);
      values.push(data.dealer_id);
    }

    if (fields.length === 0) {
      throw new Error('No fields provided for stock update');
    }

    values.push(stockId);
    const result = await pool.query(
      `UPDATE pharmacy_stock SET ${fields.join(', ')} WHERE stock_id = $${index}
       RETURNING stock_id, pharmacy_id, variant_id, quantity, stocking_date, expiry_date, dealer_id`,
      values
    );
    return result.rows[0];
  },

  async deleteStock(stockId) {
    const result = await pool.query(
      'DELETE FROM pharmacy_stock WHERE stock_id = $1 RETURNING stock_id',
      [stockId]
    );
    return result.rows.length > 0;
  },

  async findStockByPharmacy(pharmacyId) {
    const result = await pool.query(
      `SELECT s.stock_id, s.pharmacy_id, s.variant_id, s.quantity, s.stocking_date, s.expiry_date, s.dealer_id,
              v.strength, v.form, v.price,
              m.name AS medicine_name, m.brand AS medicine_brand, m.manufacturer AS medicine_manufacturer,
              d.dealer_name, d.phone AS dealer_phone, d.email AS dealer_email
       FROM pharmacy_stock s
       LEFT JOIN medicine_variants v ON s.variant_id = v.variant_id
       LEFT JOIN medicines m ON v.medicine_id = m.medicine_id
       LEFT JOIN dealers d ON s.dealer_id = d.dealer_id
       WHERE s.pharmacy_id = $1
       ORDER BY s.stock_id DESC`,
      [pharmacyId]
    );
    return result.rows;
  },
};

module.exports = PharmacyInventoryModel;
