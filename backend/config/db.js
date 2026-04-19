const { Pool } = require("pg");

// For Supabase (hosted PostgreSQL), we need to accept self-signed certificates
// regardless of NODE_ENV, as Supabase uses self-signed certs
const sslConfig = {
  rejectUnauthorized: false
};

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: sslConfig,
});

module.exports = pool;
