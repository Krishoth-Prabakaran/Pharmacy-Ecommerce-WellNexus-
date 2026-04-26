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
      `INSERT INTO medicine_variants (medicine_id, strength, form, price, image_url)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING variant_id, medicine_id, strength, form, price, image_url`,
      [data.medicine_id, data.strength || null, data.form || null, data.price || null, data.image_url || null]
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
    if (data.image_url !== undefined) {
      fields.push(`image_url = $${index++}`);
      values.push(data.image_url);
    }

    if (fields.length === 0) {
      throw new Error('No fields provided for variant update');
    }

    values.push(variantId);
    const result = await pool.query(
      `UPDATE medicine_variants SET ${fields.join(', ')} WHERE variant_id = $${index}
       RETURNING variant_id, medicine_id, strength, form, price, image_url`,
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
      `SELECT variant_id, medicine_id, strength, form, price, image_url
       FROM medicine_variants
       WHERE medicine_id = $1
       ORDER BY variant_id`,
      [medicineId]
    );
    return result.rows;
  },

  async findVariantById(variantId) {
    const result = await pool.query(
      `SELECT variant_id, medicine_id, strength, form, price, image_url
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

  // ======= Low Stock Alerts =======
  async findLowStockByPharmacy(pharmacyId, threshold = 10) {
    const result = await pool.query(
      `SELECT s.stock_id, s.pharmacy_id, s.variant_id, s.quantity, s.stocking_date, s.expiry_date, s.dealer_id,
              v.strength, v.form, v.price,
              m.name AS medicine_name, m.brand AS medicine_brand, m.manufacturer AS medicine_manufacturer,
              d.dealer_id, d.dealer_name, d.phone AS dealer_phone, d.email AS dealer_email
       FROM pharmacy_stock s
       LEFT JOIN medicine_variants v ON s.variant_id = v.variant_id
       LEFT JOIN medicines m ON v.medicine_id = m.medicine_id
       LEFT JOIN dealers d ON s.dealer_id = d.dealer_id
       WHERE s.pharmacy_id = $1 AND s.quantity <= $2
       ORDER BY s.quantity ASC, s.stock_id DESC`,
      [pharmacyId, threshold]
    );
    return result.rows;
  },

  async findAvailableStock(searchQuery = '') {
    const params = [];
    let whereClause = '';

    if (searchQuery && searchQuery.trim() !== '') {
      const searchTerm = `%${searchQuery.toLowerCase()}%`;
      params.push(searchTerm);
      params.push(searchTerm);
      params.push(searchTerm);
      params.push(searchTerm);
      params.push(searchTerm);
      params.push(searchTerm);
      whereClause = `WHERE (
          LOWER(m.name) LIKE $1 OR
          LOWER(m.brand) LIKE $2 OR
          LOWER(m.manufacturer) LIKE $3 OR
          LOWER(p.pharmacy_name) LIKE $4 OR
          LOWER(p.address) LIKE $5 OR
          LOWER(p.phone) LIKE $6
        )`;
    }

    const query = `SELECT s.stock_id, s.pharmacy_id, s.variant_id, s.quantity, s.stocking_date, s.expiry_date, s.dealer_id,
              v.strength, v.form, v.price,
              m.name AS medicine_name, m.brand AS medicine_brand, m.manufacturer AS medicine_manufacturer,
              d.dealer_name, d.phone AS dealer_phone, d.email AS dealer_email,
              p.pharmacy_name, p.address AS pharmacy_address, p.phone AS pharmacy_phone, p.open_time, p.close_time
       FROM pharmacy_stock s
       LEFT JOIN medicine_variants v ON s.variant_id = v.variant_id
       LEFT JOIN medicines m ON v.medicine_id = m.medicine_id
       LEFT JOIN dealers d ON s.dealer_id = d.dealer_id
       LEFT JOIN pharmacies p ON s.pharmacy_id = p.pharmacy_id
       ${whereClause}
       ORDER BY s.quantity DESC, s.stock_id DESC`;
    const result = await pool.query(query, params);
    return result.rows;
  },

  // ======= SALES =======

  /**
   * Create a new sale
   * @param {Object} saleData - Sale details
   * @returns {Object} Created sale
   */
  async createSale(saleData) {
    const client = await pool.connect();

    try {
      await client.query('BEGIN');

      // Create the sale record
      const saleResult = await client.query(
        `INSERT INTO sales (prescription_id, patient_id, pharmacy_id, sale_date)
         VALUES ($1, $2, $3, $4)
         RETURNING *`,
        [
          saleData.prescription_id || null,
          saleData.patient_id,
          saleData.pharmacy_id,
          saleData.sale_date || new Date()
        ]
      );

      const sale = saleResult.rows[0];

      // Add sale items and update stock
      if (saleData.items && saleData.items.length > 0) {
        for (const item of saleData.items) {
          // Check if enough stock is available
          const stockCheck = await client.query(
            `SELECT ps.quantity, mv.price
             FROM pharmacy_stock ps
             JOIN medicine_variants mv ON ps.variant_id = mv.variant_id
             WHERE ps.pharmacy_id = $1 AND ps.variant_id = $2 AND ps.quantity >= $3
             ORDER BY ps.expiry_date ASC
             LIMIT 1`,
            [saleData.pharmacy_id, item.variant_id, item.quantity]
          );

          if (stockCheck.rows.length === 0) {
            throw new Error(`Insufficient stock for variant ${item.variant_id}`);
          }

          // Create sale item
          await client.query(
            `INSERT INTO sale_items (sale_id, variant_id, quantity)
             VALUES ($1, $2, $3)`,
            [sale.sale_id, item.variant_id, item.quantity]
          );

          // Update stock quantity (reduce by sold amount)
          await client.query(
            `UPDATE pharmacy_stock
             SET quantity = quantity - $1
             WHERE pharmacy_id = $2 AND variant_id = $3 AND quantity >= $1
             ORDER BY expiry_date ASC
             LIMIT 1`,
            [item.quantity, saleData.pharmacy_id, item.variant_id]
          );
        }
      }

      await client.query('COMMIT');
      return sale;

    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  },

  /**
   * Get sales by pharmacy
   * @param {number} pharmacyId - Pharmacy ID
   * @param {Object} options - Query options (limit, offset, date range)
   * @returns {Array} List of sales with items
   */
  async findSalesByPharmacy(pharmacyId, options = {}) {
    const limit = options.limit || 50;
    const offset = options.offset || 0;

    let whereClause = 'WHERE s.pharmacy_id = $1';
    const params = [pharmacyId];
    let paramIndex = 2;

    if (options.startDate) {
      whereClause += ` AND s.sale_date >= $${paramIndex}`;
      params.push(options.startDate);
      paramIndex++;
    }

    if (options.endDate) {
      whereClause += ` AND s.sale_date <= $${paramIndex}`;
      params.push(options.endDate);
      paramIndex++;
    }

    const salesResult = await pool.query(
      `SELECT
        s.sale_id, s.prescription_id, s.patient_id, s.pharmacy_id, s.sale_date,
        p.first_name as patient_first_name, p.last_name as patient_last_name,
        pr.sms_code as prescription_code
       FROM sales s
       LEFT JOIN patients p ON s.patient_id = p.patient_id
       LEFT JOIN prescriptions pr ON s.prescription_id = pr.prescription_id
       ${whereClause}
       ORDER BY s.sale_date DESC
       LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`,
      [...params, limit, offset]
    );

    // Get items for each sale
    const sales = [];
    for (const sale of salesResult.rows) {
      const itemsResult = await pool.query(
        `SELECT
          si.quantity,
          mv.variant_name, mv.strength, mv.form, mv.price,
          m.name as medicine_name, m.brand
         FROM sale_items si
         JOIN medicine_variants mv ON si.variant_id = mv.variant_id
         JOIN medicines m ON mv.medicine_id = m.medicine_id
         WHERE si.sale_id = $1`,
        [sale.sale_id]
      );

      sales.push({
        ...sale,
        items: itemsResult.rows,
        total_amount: itemsResult.rows.reduce((sum, item) => sum + (item.price * item.quantity), 0)
      });
    }

    return sales;
  },

  /**
   * Get sale by ID with full details
   * @param {number} saleId - Sale ID
   * @returns {Object} Sale with items and patient details
   */
  async findSaleById(saleId) {
    const saleResult = await pool.query(
      `SELECT
        s.sale_id, s.prescription_id, s.patient_id, s.pharmacy_id, s.sale_date,
        p.first_name as patient_first_name, p.last_name as patient_last_name, p.phone as patient_phone,
        ph.pharmacy_name,
        pr.sms_code as prescription_code, pr.doctor_name
       FROM sales s
       LEFT JOIN patients p ON s.patient_id = p.patient_id
       LEFT JOIN pharmacies ph ON s.pharmacy_id = ph.pharmacy_id
       LEFT JOIN prescriptions pr ON s.prescription_id = pr.prescription_id
       WHERE s.sale_id = $1`,
      [saleId]
    );

    if (saleResult.rows.length === 0) {
      return null;
    }

    const sale = saleResult.rows[0];

    // Get sale items
    const itemsResult = await pool.query(
      `SELECT
        si.quantity,
        mv.variant_name, mv.strength, mv.form, mv.price,
        m.name as medicine_name, m.brand, m.manufacturer
       FROM sale_items si
       JOIN medicine_variants mv ON si.variant_id = mv.variant_id
       JOIN medicines m ON mv.medicine_id = m.medicine_id
       WHERE si.sale_id = $1`,
      [saleId]
    );

    return {
      ...sale,
      items: itemsResult.rows,
      total_amount: itemsResult.rows.reduce((sum, item) => sum + (item.price * item.quantity), 0),
      item_count: itemsResult.rows.length
    };
  },

  /**
   * Get sales statistics for pharmacy
   * @param {number} pharmacyId - Pharmacy ID
   * @param {Object} options - Date range options
   * @returns {Object} Sales statistics
   */
  async getSalesStats(pharmacyId, options = {}) {
    let whereClause = 'WHERE s.pharmacy_id = $1';
    const params = [pharmacyId];
    let paramIndex = 2;

    if (options.startDate) {
      whereClause += ` AND s.sale_date >= $${paramIndex}`;
      params.push(options.startDate);
      paramIndex++;
    }

    if (options.endDate) {
      whereClause += ` AND s.sale_date <= $${paramIndex}`;
      params.push(options.endDate);
      paramIndex++;
    }

    const statsResult = await pool.query(
      `SELECT
        COUNT(DISTINCT s.sale_id) as total_sales,
        SUM(si.quantity) as total_items_sold,
        SUM(si.quantity * mv.price) as total_revenue,
        AVG(si.quantity * mv.price) as avg_sale_amount
       FROM sales s
       JOIN sale_items si ON s.sale_id = si.sale_id
       JOIN medicine_variants mv ON si.variant_id = mv.variant_id
       ${whereClause}`,
      params
    );

    return statsResult.rows[0];
  }

};

module.exports = PharmacyInventoryModel;
