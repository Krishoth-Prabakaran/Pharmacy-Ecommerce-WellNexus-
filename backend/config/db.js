const { Pool } = require("pg");
const tls = require("tls");
require('dotenv').config();

// Disable SSL validation globally for development
if (process.env.NODE_ENV !== 'production') {
  process.env.NODE_TLS_REJECT_UNAUTHORIZED = 0;
}

// Parse DATABASE_URL or use individual parameters
let poolConfig;

if (process.env.DATABASE_URL) {
  // For remote databases like Supabase
  let connectionString = process.env.DATABASE_URL;
  
  // Remove sslmode parameter from URL to avoid conflicts with pool SSL config
  connectionString = connectionString.replace(/[\?&]sslmode=require/g, '');
  
  // Configure SSL through pool config instead
  poolConfig = {
    connectionString: connectionString,
    ssl: {
      rejectUnauthorized: false,
    },
  };
  
  console.log('🔗 Database Connection:');
  console.log('   Type: Remote (Supabase/AWS)');
  console.log('   SSL Enabled: Yes');
  console.log('   NODE_ENV:', process.env.NODE_ENV);
} else {
  // Fallback to individual environment variables (local development)
  poolConfig = {
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME || 'wellnexus',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD,
    ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
  };
  
  console.log('🔗 Database Connection:');
  console.log('   Type: Local');
}

const pool = new Pool(poolConfig);

pool.on('error', (err) => {
  console.error('❌ Unexpected error on idle client in pool:', err.message);
  console.error('   Stack:', err.stack);
});

module.exports = pool;
