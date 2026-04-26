// Migration to add professional verification support for doctors and pharmacies
// This migration adds verification fields to doctors and pharmacies tables

require('dotenv').config();
const pool = require('../config/db');

async function addProfessionalVerificationSupport() {
  console.log('🔧 Running professional verification support migration...');

  try {
    // Add verification fields to doctors table
    await pool.query(`
      ALTER TABLE doctors
      ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT false,
      ADD COLUMN IF NOT EXISTS verified_at TIMESTAMP WITH TIME ZONE,
      ADD COLUMN IF NOT EXISTS verified_by INTEGER REFERENCES users(user_id),
      ADD COLUMN IF NOT EXISTS verification_notes TEXT
    `);

    // Add verification fields to pharmacies table
    await pool.query(`
      ALTER TABLE pharmacies
      ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT false,
      ADD COLUMN IF NOT EXISTS verified_at TIMESTAMP WITH TIME ZONE,
      ADD COLUMN IF NOT EXISTS verified_by INTEGER REFERENCES users(user_id),
      ADD COLUMN IF NOT EXISTS verification_notes TEXT
    `);

    // Create disputes table for handling disputes
    await pool.query(`
      CREATE TABLE IF NOT EXISTS public.disputes (
        dispute_id SERIAL NOT NULL,
        user_id INTEGER NOT NULL,
        dispute_type VARCHAR(50) NOT NULL, -- 'prescription', 'appointment', 'pharmacy', 'doctor'
        related_id INTEGER NOT NULL, -- prescription_id, appointment_id, pharmacy_id, doctor_id
        description TEXT NOT NULL,
        status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'investigating', 'resolved', 'dismissed'
        priority VARCHAR(10) DEFAULT 'medium', -- 'low', 'medium', 'high', 'urgent'
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        resolved_by INTEGER REFERENCES users(user_id),
        resolution_notes TEXT,
        CONSTRAINT disputes_pkey PRIMARY KEY (dispute_id),
        CONSTRAINT disputes_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id)
      ) TABLESPACE pg_default;
    `);

    // Create indexes for better performance
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_doctors_is_verified ON doctors(is_verified);
      CREATE INDEX IF NOT EXISTS idx_pharmacies_is_verified ON pharmacies(is_verified);
      CREATE INDEX IF NOT EXISTS idx_disputes_status ON disputes(status);
      CREATE INDEX IF NOT EXISTS idx_disputes_type ON disputes(dispute_type);
    `);

    console.log('✅ Professional verification support migration completed');

  } catch (error) {
    console.error('❌ Error in professional verification migration:', error);
    throw error;
  } finally {
    pool.end();
  }
}

// Run the migration
addProfessionalVerificationSupport().catch(console.error);