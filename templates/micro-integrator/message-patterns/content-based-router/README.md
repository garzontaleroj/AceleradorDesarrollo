# Plantilla: Content-Based Router — Micro Integrator

## Descripción
Enruta mensajes a diferentes backends según el contenido del payload.
Implementa el patrón Enterprise Integration Pattern **Content-Based Router**.

## Caso de uso
Un API recibe peticiones con un campo `type` que determina a qué servicio backend
se debe dirigir. Ejemplo: órdenes que se enrutan a diferentes sistemas según tipo de producto.

## Artefactos
| Archivo | Tipo | Descripción |
|---------|------|-------------|
| `ContentRouter.xml` | API | API con lógica de enrutamiento |

## Variables
| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `API_NAME` | Nombre de la API | `OrdenesRouterAPI` |
| `API_CONTEXT` | Contexto URL | `/ordenes` |
| `ROUTE_FIELD` | Campo JSON para enrutar | `$.type` |
| `BACKEND_A_URL` | URL backend ruta A | `http://svc-a:8080` |
| `BACKEND_B_URL` | URL backend ruta B | `http://svc-b:8080` |

## Diagrama
```
              ┌─ type=A → [Backend A]
Cliente → API ┤
              └─ type=B → [Backend B]
              └─ default → Error 400
```
