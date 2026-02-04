const { Pool } = require('pg');

// Database connection pool
// Pool manages multiple database connections efficiently
const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'signalgrid_db',
  password: 'Ouma@218',
  port: 5432,                 // PostgreSQL default port
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