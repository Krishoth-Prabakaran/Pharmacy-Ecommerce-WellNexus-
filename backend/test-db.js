require('dotenv').config();
const pool = require('./config/db');

async function testConnection() {
  try {
    console.log('Testing database connection...');
    
    // Simple query to test connection
    const result = await pool.query('SELECT NOW() as current_time');
    console.log('✅ Database connected successfully!');
    console.log('Server time:', result.rows[0].current_time);
    
    // Check if users table exists and get count
    const users = await pool.query('SELECT COUNT(*) FROM users');
    console.log('✅ Users table exists');
    console.log('Total users in database:', users.rows[0].count);
    
    // Show sample users (without passwords)
    const sampleUsers = await pool.query(
      'SELECT user_id, username, email, role, is_active FROM users LIMIT 3'
    );
    console.log('Sample users:');
    sampleUsers.rows.forEach(user => {
      console.log(`  - ${user.username} (${user.email}): ${user.role}`);
    });
    
  } catch (err) {
    console.error('❌ Database connection failed:');
    console.error('Error:', err.message);
    console.error('Stack:', err.stack);
  } finally {
    await pool.end();
    process.exit();
  }
}

testConnection();