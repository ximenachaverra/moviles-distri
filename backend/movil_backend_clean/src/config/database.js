const { Pool } = require('pg');

// Use DATABASE_URL if available, otherwise build from individual env vars
let poolConfig;

if (process.env.DATABASE_URL) {
  // Parse DATABASE_URL and remove problematic query params
  let connString = process.env.DATABASE_URL;
  if (connString.includes('channel_binding')) {
    connString = connString.replace(/[&?]channel_binding=[^&]*/g, '');
  }
  if (connString.includes('sslmode=')) {
    connString = connString.replace(/[&?]sslmode=[^&]*/g, '');
  }
  poolConfig = {
    connectionString: connString,
    ssl: { rejectUnauthorized: false },
  };
} else {
  // Fallback to individual env variables
  poolConfig = {
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432'),
    database: process.env.DB_NAME || 'distriexpress',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || 'root',
    // Enable SSL for remote databases (AWS RDS, etc.)
    ssl: process.env.DB_HOST && !process.env.DB_HOST.includes('localhost')
      ? { rejectUnauthorized: false }
      : false,
  };
}

const pool = new Pool(poolConfig);

pool.on('connect', async (client) => {
  try {
    const schema = process.env.DB_SCHEMA || 'distriexpress';
    await client.query(`SET search_path TO "${schema}", public`);
    console.log(`✅ PostgreSQL conectado con schema "${schema}"`);
  } catch (err) {
    console.error('❌ Error al setear search_path:', err.message);
  }
});

// Simple connection test
pool.query('SELECT NOW()')
  .then(() => console.log('  PostgreSQL conectado correctamente'))
  .catch(e => console.error('  Error PostgreSQL:', e.message));

module.exports = {
  query: (text, params) => pool.query(text, params),
  pool,
};
