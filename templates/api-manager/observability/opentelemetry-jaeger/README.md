# Plantilla: Observabilidad con OpenTelemetry + Jaeger — API Manager

## Descripción
Configuración completa de trazabilidad distribuida para WSO2 API Manager 4.3.0
usando OpenTelemetry como estándar de instrumentación y Jaeger como backend de trazas.

## Caso de uso
Visualizar el flujo completo de las peticiones a través del API Gateway, identificar
cuellos de botella, medir latencias y depurar errores en entornos de desarrollo y QA.

## Artefactos

| Archivo | Tipo | Descripción |
|---------|------|-------------|
| `deployment.toml` | Configuración | Config de OpenTelemetry para APIM |
| `docker-compose.yml` | Infraestructura | Stack APIM + Jaeger listo para usar |

## Variables

| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `JAEGER_HOST` | Hostname del colector Jaeger | `jaeger` |
| `JAEGER_PORT` | Puerto del colector Jaeger (OTLP gRPC) | `4317` |
| `JAEGER_UI_PORT` | Puerto de la UI de Jaeger | `16686` |
| `APIM_HOSTNAME` | Hostname del API Manager | `localhost` |

## Configuración

### deployment.toml

Agregar la siguiente sección al archivo `deployment.toml` del API Manager:

```toml
[apim.open_telemetry]
remote_tracer.enable = true
remote_tracer.name = "jaeger"
remote_tracer.hostname = "{{JAEGER_HOST}}"
remote_tracer.port = "{{JAEGER_PORT}}"
```

### Docker Compose

El archivo `docker-compose.yml` incluido levanta:

- **WSO2 API Manager 4.3.0** con OpenTelemetry habilitado
- **Jaeger All-in-One** como backend de trazas

```bash
# Levantar el stack
docker-compose up -d

# Verificar que los servicios estén levantados
docker-compose ps
```

## Acceso

| Servicio | URL | Credenciales |
|----------|-----|-------------|
| APIM Publisher | https://localhost:9443/publisher | admin / admin |
| APIM DevPortal | https://localhost:9443/devportal | admin / admin |
| APIM Gateway (HTTPS) | https://localhost:8243 | — |
| APIM Gateway (HTTP) | http://localhost:8280 | — |
| Jaeger UI | http://localhost:16686 | — |

## Pasos de verificación

1. Acceder a la UI de Jaeger en http://localhost:16686
2. En el selector **Service**, buscar `WSO2-APIM` o `APIM-GATEWAY`
3. Invocar una API a través del gateway (puerto 8243 o 8280)
4. Refrescar Jaeger UI y buscar las trazas generadas
5. Verificar que se muestren los spans con tiempos de respuesta

## Diagrama

```
Cliente → [APIM Gateway :8243] → [Backend]
               │
               │ (OpenTelemetry OTLP gRPC)
               ▼
         [Jaeger :4317]
               │
               ▼
         [Jaeger UI :16686]
```

## Notas

- En producción, se recomienda usar **Jaeger con Elasticsearch** u otro backend de almacenamiento
  en lugar de `all-in-one` (que usa almacenamiento en memoria).
- El puerto OTLP gRPC (4317) es el estándar de OpenTelemetry. Jaeger lo soporta nativamente
  desde la versión 1.35+.
- Para un sampling más controlado en producción, configurar `remote_tracer.properties`:
  ```toml
  [apim.open_telemetry.remote_tracer.properties]
  ratio = "0.1"   # Muestrear 10% de las trazas
  ```

## Prerequisitos

- Docker 24+
- Docker Compose v2
- 4 GB RAM disponible mínimo
