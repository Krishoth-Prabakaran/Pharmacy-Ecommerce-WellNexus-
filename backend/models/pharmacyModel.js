const pool = require("../config/db");

const PharmacyModel = {
  // Create new pharmacy with transaction
  async create(pharmacyData, userData) {
    const client = await pool.connect();
    
    try {
      await client.query('BEGIN');
      
      // Insert into users table
      const userResult = await client.query(
        `INSERT INTO users (username, email, password_hash, role, created_at)
         VALUES ($1, $2, $3, $4, NOW())
         RETURNING user_id, username, email, role`,
        [userData.username, userData.email.toLowerCase(), userData.password_hash, 'pharmacy']
      );
      
      const userId = userResult.rows[0].user_id;
      
      // Insert into pharmacies table
      const pharmacyResult = await client.query(
        `INSERT INTO pharmacies (
          pharmacy_name, address, phone, latitude, longitude, 
          open_time, close_time, user_id
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        RETURNING 
          pharmacy_id, pharmacy_name, address, phone, 
          latitude, longitude, open_time, close_time`,
        [
          pharmacyData.pharmacy_name,
          pharmacyData.address,
          pharmacyData.phone,
          pharmacyData.latitude || null,
          pharmacyData.longitude || null,
          pharmacyData.open_time || null,
          pharmacyData.close_time || null,
          userId
        ]
      );
      
      await client.query('COMMIT');
      
      return {
        ...pharmacyResult.rows[0],
        email: userResult.rows[0].email,
        username: userResult.rows[0].username,
        role: userResult.rows[0].role
      };
      
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  },

  // Find pharmacy by email
  async findByEmail(email) {
    const result = await pool.query(
      `SELECT 
        p.pharmacy_id, p.pharmacy_name, p.address, p.phone,
        p.latitude, p.longitude, p.open_time, p.close_time,
        u.user_id, u.email, u.username, u.role
       FROM pharmacies p
       JOIN users u ON p.user_id = u.user_id
       WHERE u.email = $1`,
      [email.toLowerCase()]
    );
    return result.rows[0];
  },

  // Find pharmacy by phone
  async findByPhone(phone) {
    const result = await pool.query(
      `SELECT 
        p.pharmacy_id, p.pharmacy_name, p.address, p.phone,
        p.latitude, p.longitude, p.open_time, p.close_time,
        u.user_id, u.email, u.username
       FROM pharmacies p
       JOIN users u ON p.user_id = u.user_id
       WHERE p.phone = $1`,
      [phone]
    );
    return result.rows[0];
  },

  // Find pharmacy by ID
  async findById(pharmacyId) {
    const result = await pool.query(
      `SELECT 
        p.pharmacy_id, p.pharmacy_name, p.address, p.phone,
        p.latitude, p.longitude, p.open_time, p.close_time,
        u.user_id, u.email, u.username
       FROM pharmacies p
       JOIN users u ON p.user_id = u.user_id
       WHERE p.pharmacy_id = $1`,
      [pharmacyId]
    );
    return result.rows[0];
  },

  // Get all pharmacies
  async findAll() {
    const result = await pool.query(
      `SELECT 
        p.pharmacy_id, p.pharmacy_name, p.address, p.phone,
        p.latitude, p.longitude, p.open_time, p.close_time,
        u.email, u.username
       FROM pharmacies p
       JOIN users u ON p.user_id = u.user_id
       ORDER BY p.pharmacy_name`
    );
    return result.rows;
  },

  // Update pharmacy
  async update(pharmacyId, updateData) {
    const updates = [];
    const values = [];
    let paramCounter = 1;

    const allowedFields = [
      'pharmacy_name', 'address', 'phone', 'latitude', 
      'longitude', 'open_time', 'close_time'
    ];

    allowedFields.forEach(field => {
      if (updateData[field] !== undefined) {
        updates.push(`${field} = $${paramCounter++}`);
        values.push(updateData[field]);
      }
    });

    if (updates.length === 0) {
      throw new Error('No fields to update');
    }

    values.push(pharmacyId);

    const query = `
      UPDATE pharmacies 
      SET ${updates.join(', ')}
      WHERE pharmacy_id = $${paramCounter}
      RETURNING pharmacy_id, pharmacy_name, address, phone, 
                latitude, longitude, open_time, close_time
    `;

    const result = await pool.query(query, values);
    return result.rows[0];
  },

  // Delete pharmacy
  async delete(pharmacyId) {
    const client = await pool.connect();
    
    try {
      await client.query('BEGIN');
      
      // Get user_id first
      const pharmacyResult = await client.query(
        'SELECT user_id FROM pharmacies WHERE pharmacy_id = $1',
        [pharmacyId]
      );
      
      if (pharmacyResult.rows.length === 0) {
        throw new Error('Pharmacy not found');
      }
      
      const userId = pharmacyResult.rows[0].user_id;
      
      // Delete from pharmacies
      await client.query(
        'DELETE FROM pharmacies WHERE pharmacy_id = $1',
        [pharmacyId]
      );
      
      // Delete from users
      await client.query(
        'DELETE FROM users WHERE user_id = $1',
        [userId]
      );
      
      await client.query('COMMIT');
      return true;
      
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  },

  // Find nearby pharmacies
  async findNearby(latitude, longitude, radius = 10) {
    const result = await pool.query(
      `SELECT 
        p.pharmacy_id, p.pharmacy_name, p.address, p.phone,
        p.latitude, p.longitude, p.open_time, p.close_time,
        u.email, u.username,
        (6371 * acos(
          cos(radians($1)) * 
          cos(radians(p.latitude)) * 
          cos(radians(p.longitude) - radians($2)) + 
          sin(radians($1)) * 
          sin(radians(p.latitude))
        )) AS distance_km
       FROM pharmacies p
       JOIN users u ON p.user_id = u.user_id
       WHERE p.latitude IS NOT NULL 
         AND p.longitude IS NOT NULL
       HAVING (6371 * acos(
         cos(radians($1)) * 
         cos(radians(p.latitude)) * 
         cos(radians(p.longitude) - radians($2)) + 
         sin(radians($1)) * 
         sin(radians(p.latitude))
       )) <= $3
       ORDER BY distance_km`,
      [latitude, longitude, radius]
    );
    
    return result.rows;
  },

  // Check if email exists
  async emailExists(email) {
    const result = await pool.query(
      'SELECT user_id FROM users WHERE email = $1',
      [email.toLowerCase()]
    );
    return result.rows.length > 0;
  },

  // Check if username exists
  async usernameExists(username) {
    const result = await pool.query(
      'SELECT user_id FROM users WHERE username = $1',
      [username]
    );
    return result.rows.length > 0;
  },

  // Check if phone exists
  async phoneExists(phone) {
    const result = await pool.query(
      'SELECT pharmacy_id FROM pharmacies WHERE phone = $1',
      [phone]
    );
    return result.rows.length > 0;
  }
};

module.exports = PharmacyModel;