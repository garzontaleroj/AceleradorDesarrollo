# WSO2 Development Accelerator

Acelerador de desarrollo para proyectos WSO2 con CI/CD automatizado usando **GitHub Flow** y **GitHub Actions**, despliegue en **Kubernetes** con **Docker**, y soporte para los 4 productos WSO2 + Ballerina.

## Productos Soportados

| Producto | Versión | Artefactos |
|----------|---------|------------|
| **API Manager** | 4.3.0 | OpenAPI specs, políticas XML |
| **Micro Integrator** | 4.3.0 | Synapse XML (APIs, proxies, secuencias, endpoints) |
| **Identity Server** | 7.0.0 | IdPs, Service Providers, Auth adaptiva |
| **Streaming Integrator** | 4.2.0 | Siddhi Apps |
| **Ballerina** | 2201.9.0 | Servicios HTTP, tests |

## Ambientes

| Ambiente | Trigger | Namespace K8s |
|----------|---------|---------------|
| **DEV** | Auto (merge a main) | `wso2-dev` |
| **QA** | Manual + E2E tests | `wso2-qa` |
| **STAGING** | Manual + aprobación | `wso2-staging` |
| **PROD** | Manual + 2 aprobaciones + release | `wso2-prod` |

## Estructura del Proyecto

```
AceleradorDesarrollo/
├── .github/
│   ├── workflows/
│   │   ├── ci.yml                    # CI: validación, lint, tests, seguridad
│   │   ├── cd-dev.yml                # CD → DEV (automático)
│   │   ├── cd-qa.yml                 # CD → QA (manual + E2E)
│   │   ├── cd-staging.yml            # CD → STAGING (manual + approval)
│   │   └── cd-prod.yml              # CD → PROD (manual + 2 approvals + release)
│   ├── PULL_REQUEST_TEMPLATE.md
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   └── feature_request.md
│   └── CODEOWNERS
│
├── projects/                          # Artefactos WSO2
│   ├── api-manager/
│   │   ├── apis/                      # Definiciones OpenAPI
│   │   ├── policies/                  # Políticas de gateway
│   │   └── certificates/
│   ├── micro-integrator/
│   │   └── src/main/synapse-config/
│   │       ├── api/                   # APIs REST/SOAP
│   │       ├── endpoints/             # Endpoints backend
│   │       ├── proxy-services/        # Proxy services
│   │       └── sequences/             # Secuencias reutilizables
│   ├── identity-server/
│   │   ├── identity-providers/        # Configuración IdPs
│   │   ├── service-providers/         # Configuración SPs
│   │   └── templates/                 # Scripts auth adaptiva
│   ├── streaming-integrator/
│   │   └── siddhi-apps/               # Aplicaciones Siddhi
│   └── ballerina/
│       ├── main.bal                   # Servicio HTTP
│       └── tests/                     # Tests Ballerina
│
├── infrastructure/
│   ├── docker/                        # Dockerfiles por producto
│   │   ├── api-manager/Dockerfile
│   │   ├── micro-integrator/Dockerfile
│   │   ├── identity-server/Dockerfile
│   │   ├── streaming-integrator/Dockerfile
│   │   └── docker-compose.yml         # Stack local completo
│   └── kubernetes/
│       ├── base/                      # Manifiestos base (Kustomize)
│       └── overlays/                  # Patches por ambiente
│           ├── dev/
│           ├── qa/
│           ├── staging/
│           └── prod/
│
├── config/                            # deployment.toml por ambiente
│   ├── dev/{apim,mi,is,si}/
│   ├── qa/{apim,mi,is,si}/
│   ├── staging/{apim,mi,is,si}/
│   └── prod/{apim,mi,is,si}/
│
├── scripts/
│   ├── setup.sh                       # Configurar entorno local
│   ├── build.sh                       # Construir imágenes Docker
│   ├── deploy.sh                      # Desplegar a K8s
│   ├── test.sh                        # Ejecutar tests
│   └── smoke-test.sh                  # Smoke tests post-deploy
│
├── tests/
│   ├── unit/                          # Validación estructura + XML
│   ├── integration/                   # Tests contra productos WSO2
│   └── e2e/                           # Tests end-to-end del stack
│
├── docs/
│   ├── ARCHITECTURE.md                # Diagrama de arquitectura
│   ├── GIT_WORKFLOW.md                # Guía de GitHub Flow
│   ├── CONTRIBUTING.md                # Guía de contribución
│   └── ENVIRONMENTS.md                # Detalle de ambientes
│
├── .gitignore
├── .editorconfig
└── .env.example
```

