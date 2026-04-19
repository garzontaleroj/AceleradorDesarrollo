// =============================================================================
// Plantilla: Configuración global de Karate para APIs WSO2
// Variables:
//   {{APIM_GATEWAY_URL}} - URL del Gateway de APIM (e.g., https://localhost:8243)
//   {{MI_HTTP_URL}}      - URL HTTP del MI (e.g., http://localhost:8290)
//   {{ACCESS_TOKEN}}     - Token OAuth2 (e.g., Bearer eyJ...)
// =============================================================================

function fn() {
  // Entorno: se puede pasar con -Dkarate.env=qa
  var env = karate.env || 'dev';
  karate.log('karate.env =', env);

  // Configuración base
  var config = {
    apiContext: '/customers/v1',
    connectTimeout: 10000,
    readTimeout: 15000
  };

  // Configuración por entorno
  if (env === 'dev') {
    config.apimGatewayUrl = '{{APIM_GATEWAY_URL}}';
    config.miHttpUrl = '{{MI_HTTP_URL}}';
    config.accessToken = '{{ACCESS_TOKEN}}';
  } else if (env === 'qa') {
    config.apimGatewayUrl = 'https://qa-gateway.example.com:8243';
    config.miHttpUrl = 'http://qa-mi.example.com:8290';
    config.accessToken = '';  // Obtener dinámicamente
  } else if (env === 'staging') {
    config.apimGatewayUrl = 'https://staging-gateway.example.com:8243';
    config.miHttpUrl = 'http://staging-mi.example.com:8290';
    config.accessToken = '';
  } else if (env === 'prod') {
    config.apimGatewayUrl = 'https://api.example.com';
    config.miHttpUrl = 'http://mi.example.com:8290';
    config.accessToken = '';
  }

  // URL completa de la API
  config.baseUrl = config.apimGatewayUrl + config.apiContext;
  config.miBaseUrl = config.miHttpUrl + config.apiContext;

  // Headers por defecto
  karate.configure('headers', {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  });

  // Timeouts
  karate.configure('connectTimeout', config.connectTimeout);
  karate.configure('readTimeout', config.readTimeout);

  // Deshabilitar verificación SSL para entornos de desarrollo
  if (env === 'dev') {
    karate.configure('ssl', { trustAll: true });
  }

  return config;
}
