# Plantilla: Framework de Testing con Karate — APIs WSO2

## Descripción
Plantilla de proyecto de pruebas automatizadas con [Karate](https://github.com/karatelabs/karate)
para validar APIs publicadas en WSO2 API Manager y servicios del Micro Integrator.

Karate es un framework de testing unificado (API, UI, performance, mocking) que usa
sintaxis Gherkin para escribir tests sin necesidad de código Java explícito.

## Caso de uso
Automatizar pruebas funcionales, de integración y de rendimiento de APIs WSO2:
- Validar respuestas HTTP de APIs publicadas en APIM Gateway
- Probar servicios REST expuestos por Micro Integrator
- Verificar transformaciones de datos y flujos de mediación
- Ejecutar pruebas de carga con Karate Gatling

## Artefactos

| Archivo | Tipo | Descripción |
|---------|------|-------------|
| `karate-config.js` | Configuración | Config global de Karate con URLs por entorno |
| `api-health.feature` | Test | Verificación de salud de APIs |
| `crud-operations.feature` | Test | Tests CRUD completos para una API REST |
| `pom.xml` | Build | Configuración Maven con dependencias de Karate |

## Variables

| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `APIM_GATEWAY_URL` | URL del Gateway de APIM | `https://localhost:8243` |
| `MI_HTTP_URL` | URL HTTP del Micro Integrator | `http://localhost:8290` |
| `API_CONTEXT` | Contexto base de la API a probar | `/customers/v1` |
| `ACCESS_TOKEN` | Token OAuth2 de acceso | `Bearer eyJ...` |

## Requisitos previos

- Java 11+ (JDK)
- Maven 3.6+
- WSO2 API Manager y/o Micro Integrator en ejecución

## Estructura del proyecto

```
karate/
├── pom.xml                    # Dependencias Maven (Karate + JUnit5)
├── karate-config.js           # Configuración global y variables de entorno
└── features/
    ├── api-health.feature     # Tests de salud y disponibilidad
    └── crud-operations.feature # Tests CRUD completos
```

## Ejecución

### Ejecutar todos los tests

```bash
mvn test
```

### Ejecutar un feature específico

```bash
mvn test -Dkarate.options="classpath:features/api-health.feature"
```

### Ejecutar por tags

```bash
mvn test -Dkarate.options="--tags @smoke"
```

### Seleccionar entorno

```bash
mvn test -Dkarate.env=qa
```

Los entornos disponibles (`dev`, `qa`, `staging`, `prod`) se configuran en `karate-config.js`.

## Reportes

Karate genera reportes HTML automáticamente tras la ejecución:

```
target/karate-reports/karate-summary.html
```

Abrir en el navegador para ver resultados detallados con tiempos, payloads y assertions.

## Diagrama

```
┌─────────────────┐     HTTP/HTTPS      ┌──────────────────┐
│                  │ ──────────────────→ │                  │
│   Karate Tests   │                     │   APIM Gateway   │
│   (.feature)     │ ←────────────────── │   :8243          │
│                  │    JSON Response     │                  │
└─────────────────┘                      └──────────────────┘
        │                                         │
        │              HTTP                       │ Proxy
        │ ──────────────────→ ┌──────────────────┐│
        │                     │                  ││
        └────────────────────→│   Micro          │←┘
                              │   Integrator     │
                              │   :8290          │
                              └──────────────────┘
```

## Notas

- Karate v2.0.2 soporta REST, GraphQL, SOAP, WebSocket y gRPC.
- Los archivos `.feature` usan sintaxis Gherkin extendida por Karate.
- No requiere escribir código Java; toda la lógica de test va en los `.feature`.
- Karate incluye mocking integrado para simular backends.
- Para tests de rendimiento, usar `karate-gatling` (compatible con Gatling).
- Licencia MIT — libre para uso comercial.