## Quick Start

### 1. Clonar y configurar

```bash
git clone https://github.com/ticxar/AceleradorDesarrollo.git
cd AceleradorDesarrollo
./scripts/setup.sh
```

### 2. Levantar stack local con Docker

```bash
docker-compose -f infrastructure/docker/docker-compose.yml up -d
```

### 3. Crear una rama y desarrollar

```bash
git checkout -b feature/mi-nuevo-servicio
# ... editar artefactos en projects/
git add .
git commit -m "feat(mi): agregar servicio de clientes"
git push origin feature/mi-nuevo-servicio
```

### 4. Crear Pull Request

El CI validará automáticamente:
- XML well-formed (Synapse configs)
- TOML válido (deployment configs)
- OpenAPI válido (Spectral)
- Dockerfiles (Hadolint)
- Manifiestos K8s (Kubeconform)
- Seguridad (Trivy + TruffleHog)

### 5. Merge → Deploy automático a DEV

Al hacer merge a `main`, el CD despliega automáticamente a DEV.

### 6. Promover a otros ambientes

```bash
# QA: desde GitHub Actions → workflow_dispatch
# STAGING: workflow_dispatch + approval
# PROD: workflow_dispatch + 2 approvals → crea release
```

## Scripts Disponibles

| Script | Descripción | Uso |
|--------|-------------|-----|
| `setup.sh` | Configurar entorno local | `./scripts/setup.sh` |
| `build.sh` | Construir imágenes Docker | `./scripts/build.sh all --tag v1.0.0 --env dev` |
| `deploy.sh` | Desplegar a K8s | `./scripts/deploy.sh qa --product micro-integrator` |
| `test.sh` | Ejecutar tests | `./scripts/test.sh unit` |
| `smoke-test.sh` | Smoke tests | `./scripts/smoke-test.sh dev` |

## GitHub Actions Workflows

| Workflow | Trigger | Descripción |
|----------|---------|-------------|
| `ci.yml` | PR a main | Validación completa + seguridad |
| `cd-dev.yml` | Merge a main | Deploy automático a DEV |
| `cd-qa.yml` | Manual | Deploy a QA + tests E2E |
| `cd-staging.yml` | Manual + approval | Deploy a STAGING |
| `cd-prod.yml` | Manual + 2 approvals | Deploy a PROD + release |

## Documentación

- [Arquitectura](docs/ARCHITECTURE.md) — Diagrama y flujos de datos
- [Git Workflow](docs/GIT_WORKFLOW.md) — GitHub Flow + Conventional Commits
- [Contribución](docs/CONTRIBUTING.md) — Guía para desarrolladores
- [Ambientes](docs/ENVIRONMENTS.md) — Configuración por ambiente

## Requisitos

| Herramienta | Versión |
|-------------|---------|
| Java JDK | 17+ |
| Docker | 24+ |
| kubectl | 1.28+ |
| Git | 2.40+ |
| Ballerina (opcional) | 2201.9.0 |
| Node.js (para tests) | 18+ |

## Equipos y CODEOWNERS

| Equipo | Responsabilidad |
|--------|-----------------|
| `@ticxar/apim-team` | API Manager |
| `@ticxar/mi-team` | Micro Integrator |
| `@ticxar/is-team` | Identity Server |
| `@ticxar/si-team` | Streaming Integrator |
| `@ticxar/ballerina-team` | Servicios Ballerina |
| `@ticxar/devops-team` | Infra, CI/CD, K8s |

---

**Ticxar** — Acelerador de Desarrollo WSO2
