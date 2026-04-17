# Plantilla: API REST CRUD — Micro Integrator

## Descripción
API REST completa con operaciones CRUD contra un backend HTTP.
Incluye manejo de errores centralizado, logging de request/response y endpoint configurable.

## Artefactos incluidos
| Archivo | Tipo | Descripción |
|---------|------|-------------|
| `CrudAPI.xml` | API | Definición de la API REST |
| `CrudBackendEP.xml` | Endpoint | Endpoint del backend |
| `CrudErrorHandler.xml` | Sequence | Manejo centralizado de errores |
| `variables.yaml` | Config | Variables a personalizar |

## Variables a configurar
| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `API_NAME` | Nombre de la API | `ClientesAPI` |
| `API_CONTEXT` | Contexto URL | `/clientes` |
| `BACKEND_URL` | URL del backend | `http://backend:8080/api` |
| `API_VERSION` | Versión | `v1` |

## Uso rápido

### 1. Copiar plantilla
```bash
# Desde la raíz del proyecto
cp -r templates/micro-integrator/rest-api/crud-api/ \
      projects/micro-integrator/src/main/synapse-config/api/MiNuevaAPI/
```

### 2. Personalizar variables
Editar los archivos XML reemplazando los placeholders:
- `{{API_NAME}}` → nombre de tu API
- `{{API_CONTEXT}}` → contexto URL
- `{{BACKEND_URL}}` → URL de tu backend
- `{{API_VERSION}}` → versión

### 3. Probar en Minikube
```bash
./scripts/minikube-demo.sh --product micro-integrator --build
kubectl port-forward svc/wso2-micro-integrator -n wso2-dev 8290:8290

# Probar endpoints
curl http://localhost:8290/{{API_CONTEXT}}/{{API_VERSION}}/items
curl -X POST http://localhost:8290/{{API_CONTEXT}}/{{API_VERSION}}/items \
  -H "Content-Type: application/json" \
  -d '{"name": "test"}'
```

## Diagrama de flujo
```
Cliente → [CrudAPI] → [CrudBackendEP] → Backend
                 ↓ (error)
          [CrudErrorHandler] → Respuesta de error JSON
```

## Patrones aplicados
- **Error Handling**: Secuencia de error reutilizable
- **Logging**: Log de entrada/salida con correlation ID
- **Health Check**: Endpoint `/health` para readiness probes
