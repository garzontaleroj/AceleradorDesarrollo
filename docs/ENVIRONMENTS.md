# Ambientes de Despliegue

## Resumen

| Ambiente | Propósito | Nivel de Log | Base de Datos | Réplicas | Aprobación |
|----------|-----------|-------------|---------------|----------|------------|
| **LOCAL** | Demos y desarrollo local | DEBUG | H2 (embebida) | 1 | N/A |
| **DEV** | Desarrollo y pruebas rápidas | DEBUG | H2 (embebida) | 1 | Automático |
| **QA** | Pruebas de integración y E2E | INFO | PostgreSQL | 2 | Manual |
| **STAGING** | Pre-producción, pruebas de carga | WARN | PostgreSQL | 2 | Manual + Approval |
| **PROD** | Producción | ERROR | PostgreSQL (HA) | 2-3 | Manual + 2 Approvals |

## Dominios por Ambiente

| Producto | LOCAL (port-forward) | DEV | QA | STAGING | PROD |
|----------|-----|-----|-----|---------|------|
| API Manager | `localhost:9443` | `apim.dev.wso2.ticxar.com` | `apim.qa.wso2.ticxar.com` | `apim.staging.wso2.ticxar.com` | `apim.wso2.ticxar.com` |
| Micro Integrator | `localhost:8290` | `mi.dev.wso2.ticxar.com` | `mi.qa.wso2.ticxar.com` | `mi.staging.wso2.ticxar.com` | `mi.wso2.ticxar.com` |
| Identity Server | `localhost:9444` | `is.dev.wso2.ticxar.com` | `is.qa.wso2.ticxar.com` | `is.staging.wso2.ticxar.com` | `is.wso2.ticxar.com` |
| Streaming Integrator | `localhost:9445` | `si.dev.wso2.ticxar.com` | `si.qa.wso2.ticxar.com` | `si.staging.wso2.ticxar.com` | `si.wso2.ticxar.com` |

## Namespaces de Kubernetes

| Ambiente | Namespace |
|----------|-----------|
| LOCAL | `wso2-dev` (reutiliza overlay dev) |
| DEV | `wso2-dev` |
| QA | `wso2-qa` |
| STAGING | `wso2-staging` |
| PROD | `wso2-prod` |

## LOCAL (Minikube)

Entorno de desarrollo local usando Minikube. Ideal para demos rápidas y validación
antes de subir cambios al cluster DEV.

### Requisitos

| Recurso | Mínimo | Recomendado |
|---------|--------|-------------|
| CPUs Minikube | 2 | 4 |
| Memoria | 4 GB | 8 GB |
| Disco | 20 GB | 40 GB |

### Recursos K8s por Producto

| Producto | CPU Request | Memoria Request | Notas |
|----------|------------|-----------------|-------|
| API Manager | 500m | 1 Gi | Requiere más memoria |
| Identity Server | 500m | 1 Gi | Requiere más memoria |
| Micro Integrator | 250m | 512 Mi | Ligero |
| Streaming Integrator | 250m | 512 Mi | Ligero |
| **Total (4 productos)** | **1500m** | **3 Gi** | Excede 2 CPUs |

> **Nota**: Con 2 CPUs de Minikube, usar `--product` para desplegar un solo producto.

### Acceso a Servicios

| Producto | Comando de acceso | URL local |
|----------|-------------------|-----------|
| API Manager | `kubectl port-forward svc/wso2-api-manager -n wso2-dev 9443:9443 8243:8243 8280:8280` | `https://localhost:9443/carbon` |
| Micro Integrator | `kubectl port-forward svc/wso2-micro-integrator -n wso2-dev 8290:8290 8253:8253` | `http://localhost:8290/services` |
| Identity Server | `kubectl port-forward svc/wso2-identity-server -n wso2-dev 9444:9443` | `https://localhost:9444/console` |
| Streaming Integrator | `kubectl port-forward svc/wso2-streaming-integrator -n wso2-dev 9445:9443 9090:9090` | `https://localhost:9445/carbon` |

> **Nota**: IS usa puerto local `9444` y SI usa `9445` para evitar conflicto con APIM en `9443`.

### Puertos por Producto

| Producto | Puerto | Protocolo | Uso |
|----------|--------|-----------|-----|
| **API Manager** | 9443 | HTTPS | Publisher, DevPortal, Admin |
| | 8243 | HTTPS | Gateway (producción) |
| | 8280 | HTTP | Gateway (sandbox) |
| **Micro Integrator** | 8290 | HTTP | HTTP Passthrough (APIs/proxies) |
| | 8253 | HTTPS | HTTPS Passthrough |
| | 9154 | HTTPS | Management API (interno, Basic auth) |
| **Identity Server** | 9443 | HTTPS | Console, OAuth/OIDC endpoints |
| **Streaming Integrator** | 9443 | HTTPS | Console |
| | 9090 | HTTP | Siddhi API |

