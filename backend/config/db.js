const { Pool } = require("pg");

// Determine SSL configuration based on environment
const isProduction = process.env.NODE_ENV === 'production';
const sslConfig = isProduction
  ? { rejectUnauthorized: false } // For hosted databases like Heroku
  : false; // For local development

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: sslConfig,
});

module.exports = pool;
