const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

// System-level health check
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    service: process.env.SERVICE_NAME || 'health-system-api',
    version: process.env.APP_VERSION || '1.0.0',
    environment: process.env.NODE_ENV || 'development',
  });
});

// Patient records endpoint (stub)
app.get('/api/patients', (req, res) => {
  res.status(200).json({ message: 'Patient records endpoint', data: [] });
});

// Appointments endpoint (stub)
app.get('/api/appointments', (req, res) => {
  res.status(200).json({ message: 'Appointments endpoint', data: [] });
});

// Vitals endpoint (stub)
app.get('/api/vitals', (req, res) => {
  res.status(200).json({ message: 'Vitals monitoring endpoint', data: [] });
});

app.listen(PORT, () => console.log(`Health System API running on port ${PORT}`));

module.exports = app;
