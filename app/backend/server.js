const express = require('express');
const mysql = require('mysql2');

const app = express();
const PORT = process.env.PORT || 3000;

const db = mysql.createConnection({
  host:     process.env.DB_HOST,
  user:     process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
});

db.connect((err) => {
  if (err) {
    console.error('Database connection failed:', err.message);
    return;
  }
  console.log('Connected to database layer');
});

app.get('/', (req, res) => {
  res.send('Backend application layer is running');
});

app.get('/health', (req, res) => {
  db.query('SELECT message FROM messages LIMIT 1', (err, results) => {
    if (err) {
      return res.status(500).json({ status: 'error', message: err.message });
    }
    const msg = results.length > 0 ? results[0].message : 'No data found';
    res.send(`Application layer connected to database: ${msg}`);
  });
});

app.listen(PORT, () => {
  console.log(`Backend app running on port ${PORT}`);
});
