// Migration to ensure password reset support
// This migration documents the required schema changes for password reset functionality

const pool = require('../config/db');

async function addPasswordResetSupport() {
  console.log('🔧 Running password reset support migration...');

  try {
    // Check if the verification_token and verification_token_expires columns exist
    const result = await pool.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'users' 
      AND column_name IN ('verification_token', 'verification_token_expires')
    `);

    if (result.rows.length >= 2) {
      console.log('✅ Password reset columns already exist in users table');
      console.log('📋 Columns found:');
      result.rows.forEach(row => {
        console.log(`   - ${row.column_name}: ${row.data_type}`);
      });
    } else {
      console.log('⚠️ Missing required columns for password reset');
      console.log('📝 Please run the following SQL to add password reset support:');
      console.log(`
-- Add verification_token column (reused for password reset)
ALTER TABLE users ADD COLUMN IF NOT EXISTS verification_token VARCHAR(255);

-- Add verification_token_expires column (reused for password reset token expiry)
ALTER TABLE users ADD COLUMN IF NOT EXISTS verification_token_expires TIMESTAMP WITH TIME ZONE;
      `);
    }

    // Check if email_verified column exists
    const emailVerifiedResult = await pool.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'users' 
      AND column_name = 'email_verified'
    `);

    if (emailVerifiedResult.rows.length === 0) {
      console.log('⚠️ Missing email_verified column');
      console.log('📝 Please run the following SQL:');
      console.log(`
-- Add email_verified column for email verification status
ALTER TABLE users ADD COLUMN email_verified BOOLEAN DEFAULT false;
      `);
    } else {
      console.log('✅ email_verified column exists');
    }

    console.log('\n🔐 Password Reset Feature Summary:');
    console.log('=====================================');
    console.log('The password reset feature uses the existing verification_token');
    console.log('and verification_token_expires columns for both email verification');
    console.log('and password reset tokens.');
    console.log('');
    console.log('Flow:');
    console.log('1. User requests password reset via /api/auth/forgot-password');
    console.log('2. System generates a secure random token (64 hex characters)');
    console.log('3. Token is stored in verification_token with 1-hour expiry');
    console.log('4. Email with reset link is sent to user');
    console.log('5. User clicks link and is redirected to reset password screen');
    console.log('6. Token is verified and password is updated');
    console.log('7. Token is cleared after successful password reset');

  } catch (error) {
    console.error('❌ Migration error:', error.message);
  } finally {
    await pool.end();
  }
}

// Run the migration
addPasswordResetSupport();