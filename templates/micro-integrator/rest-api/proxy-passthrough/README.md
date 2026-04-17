# Plantilla: Proxy Pass-Through — Micro Integrator

## Descripción
Proxy transparente que reenvía peticiones al backend sin transformación.
Útil como punto de entrada centralizado con logging, métricas y control de acceso.

## Caso de uso
Exponer un servicio backend existente a través del MI para agregar logging,
throttling o seguridad sin modificar el servicio original.

## Artefactos
| Archivo | Tipo | Descripción |
|---------|------|-------------|
| `PassthroughProxy.xml` | Proxy | Proxy pass-through con logging |

## Variables
| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `PROXY_NAME` | Nombre del proxy | `ClientesSvcProxy` |
| `BACKEND_URL` | URL del backend | `http://legacy-service:8080/api` |
