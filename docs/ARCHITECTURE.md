# Arquitectura del Acelerador WSO2

## Visión General

```
┌─────────────────────────────────────────────────────────────────┐
│                        Clientes / Apps                          │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                    WSO2 API Manager                              │
│              (Gateway + Publisher + DevPortal)                    │
│                                                                  │
│  • Rate Limiting    • OAuth/JWT     • OpenAPI Management         │
│  • Analytics        • Monetización  • Versionado de APIs         │
└──────────────────────────┬──────────────────────────────────────┘
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
┌──────────────────┐ ┌──────────┐ ┌──────────────────┐
│ Micro Integrator │ │ Ballerina│ │    Backends       │
│                  │ │ Services │ │    Externos       │
│ • APIs REST/SOAP │ │          │ │                   │
│ • Mediaciones    │ │ • HTTP   │ │ • CRM             │
│ • Transformación │ │ • gRPC   │ │ • ERP             │
│ • Orquestación   │ │ • GraphQL│ │ • Legacy          │
└────────┬─────────┘ └────┬─────┘ └───────────────────┘
         │                │
         └────────┬───────┘
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                 WSO2 Streaming Integrator                        │
│                                                                  │
│  • Event Processing (Siddhi)    • CDC (Change Data Capture)      │
│  • Stream Analytics             • ETL en Tiempo Real             │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                  WSO2 Identity Server                            │
│                                                                  │
│  • OAuth 2.0 / OpenID Connect   • SAML 2.0                      │
│  • MFA / Auth Adaptiva          • Federación de Identidad        │
│  • User Management              • Claim Mapping                  │
└─────────────────────────────────────────────────────────────────┘
```

## Componentes del Acelerador

### Repositorio (este proyecto)

```
AceleradorDesarrollo/
│
├── projects/                    ← Artefactos por producto WSO2
│   ├── api-manager/             ← OpenAPIs, políticas
│   ├── micro-integrator/        ← Synapse XML (APIs, proxies, secuencias)
│   ├── identity-server/         ← IdPs, SPs, auth adaptiva
│   ├── streaming-integrator/    ← Siddhi apps
│   └── ballerina/               ← Servicios Ballerina
│
├── templates/                   ← Base de conocimiento (24 plantillas)
│   ├── catalog.yaml             ← Índice central del catálogo
│   ├── micro-integrator/        ← REST, data-services, patrones EIP, errores
│   ├── api-manager/             ← Definiciones OpenAPI, políticas
│   ├── identity-server/         ← SPs, IdPs, auth adaptiva
│   ├── streaming-integrator/    ← Event processing (Kafka, CDC)
│   ├── ballerina/               ← Servicios HTTP
│   ├── quarkus/                 ← REST API + Quickstarts (100+ ejemplos)
│   ├── spring-boot/             ← REST API
│   ├── python/                  ← FastAPI REST
│   ├── openshift/               ← Quickstart OCP
│   └── awesome-compose/         ← 40+ stacks Docker Compose
│
├── infrastructure/              ← Infraestructura como código
│   ├── docker/                  ← Dockerfiles por producto
│   └── kubernetes/              ← Kustomize (base + overlays)
│
├── config/                      ← deployment.toml por ambiente
│   ├── dev/ qa/ staging/ prod/
│
├── scripts/                     ← Automatización local
├── tests/                       ← Unit / Integration / E2E
├── docs/                        ← Documentación del proyecto
└── .github/                     ← CI/CD + templates
```

### Pipeline CI/CD

```
Developer                GitHub                        Kubernetes
   │                       │                              │
   │  push feature/*       │                              │
   │──────────────────────►│                              │
   │                       │  CI Pipeline                 │
   │                       │  ├─ XML validation           │
   │                       │  ├─ TOML validation          │
   │                       │  ├─ OpenAPI lint (Spectral)  │
   │                       │  ├─ Ballerina build+test     │
   │                       │  ├─ Dockerfile lint          │
   │                       │  ├─ K8s manifest validation  │
   │                       │  ├─ Security scan (Trivy)    │
   │                       │  └─ Secret scan (TruffleHog) │
   │                       │                              │
   │  merge PR → main      │                              │
   │──────────────────────►│                              │
   │                       │  CD DEV (automático)         │
   │                       │──────────────────────────────► wso2-dev
   │                       │                              │
   │  dispatch QA          │                              │
   │──────────────────────►│  CD QA + E2E tests           │
   │                       │──────────────────────────────► wso2-qa
   │                       │                              │
   │  dispatch STAGING     │  (requiere approval)         │
   │──────────────────────►│──────────────────────────────► wso2-staging
   │                       │                              │
   │  dispatch PROD        │  (requiere 2 approvals)      │
   │──────────────────────►│──────────────────────────────► wso2-prod
   │                       │  └─ Release tag + changelog  │
```

