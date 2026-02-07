
const { Pool } = require('pg');

// Database connection pool
// Pool manages multiple database connections efficiently
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: false
  }
});

// Test the database connection
pool.connect((err, client, release) => {
  if (err) {
    console.error('Database connection failed:', err.stack);
  } else {
    console.log('PostgreSQL connected successfully');
    release(); // Release the client back to the pool
  }
});

module.exports = pool;