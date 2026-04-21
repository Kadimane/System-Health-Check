const request = require('supertest');
const app = require('./server');

describe('Health System API', () => {
  describe('GET /health', () => {
    it('returns 200 with status ok', async () => {
      const res = await request(app).get('/health');
      expect(res.statusCode).toBe(200);
      expect(res.body.status).toBe('ok');
      expect(res.body.service).toBe('health-system-api');
    });
  });

  describe('GET /api/patients', () => {
    it('returns 200', async () => {
      const res = await request(app).get('/api/patients');
      expect(res.statusCode).toBe(200);
    });
  });

  describe('GET /api/appointments', () => {
    it('returns 200', async () => {
      const res = await request(app).get('/api/appointments');
      expect(res.statusCode).toBe(200);
    });
  });

  describe('GET /api/vitals', () => {
    it('returns 200', async () => {
      const res = await request(app).get('/api/vitals');
      expect(res.statusCode).toBe(200);
    });
  });
});
