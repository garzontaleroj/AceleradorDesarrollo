# Catálogo de Plantillas WSO2 — Base de Conocimiento TICXAR

Este directorio contiene plantillas reutilizables de integración WSO2 que sirven como
base de conocimiento para la fábrica de desarrollo de TICXAR y para capacitaciones.

## Estructura

```
templates/
├── README.md                          ← Este archivo
├── catalog.yaml                       ← Índice del catálogo de plantillas
│
├── micro-integrator/                  ← Plantillas para MI
│   ├── rest-api/                      ← APIs REST
│   │   ├── crud-api/                  ← API CRUD completa
│   │   ├── proxy-passthrough/         ← Proxy pass-through
│   │   └── api-with-auth/             ← API con autenticación OAuth2
│   ├── data-services/                 ← Servicios de datos
│   │   ├── mysql-crud/                ← CRUD con MySQL
│   │   └── postgres-crud/             ← CRUD con PostgreSQL
│   ├── message-patterns/              ← Patrones de mensajería
│   │   ├── content-based-router/      ← Enrutamiento por contenido
│   │   ├── message-splitter/          ← Splitter/Aggregator
│   │   └── store-and-forward/         ← Store and Forward
│   ├── connectors/                    ← Conectores comunes
│   │   ├── salesforce/                ← Integración Salesforce
│   │   ├── sap/                       ← Integración SAP
│   │   └── database-polling/          ← Polling de base de datos
│   └── error-handling/                ← Patrones de manejo de errores
│       ├── retry-with-backoff/        ← Reintentos con backoff
│       └── dead-letter-channel/       ← Canal de mensajes muertos
│
├── api-manager/                       ← Plantillas para APIM
│   ├── api-definitions/               ← Definiciones OpenAPI
│   │   ├── rest-crud/                 ← API CRUD estándar
│   │   └── graphql/                   ← API GraphQL
│   ├── policies/                      ← Políticas reutilizables
│   │   ├── rate-limiting/             ← Rate limiting
│   │   ├── request-validation/        ← Validación de request
│   │   └── response-caching/          ← Cache de respuestas
│   └── products/                      ← Productos API
│       └── standard-product/          ← Producto API estándar
│
├── identity-server/                   ← Plantillas para IS
│   ├── service-providers/             ← Configuraciones SP
│   │   ├── spa-oauth2/                ← SPA con OAuth2/OIDC
│   │   └── saml-webapp/               ← Webapp con SAML2
│   ├── identity-providers/            ← Proveedores de identidad
│   │   ├── azure-ad/                  ← Federación con Azure AD
│   │   └── google/                    ← Login con Google
│   ├── adaptive-auth/                 ← Scripts de autenticación adaptativa
│   │   ├── ip-based-2fa/              ← 2FA basado en IP
│   │   └── role-based-step-up/        ← Step-up por rol
│   └── identity7groups/               ← SCIM2 con grupos LDAP/AD
│       ├── README.md                  ← Guía completa
│       ├── deployment.toml            ← Config WSO2 IS 7.2.0
│       ├── docker-compose.yml         ← Escenario OpenLDAP
│       ├── docker-compose-ad.yml      ← Escenario Samba AD DC
│       ├── docs/                      ← Guías por escenario (LDAP, AD)
│       ├── ldif/                      ← Seed data LDAP
│       ├── samba-ad/                  ← Dockerfile + scripts Samba AD
│       ├── userstores/                ← XML userstores (LDAP)
│       ├── userstores-ad/             ← XML userstores (AD)
│       ├── init-claims*.sh/.bat       ← Scripts mapeo de claims
│       └── seed-scim-groups*.sh/.bat  ← Scripts seed SCIM2 grupos
│
├── streaming-integrator/              ← Plantillas para SI
│   ├── event-processing/              ← Procesamiento de eventos
│   │   ├── kafka-consumer/            ← Consumo desde Kafka
│   │   └── cdc-mysql/                 ← Change Data Capture MySQL
│   └── analytics/                     ← Analíticas
│       └── api-analytics/             ← Analíticas de API
│
└── ballerina/                         ← Plantillas Ballerina
    ├── http-service/                  ← Servicio HTTP
    ├── graphql-service/               ← Servicio GraphQL
    └── integration-service/           ← Servicio de integración
```

## Cómo usar una plantilla

### 1. Buscar en el catálogo
```bash
# Listar todas las plantillas disponibles
cat templates/catalog.yaml

# Buscar por categoría
grep -r "category: rest-api" templates/catalog.yaml
```

### 2. Copiar la plantilla
```bash
# Copiar plantilla a tu proyecto
cp -r templates/micro-integrator/rest-api/crud-api/ \
      projects/micro-integrator/src/main/synapse-config/api/mi-nueva-api/
```

### 3. Personalizar
Cada plantilla incluye:
- `README.md` con instrucciones de uso
- `template.yaml` / `template.xml` con el artefacto base
- `variables.yaml` con las variables a configurar
- `test/` con pruebas de ejemplo

### 4. Probar en Minikube
```bash
# Construir y desplegar solo MI
./scripts/minikube-demo.sh --product micro-integrator --build
```

## Cómo contribuir una plantilla

Ver [CONTRIBUTING.md](../docs/CONTRIBUTING.md) y seguir la guía de plantillas:

1. Crear directorio en la categoría correcta
2. Incluir `README.md`, artefacto, variables y tests
3. Registrar en `catalog.yaml`
4. Probar en Minikube antes de hacer PR
