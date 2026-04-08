const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const ROOT = path.resolve(__dirname, '..', '..');

describe('Validación de estructura del proyecto', () => {
  const requiredDirs = [
    'projects/api-manager',
    'projects/micro-integrator',
    'projects/identity-server',
    'projects/streaming-integrator',
    'projects/ballerina',
    'infrastructure/docker',
    'infrastructure/kubernetes/base',
    'infrastructure/kubernetes/overlays/dev',
    'infrastructure/kubernetes/overlays/qa',
    'infrastructure/kubernetes/overlays/staging',
    'infrastructure/kubernetes/overlays/prod',
    'config/dev',
    'config/qa',
    'config/staging',
    'config/prod',
    'scripts',
  ];

  test.each(requiredDirs)('directorio %s debe existir', (dir) => {
    expect(fs.existsSync(path.join(ROOT, dir))).toBe(true);
  });
});

describe('Validación de archivos de configuración', () => {
  const products = ['mi', 'apim', 'is', 'si'];
  const environments = ['dev', 'qa', 'staging', 'prod'];

  environments.forEach((env) => {
    products.forEach((product) => {
      test(`config/${env}/${product}/deployment.toml debe existir`, () => {
        const filePath = path.join(ROOT, 'config', env, product, 'deployment.toml');
        expect(fs.existsSync(filePath)).toBe(true);
      });

      test(`config/${env}/${product}/deployment.toml debe contener hostname`, () => {
        const filePath = path.join(ROOT, 'config', env, product, 'deployment.toml');
        const content = fs.readFileSync(filePath, 'utf8');
        expect(content).toContain('hostname');
      });
    });
  });
});

describe('Validación de archivos XML (Synapse)', () => {
  const synapseDir = path.join(ROOT, 'projects', 'micro-integrator', 'src', 'main', 'synapse-config');

  test('archivos XML de Synapse deben ser well-formed', () => {
    if (!fs.existsSync(synapseDir)) return;

    const xmlFiles = [];
    const findXml = (dir) => {
      fs.readdirSync(dir, { withFileTypes: true }).forEach((entry) => {
        const full = path.join(dir, entry.name);
        if (entry.isDirectory()) findXml(full);
        else if (entry.name.endsWith('.xml')) xmlFiles.push(full);
      });
    };
    findXml(synapseDir);

    xmlFiles.forEach((file) => {
      const content = fs.readFileSync(file, 'utf8');
      // Verificar que tenga declaración o tag raíz XML
      expect(content.trim()).toMatch(/^<(\?xml|[a-zA-Z])/);
    });
  });
});

describe('Validación de Dockerfiles', () => {
  const products = ['api-manager', 'micro-integrator', 'identity-server', 'streaming-integrator'];

  test.each(products)('Dockerfile de %s debe existir', (product) => {
    const dockerfile = path.join(ROOT, 'infrastructure', 'docker', product, 'Dockerfile');
    expect(fs.existsSync(dockerfile)).toBe(true);
  });

  test.each(products)('Dockerfile de %s debe tener HEALTHCHECK', (product) => {
    const dockerfile = path.join(ROOT, 'infrastructure', 'docker', product, 'Dockerfile');
    const content = fs.readFileSync(dockerfile, 'utf8');
    expect(content).toContain('HEALTHCHECK');
  });
});
