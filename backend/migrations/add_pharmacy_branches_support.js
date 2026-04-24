// Migration to add pharmacy branches support
// This migration creates a pharmacy_branches table to allow pharmacies to have multiple locations

require('dotenv').config();
const pool = require('../config/db');

async function addPharmacyBranchesSupport() {
  console.log('🔧 Running pharmacy branches support migration...');

  try {
    // Create pharmacy_branches table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS public.pharmacy_branches (
        branch_id SERIAL NOT NULL,
        pharmacy_id INTEGER NOT NULL,
        branch_name VARCHAR(100),
        address TEXT NOT NULL,
        phone VARCHAR(15) NOT NULL,
        latitude DOUBLE PRECISION,
        longitude DOUBLE PRECISION,
        open_time TIME,
        close_time TIME,
        is_main_branch BOOLEAN DEFAULT false,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        CONSTRAINT pharmacy_branches_pkey PRIMARY KEY (branch_id),
        CONSTRAINT pharmacy_branches_pharmacy_id_fkey FOREIGN KEY (pharmacy_id)
          REFERENCES pharmacies (pharmacy_id) ON DELETE CASCADE,
        CONSTRAINT pharmacy_branches_phone_key UNIQUE (phone)
      ) TABLESPACE pg_default;
    `);

    // Create index for better performance
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_pharmacy_branches_pharmacy_id
      ON public.pharmacy_branches USING BTREE (pharmacy_id) TABLESPACE pg_default;
    `);

    // Migrate existing pharmacy data to branches
    // First, check if there are existing pharmacies
    const existingPharmacies = await pool.query(`
      SELECT pharmacy_id, address, phone, latitude, longitude, open_time, close_time
      FROM pharmacies
      WHERE pharmacy_id NOT IN (SELECT DISTINCT pharmacy_id FROM pharmacy_branches)
    `);

    if (existingPharmacies.rows.length > 0) {
      console.log(`📦 Migrating ${existingPharmacies.rows.length} existing pharmacies to branches...`);

      for (const pharmacy of existingPharmacies.rows) {
        await pool.query(`
          INSERT INTO pharmacy_branches (
            pharmacy_id, branch_name, address, phone, latitude, longitude,
            open_time, close_time, is_main_branch
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        `, [
          pharmacy.pharmacy_id,
          'Main Branch', // Default branch name
          pharmacy.address,
          pharmacy.phone,
          pharmacy.latitude,
          pharmacy.longitude,
          pharmacy.open_time,
          pharmacy.close_time,
          true // Mark as main branch
        ]);
      }

      console.log('✅ Migration completed successfully');
    } else {
      console.log('ℹ️ No existing pharmacies to migrate or already migrated');
    }

    // Optional: Remove old columns from pharmacies table (commented out for safety)
    // This would be done in a separate migration after confirming everything works
    /*
    console.log('⚠️ Consider removing redundant columns from pharmacies table in a future migration:');
    console.log('   - address, phone, latitude, longitude, open_time, close_time');
    console.log('   These are now stored in pharmacy_branches table');
    */

    console.log('✅ Pharmacy branches support migration completed');

  } catch (error) {
    console.error('❌ Error in pharmacy branches migration:', error);
    throw error;
  } finally {
    pool.end();
  }
}

// Run the migration
addPharmacyBranchesSupport().catch(console.error);