### Uso Rápido

```bash
# Opción 1: Desplegar un solo producto (recomendado con 2 CPUs)
& "C:\Program Files\Git\bin\bash.exe" scripts/minikube-demo.sh --build --product micro-integrator

# Opción 2: Desplegar todo el stack (requiere 4+ CPUs)
& "C:\Program Files\Git\bin\bash.exe" scripts/minikube-demo.sh --build

# Operaciones
& "C:\Program Files\Git\bin\bash.exe" scripts/minikube-demo.sh --status
& "C:\Program Files\Git\bin\bash.exe" scripts/minikube-demo.sh --logs micro-integrator
& "C:\Program Files\Git\bin\bash.exe" scripts/minikube-demo.sh --clean
```

> **Importante**: En Windows usar **Git Bash**, no WSL. WSL no tiene acceso al Minikube de Windows.

## DEV

**Propósito**: Validación rápida de cambios tras merge a `main`.

- **Despliegue**: Automático al hacer merge de PR a `main`
- **Base de datos**: H2 embebida (sin dependencias externas)
- **CORS**: Permite todos los orígenes (`*`)
- **Logging**: `DEBUG` — máxima verbosidad
- **Réplicas**: 1 por producto
- **Recursos K8s**: CPU 250m-500m, Memoria 512Mi-1Gi
- **Secretos**: Valores por defecto (wso2carbon)

### Cuándo usar
- Verificar que artefactos nuevos se despliegan correctamente
- Debugging de mediaciones y flujos
- Pruebas de humo rápidas

## QA

**Propósito**: Pruebas de integración y funcionales con stack completo.

- **Despliegue**: Manual via `workflow_dispatch` con `image_tag`
- **Base de datos**: PostgreSQL compartida
- **CORS**: Restringido a `portal.qa.wso2.ticxar.com`
- **Logging**: `INFO`
- **Réplicas**: 2 por producto
- **Recursos K8s**: CPU 250m-500m, Memoria 512Mi-1Gi
- **Tests**: E2E automáticos post-despliegue

### Cuándo usar
- Ejecutar suite completa de tests de integración
- Validar flujos entre productos (APIM → MI → Backend)
- Pruebas de autenticación con IS

## STAGING

**Propósito**: Réplica de producción para validación final.

- **Despliegue**: Manual con aprobación requerida
- **Base de datos**: PostgreSQL (misma configuración que prod)
- **CORS**: Restringido a dominio de staging
- **Logging**: `WARN`
- **Réplicas**: 2 por producto
- **Recursos K8s**: CPU 500m-1000m, Memoria 1Gi-2Gi
- **Analytics**: Habilitado
- **Throttling**: Habilitado

### Cuándo usar
- Pruebas de rendimiento y carga
- Validación de configuración de producción
- Pruebas de procedimientos de rollback
- Demo para stakeholders

## PROD

**Propósito**: Ambiente de producción en vivo.

- **Despliegue**: Manual con 2 aprobaciones + release tag
- **Base de datos**: PostgreSQL con HA
- **CORS**: Restringido a dominio de producción
- **Logging**: `ERROR` — solo errores
- **Réplicas**: 2-3 por producto (con HPA)
- **Recursos K8s**: CPU 500m-2000m, Memoria 1Gi-4Gi
- **HA**: Streaming Integrator con nodo pasivo
- **Pool de conexiones**: maxActive=150, validación continua
- **Backups**: Automáticos antes de cada despliegue

### Procedimiento de despliegue

1. Verificar que la versión pasó QA y STAGING
2. Ejecutar workflow `cd-prod.yml` con `image_tag` y `release_version`
3. Aprobar el despliegue (2 aprobadores)
4. El workflow:
   - Ejecuta pre-checks
   - Hace backup del estado actual
   - Despliega con Kustomize
   - Ejecuta smoke tests
   - Crea GitHub Release con changelog
   - Re-tagea imágenes Docker

### Rollback

```bash
# Rollback rápido al deployment anterior
kubectl rollout undo deployment/wso2-<producto> -n wso2-prod

# Rollback a versión específica
./scripts/deploy.sh prod --tag <version-anterior>
```

## Configuración por Ambiente

Todos los archivos de configuración están en:

```
config/
├── dev/
│   ├── apim/deployment.toml
│   ├── mi/deployment.toml
│   ├── is/deployment.toml
│   └── si/deployment.toml
├── qa/
│   └── ...
├── staging/
│   └── ...
└── prod/
    └── ...
```

### Variables Sensibles

Las credenciales **nunca** se almacenan en los archivos de configuración. Se usan:

- `$secret{nombre}` en deployment.toml → resuelto por WSO2 Secure Vault
- Kubernetes Secrets → montados como volúmenes
- GitHub Actions Secrets → inyectados en CI/CD
