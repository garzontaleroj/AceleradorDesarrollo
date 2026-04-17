# Plantilla: Retry con Exponential Backoff — Micro Integrator

## Descripción
Patrón de reintentos con backoff exponencial para llamadas a backends
inestables. Utiliza el endpoint con configuración de retry y suspensión
nativa de WSO2 MI para manejar fallos transitorios.

## Caso de uso
- Integración con servicios externos que pueden tener downtime intermitente
- APIs de terceros con rate limiting
- Backends que se recuperan tras breves períodos de inactividad

## Artefactos
| Archivo | Tipo | Descripción |
|---------|------|-------------|
| `RetryAPI.xml` | API | API con lógica de retry |
| `RetryEndpoint.xml` | Endpoint | Endpoint con backoff configurado |
| `variables.yaml` | Config | Variables de la plantilla |

## Variables
| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `API_NAME` | Nombre de la API | `ResilientOrderAPI` |
| `API_CONTEXT` | Contexto URL | `/orders` |
| `BACKEND_URL` | URL del backend | `http://flaky-service:8080/api` |
| `INITIAL_DURATION` | Delay inicial de suspensión (ms) | `1000` |
| `PROGRESSION_FACTOR` | Factor de incremento exponencial | `2` |
| `MAX_DURATION` | Delay máximo de suspensión (ms) | `60000` |
| `RETRY_COUNT` | Número de reintentos antes de suspender | `3` |
| `RETRY_DELAY` | Delay entre reintentos (ms) | `1000` |
| `TIMEOUT_DURATION` | Timeout de la conexión (ms) | `5000` |

## Comportamiento de retry
```
Intento 1: falla → esperar 1s → reintentar
Intento 2: falla → esperar 1s → reintentar
Intento 3: falla → SUSPENDER endpoint
  Suspensión: 1s → 2s → 4s → 8s → ... → máx 60s
Después de suspensión: volver a intentar
```
