# Plantilla: Observabilidad con OpenTelemetry + Jaeger — Micro Integrator

## Descripción
Configuración completa de trazabilidad distribuida para WSO2 Micro Integrator 4.3.0
usando OpenTelemetry como estándar de instrumentación y Jaeger como backend de trazas.

## Caso de uso
Visualizar el flujo de mediación completo dentro del Micro Integrator: APIs, secuencias,
endpoints y transformaciones. Identificar cuellos de botella, medir latencias de backends
y depurar errores en flujos de integración complejos.

## Artefactos

| Archivo | Tipo | Descripción |
|---------|------|-------------|
| `deployment.toml` | Configuración | Config de OpenTelemetry + estadísticas para MI |
| `docker-compose.yml` | Infraestructura | Stack MI + Jaeger listo para usar |

## Variables

| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `JAEGER_HOST` | Hostname del colector Jaeger | `jaeger` |
| `JAEGER_PORT` | Puerto del colector Jaeger (OTLP gRPC) | `4317` |
| `JAEGER_UI_PORT` | Puerto de la UI de Jaeger | `16686` |

## Configuración

### deployment.toml

Agregar las siguientes secciones al archivo `deployment.toml` del Micro Integrator:

```toml
# Habilitar captura de estadísticas de mediación (requerido para OpenTelemetry)
[mediation]
flow.statistics.capture_all = true
flow.statistics.enable = true

# Configuración de OpenTelemetry con Jaeger
[opentelemetry]
enable = true
logs = true
type = "jaeger"
host = "{{JAEGER_HOST}}"
port = "{{JAEGER_PORT}}"
```

> **Importante**: La sección `[mediation]` con `flow.statistics.capture_all = true`
> es **obligatoria** para que OpenTelemetry capture los spans de mediación.

### Docker Compose

El archivo `docker-compose.yml` incluido levanta:

- **WSO2 Micro Integrator 4.3.0** con OpenTelemetry habilitado
- **Jaeger All-in-One** como backend de trazas

```bash
# Levantar el stack
docker-compose up -d

# Verificar que los servicios estén levantados
docker-compose ps
```

## Acceso

| Servicio | URL | Descripción |
|----------|-----|-------------|
| MI HTTP Transport | http://localhost:8290 | APIs REST y proxy services |
| MI HTTPS Transport | https://localhost:8253 | APIs REST y proxy services (TLS) |
| MI Management API | https://localhost:9164 | API de gestión interna |
| Jaeger UI | http://localhost:16686 | Visualización de trazas |

## Pasos de verificación

1. Acceder a la UI de Jaeger en http://localhost:16686
2. En el selector **Service**, buscar `WSO2-MI` o `wso2-micro-integrator`
3. Invocar una API del MI en http://localhost:8290
4. Refrescar Jaeger UI y buscar las trazas generadas
5. Verificar que se muestren los spans de mediación (secuencias, mediadores, endpoints)

## Diagrama

```
Cliente → [MI HTTP :8290] → Mediación (secuencias, mediadores) → [Backend]
               │
               │ (OpenTelemetry OTLP)
               ▼
         [Jaeger :4317]
               │
               ▼
         [Jaeger UI :16686]
```

## Spans de mediación

Con OpenTelemetry habilitado y `flow.statistics.capture_all = true`, el MI
genera spans para cada paso de mediación:

- **API** — span padre por cada petición a la API
  - **Resource** — span del recurso invocado
    - **InSequence** — span de la secuencia de entrada
      - **Log Mediator** — span de cada mediador de log
      - **Call Mediator** — span de llamadas a endpoints
      - **Respond Mediator** — span de respuesta
    - **OutSequence** — span de la secuencia de salida
    - **FaultSequence** — span en caso de error

## Notas

- En producción, se recomienda usar **Jaeger con Elasticsearch** u otro backend
  persistente en lugar de `all-in-one`.
- `flow.statistics.capture_all = true` tiene un impacto menor en rendimiento.
  En producción con alta carga, considerar capturar solo estadísticas específicas.
- El MI también soporta `type = "zipkin"` y `type = "otlp"` como alternativas.

## Prerequisitos

- Docker 24+
- Docker Compose v2
- 2 GB RAM disponible mínimo