## Flujo de Datos Típico

### API REST → Micro Integrator → Backend

```
1. Cliente → APIM Gateway (autenticación JWT, rate limit)
2. APIM Gateway → MI API (routing por path)
3. MI → Secuencia de mediación:
   a. LoggingSequence (traza de entrada)
   b. Transformación de payload
   c. Llamada a endpoint backend
   d. Transformación de respuesta
   e. CommonErrorHandler (si hay error)
4. MI → APIM Gateway → Cliente
```

### Evento → Streaming Integrator → Acción

```
1. Source HTTP/Kafka → SI (Siddhi App)
2. Filtrado y enriquecimiento en memoria
3. Ventana temporal (time window)
4. Sink: Log, HTTP callback, Base de datos
```

### Autenticación Federada

```
1. App → IS (authorize endpoint)
2. IS → IdP externo (Google, Azure AD, etc.)
3. IdP → IS (callback con token)
4. IS → App (JWT con claims mapeados)
5. App → APIM (JWT en header Authorization)
6. APIM valida JWT y aplica políticas
```
## Puertos y Servicios Kubernetes

| Producto | Puerto | Protocolo | Uso |
|----------|--------|-----------|-----|
| **API Manager** | 9443 | HTTPS | Publisher, DevPortal, Admin Console |
| | 8243 | HTTPS | Gateway (producción) |
| | 8280 | HTTP | Gateway (sandbox) |
| **Micro Integrator** | 8290 | HTTP | HTTP Passthrough (APIs/proxies) |
| | 8253 | HTTPS | HTTPS Passthrough |
| | 9154 | HTTPS | Management API (interno) |
| **Identity Server** | 9443 | HTTPS | Console, OAuth/OIDC endpoints |
| **Streaming Integrator** | 9443 | HTTPS | Console |
| | 9090 | HTTP | Siddhi API |

> **Nota**: El Management API del MI (9154) requiere autenticación Basic y es solo
> para uso interno. Los probes de K8s usan tcpSocket en el puerto 8290.

## Catálogo de Plantillas

El directorio `templates/` contiene **24 plantillas reutilizables** organizadas por producto.
El archivo `templates/catalog.yaml` sirve como índice central con metadatos de cada plantilla
(dificultad, tiempo estimado, dependencias, tags).

| Producto | Plantillas | Categorías |
|----------|-----------|------------|
| Micro Integrator | 7 | REST API, Data Services, Message Patterns, Error Handling, Observabilidad |
| API Manager | 3 | Definiciones OpenAPI, Políticas, Observabilidad |
| Identity Server | 4 | Service Providers, Identity Providers, Auth Adaptiva, SCIM2 Grupos LDAP/AD |
| Streaming Integrator | 1 | Event Processing |
| Ballerina | 1 | HTTP Service |
| OpenChoreo | 1 | Platform Setup |
| Karate | 1 | API Testing |
| Quarkus | 2 | REST API, Quickstarts (100+ ejemplos oficiales) |
| Spring Boot | 1 | REST API |
| Python | 1 | FastAPI REST |
| OpenShift (OCP) | 1 | Quickstart (BuildConfig + Deploy + Route) |
| Docker Compose | 1 | Awesome Compose (40+ stacks multi-servicio) |

Las plantillas incluyen artefactos listos para copiar, archivos README con instrucciones
paso a paso, y guías de personalización. Ver [templates/README.md](../templates/README.md).
## Tecnologías

| Componente | Tecnología | Versión |
|------------|-----------|---------|
| API Management | WSO2 API Manager | 4.3.0 |
| Integración | WSO2 Micro Integrator | 4.3.0 |
| Identidad | WSO2 Identity Server | 7.0.0 |
| Streaming | WSO2 Streaming Integrator | 4.2.0 |
| Lenguaje | Ballerina | 2201.9.0 |
| Runtime | Java | 17 |
| Contenedores | Docker | 24+ |
| Orquestación | Kubernetes + Kustomize | 1.28+ |
| CI/CD | GitHub Actions | N/A |
| Registry | GitHub Container Registry | N/A |
| Seguridad | Trivy, TruffleHog | latest |
| Linting | Spectral, Hadolint, xmllint | latest |
