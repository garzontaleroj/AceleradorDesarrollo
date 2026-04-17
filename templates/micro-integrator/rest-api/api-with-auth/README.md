# Plantilla: API con Autenticación OAuth2 — Micro Integrator

## Descripción
API REST protegida con validación de tokens OAuth2 Bearer emitidos por
WSO2 Identity Server. Cada petición se valida contra el endpoint de
introspección del IS antes de continuar al backend.

## Caso de uso
APIs internas que requieren autenticación y autorización basada en tokens
dentro del ecosistema WSO2.

## Artefactos
| Archivo | Tipo | Descripción |
|---------|------|-------------|
| `SecureAPI.xml` | API | API protegida con validación OAuth2 |
| `TokenValidationSeq.xml` | Sequence | Secuencia de validación de token |
| `variables.yaml` | Config | Variables de la plantilla |

## Variables
| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `API_NAME` | Nombre de la API | `SecureCustomerAPI` |
| `API_CONTEXT` | Contexto URL | `/secure/customers` |
| `API_VERSION` | Versión | `v1` |
| `BACKEND_URL` | URL del backend | `http://backend:8080/api` |
| `IS_HOST` | Hostname del IS | `is.local` |
| `IS_PORT` | Puerto del IS | `9443` |

## Flujo de autenticación
```
1. Cliente → MI: Request con Authorization: Bearer <token>
2. MI → IS: POST /oauth2/introspect (validar token)
3. IS → MI: Token info (active: true/false, scopes, user)
4. Si válido → MI → Backend: Forward request
5. Si inválido → MI → Cliente: 401 Unauthorized
```
