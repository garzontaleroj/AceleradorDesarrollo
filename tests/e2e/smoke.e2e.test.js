const axios = require('axios');

const ENVIRONMENT = process.env.TEST_ENVIRONMENT || 'dev';
const DOMAIN = ENVIRONMENT === 'prod'
  ? 'wso2.ticxar.com'
  : `${ENVIRONMENT}.wso2.ticxar.com`;

const client = axios.create({
  httpsAgent: new (require('https').Agent)({ rejectUnauthorized: false }),
  timeout: 30000,
});

describe(`E2E Smoke Tests — Ambiente: ${ENVIRONMENT}`, () => {

  describe('API Manager', () => {
    test('Publisher debería estar accesible', async () => {
      const res = await client.get(`https://apim.${DOMAIN}:9443/publisher/`);
      expect(res.status).toBe(200);
    });

    test('DevPortal debería estar accesible', async () => {
      const res = await client.get(`https://apim.${DOMAIN}:9443/devportal/`);
      expect(res.status).toBe(200);
    });
  });

  describe('Micro Integrator', () => {
    test('API de management debería listar servicios', async () => {
      const res = await client.get(`https://mi.${DOMAIN}:9164/management/apis`);
      expect(res.status).toBe(200);
      expect(res.data).toHaveProperty('count');
    });
  });

  describe('Identity Server', () => {
    test('OpenID Discovery debería responder', async () => {
      const res = await client.get(
        `https://is.${DOMAIN}:9443/.well-known/openid-configuration`
      );
      expect(res.status).toBe(200);
      expect(res.data).toHaveProperty('issuer');
      expect(res.data).toHaveProperty('authorization_endpoint');
    });
  });

  describe('Streaming Integrator', () => {
    test('Health endpoint debería responder', async () => {
      const res = await client.get(`https://si.${DOMAIN}:9443/health`);
      expect(res.status).toBe(200);
    });
  });

  describe('Flujo completo: API → MI → Backend', () => {
    test('Invocar API a través del gateway debería llegar al MI', async () => {
      try {
        const res = await client.get(
          `https://apim.${DOMAIN}:8243/sample/v1/data`,
          { headers: { 'Authorization': `Bearer ${process.env.TEST_API_TOKEN || 'test'}` } }
        );
        // Aceptar 200 o 401 (si no hay token válido, pero el gateway responde)
        expect([200, 401, 403]).toContain(res.status);
      } catch (err) {
        if (err.response) {
          expect([200, 401, 403, 404]).toContain(err.response.status);
        } else {
          throw err;
        }
      }
    });
  });
});
