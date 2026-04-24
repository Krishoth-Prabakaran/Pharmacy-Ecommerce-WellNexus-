const pool = require("../config/db");

const PharmacyModel = {
  // Create new pharmacy with transaction. If userData contains user_id, use the existing verified user.
  async create(pharmacyData, userData, branchesData = []) {
    const client = await pool.connect();

    try {
      await client.query('BEGIN');

      let userId;
      let userRecord;

      if (userData.user_id) {
        userId = userData.user_id;
        userRecord = {
          user_id: userData.user_id,
          username: userData.username,
          email: userData.email,
          role: userData.role
        };
      } else {
        const userResult = await client.query(
          `INSERT INTO users (username, email, password_hash, role, created_at)
           VALUES ($1, $2, $3, $4, NOW())
           RETURNING user_id, username, email, role`,
          [
            userData.username,
            userData.email.toLowerCase(),
            userData.password_hash,
            'pharmacist'
          ]
        );

        userId = userResult.rows[0].user_id;
        userRecord = userResult.rows[0];
      }

      // Create main pharmacy record (without location details - those go to branches)
      const pharmacyResult = await client.query(
        `INSERT INTO pharmacies (pharmacy_name, user_id)
         VALUES ($1, $2)
         RETURNING pharmacy_id, pharmacy_name`,
        [pharmacyData.pharmacy_name, userId]
      );

      const pharmacyId = pharmacyResult.rows[0].pharmacy_id;

      // Create branches
      if (branchesData.length === 0) {
        // If no branches provided, create a default main branch with the old data
        branchesData = [{
          branch_name: 'Main Branch',
          address: pharmacyData.address,
          phone: pharmacyData.phone,
          latitude: pharmacyData.latitude,
          longitude: pharmacyData.longitude,
          open_time: pharmacyData.open_time,
          close_time: pharmacyData.close_time,
          is_main_branch: true
        }];
      }

      for (const branch of branchesData) {
        await client.query(
          `INSERT INTO pharmacy_branches (
            pharmacy_id, branch_name, address, phone, latitude, longitude,
            open_time, close_time, is_main_branch
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
          [
            pharmacyId,
            branch.branch_name || 'Branch',
            branch.address,
            branch.phone,
            branch.latitude ?? null,
            branch.longitude ?? null,
            branch.open_time ?? null,
            branch.close_time ?? null,
            branch.is_main_branch ?? false
          ]
        );
      }

      await client.query('COMMIT');

      return {
        ...pharmacyResult.rows[0],
        email: userRecord.email,
        username: userRecord.username,
        role: userRecord.role,
        user_id: userId,
        branches: branchesData
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
        p.pharmacy_id, p.pharmacy_name,
        u.user_id, u.email, u.username, u.role
       FROM pharmacies p
       JOIN users u ON p.user_id = u.user_id
       WHERE u.email = $1`,
      [email.toLowerCase()]
    );

    if (result.rows.length === 0) {
      return null;
    }

    const pharmacy = result.rows[0];

    // Get branches
    const branchesResult = await pool.query(
      `SELECT branch_id, branch_name, address, phone, latitude, longitude,
              open_time, close_time, is_main_branch
       FROM pharmacy_branches
       WHERE pharmacy_id = $1
       ORDER BY is_main_branch DESC, branch_name`,
      [pharmacy.pharmacy_id]
    );

    return {
      ...pharmacy,
      branches: branchesResult.rows
    };
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
        p.pharmacy_id, p.pharmacy_name,
        u.user_id, u.email, u.username
       FROM pharmacies p
       JOIN users u ON p.user_id = u.user_id
       WHERE p.pharmacy_id = $1`,
      [pharmacyId]
    );

    if (result.rows.length === 0) {
      return null;
    }

    const pharmacy = result.rows[0];

    // Get branches
    const branchesResult = await pool.query(
      `SELECT branch_id, branch_name, address, phone, latitude, longitude,
              open_time, close_time, is_main_branch
       FROM pharmacy_branches
       WHERE pharmacy_id = $1
       ORDER BY is_main_branch DESC, branch_name`,
      [pharmacyId]
    );

    return {
      ...pharmacy,
      branches: branchesResult.rows
    };
  },

  // Get all pharmacies
  async findAll() {
    const result = await pool.query(
      `SELECT 
        p.pharmacy_id, p.pharmacy_name,
        u.email, u.username
       FROM pharmacies p
       JOIN users u ON p.user_id = u.user_id
       ORDER BY p.pharmacy_name`
    );

    // Get branches for each pharmacy
    const pharmaciesWithBranches = await Promise.all(
      result.rows.map(async (pharmacy) => {
        const branchesResult = await pool.query(
          `SELECT branch_id, branch_name, address, phone, latitude, longitude,
                  open_time, close_time, is_main_branch
           FROM pharmacy_branches
           WHERE pharmacy_id = $1
           ORDER BY is_main_branch DESC, branch_name`,
          [pharmacy.pharmacy_id]
        );

        return {
          ...pharmacy,
          branches: branchesResult.rows
        };
      })
    );

    return pharmaciesWithBranches;
  },

  // Update pharmacy
  async update(pharmacyId, updateData) {
    const client = await pool.connect();

    try {
      await client.query('BEGIN');

      // Update pharmacy name if provided
      if (updateData.pharmacy_name) {
        await client.query(
          'UPDATE pharmacies SET pharmacy_name = $1 WHERE pharmacy_id = $2',
          [updateData.pharmacy_name, pharmacyId]
        );
      }

      // Handle branch updates
      if (updateData.branches && Array.isArray(updateData.branches)) {
        // Delete existing branches
        await client.query('DELETE FROM pharmacy_branches WHERE pharmacy_id = $1', [pharmacyId]);

        // Insert new branches
        for (const branch of updateData.branches) {
          await client.query(
            `INSERT INTO pharmacy_branches (
              pharmacy_id, branch_name, address, phone, latitude, longitude,
              open_time, close_time, is_main_branch
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
            [
              pharmacyId,
              branch.branch_name || 'Branch',
              branch.address,
              branch.phone,
              branch.latitude ?? null,
              branch.longitude ?? null,
              branch.open_time ?? null,
              branch.close_time ?? null,
              branch.is_main_branch ?? false
            ]
          );
        }
      }

      await client.query('COMMIT');

      // Return updated pharmacy with branches
      return await this.findById(pharmacyId);

    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
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
        p.pharmacy_id, p.pharmacy_name,
        u.email, u.username,
        pb.branch_id, pb.branch_name, pb.address, pb.phone,
        pb.latitude, pb.longitude, pb.open_time, pb.close_time, pb.is_main_branch,
        (6371 * acos(
          cos(radians($1)) * 
          cos(radians(pb.latitude)) * 
          cos(radians(pb.longitude) - radians($2)) + 
          sin(radians($1)) * 
          sin(radians(pb.latitude))
        )) AS distance_km
       FROM pharmacies p
       JOIN users u ON p.user_id = u.user_id
       JOIN pharmacy_branches pb ON p.pharmacy_id = pb.pharmacy_id
       WHERE pb.latitude IS NOT NULL 
         AND pb.longitude IS NOT NULL
       HAVING (6371 * acos(
         cos(radians($1)) * 
         cos(radians(pb.latitude)) * 
         cos(radians(pb.longitude) - radians($2)) + 
         sin(radians($1)) * 
         sin(radians(pb.latitude))
       )) <= $3
       ORDER BY distance_km`,
      [latitude, longitude, radius]
    );

    // Group by pharmacy
    const pharmaciesMap = new Map();

    result.rows.forEach(row => {
      const pharmacyId = row.pharmacy_id;
      if (!pharmaciesMap.has(pharmacyId)) {
        pharmaciesMap.set(pharmacyId, {
          pharmacy_id: row.pharmacy_id,
          pharmacy_name: row.pharmacy_name,
          email: row.email,
          username: row.username,
          branches: []
        });
      }

      pharmaciesMap.get(pharmacyId).branches.push({
        branch_id: row.branch_id,
        branch_name: row.branch_name,
        address: row.address,
        phone: row.phone,
        latitude: row.latitude,
        longitude: row.longitude,
        open_time: row.open_time,
        close_time: row.close_time,
        is_main_branch: row.is_main_branch,
        distance_km: row.distance_km
      });
    });

    return Array.from(pharmaciesMap.values());
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
      'SELECT branch_id FROM pharmacy_branches WHERE phone = $1',
      [phone]
    );
    return result.rows.length > 0;
  },

  // Branch management methods
  async createBranch(pharmacyId, branchData) {
    const result = await pool.query(
      `INSERT INTO pharmacy_branches (
        pharmacy_id, branch_name, address, phone, latitude, longitude,
        open_time, close_time, is_main_branch
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      RETURNING *`,
      [
        pharmacyId,
        branchData.branch_name || 'New Branch',
        branchData.address,
        branchData.phone,
        branchData.latitude ?? null,
        branchData.longitude ?? null,
        branchData.open_time ?? null,
        branchData.close_time ?? null,
        branchData.is_main_branch ?? false
      ]
    );
    return result.rows[0];
  },

  async updateBranch(branchId, branchData) {
    const updates = [];
    const values = [];
    let paramCounter = 1;

    const allowedFields = [
      'branch_name', 'address', 'phone', 'latitude', 'longitude',
      'open_time', 'close_time', 'is_main_branch'
    ];

    allowedFields.forEach(field => {
      if (branchData[field] !== undefined) {
        updates.push(`${field} = $${paramCounter++}`);
        values.push(branchData[field]);
      }
    });

    if (updates.length === 0) {
      throw new Error('No fields to update');
    }

    values.push(branchId);

    const query = `
      UPDATE pharmacy_branches
      SET ${updates.join(', ')}
      WHERE branch_id = $${paramCounter}
      RETURNING *
    `;

    const result = await pool.query(query, values);
    return result.rows[0];
  },

  async deleteBranch(branchId) {
    const result = await pool.query(
      'DELETE FROM pharmacy_branches WHERE branch_id = $1 RETURNING *',
      [branchId]
    );
    return result.rows[0];
  },

  async getBranches(pharmacyId) {
    const result = await pool.query(
      `SELECT * FROM pharmacy_branches
       WHERE pharmacy_id = $1
       ORDER BY is_main_branch DESC, branch_name`,
      [pharmacyId]
    );
    return result.rows;
  },

  async setMainBranch(pharmacyId, branchId) {
    // First, set all branches for this pharmacy to not main
    await pool.query(
      'UPDATE pharmacy_branches SET is_main_branch = false WHERE pharmacy_id = $1',
      [pharmacyId]
    );

    // Then set the specified branch as main
    const result = await pool.query(
      'UPDATE pharmacy_branches SET is_main_branch = true WHERE branch_id = $1 AND pharmacy_id = $2 RETURNING *',
      [branchId, pharmacyId]
    );

    if (result.rows.length === 0) {
      throw new Error('Branch not found or does not belong to pharmacy');
    }

    return result.rows[0];
  },

  async getBranchesByBranchId(branchId) {
    const result = await pool.query(
      `SELECT pb.*, p.pharmacy_name
       FROM pharmacy_branches pb
       JOIN pharmacies p ON pb.pharmacy_id = p.pharmacy_id
       WHERE pb.branch_id = $1`,
      [branchId]
    );
    return result.rows;
  }
};