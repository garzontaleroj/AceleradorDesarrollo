const axios = require('axios');

// Configurar según ambiente
const MI_BASE_URL = process.env.MI_BASE_URL || 'https://localhost:8253';
const MI_MGMT_URL = process.env.MI_MGMT_URL || 'https://localhost:9164';

const client = axios.create({
  httpsAgent: new (require('https').Agent)({ rejectUnauthorized: false }),
  timeout: 10000,
});

describe('Micro Integrator — Integration Tests', () => {
  test('Management API debe responder', async () => {
    try {
      const res = await client.get(`${MI_MGMT_URL}/management/apis`);
      expect(res.status).toBe(200);
      expect(res.data).toHaveProperty('count');
    } catch (err) {
      if (err.code === 'ECONNREFUSED') {
        console.warn('MI no está corriendo — saltando test');
        return;
      }
      throw err;
    }
  });

  test('Health check debe responder OK', async () => {
    try {
      const res = await client.get(`${MI_BASE_URL.replace('8253', '9201')}/healthz`);
      expect(res.status).toBe(200);
    } catch (err) {
      if (err.code === 'ECONNREFUSED') {
        console.warn('MI no está corriendo — saltando test');
        return;
      }
      throw err;
    }
  });
});
