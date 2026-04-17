# Plantilla: Definición OpenAPI 3.0 REST CRUD — API Manager

## Descripción
Definición OpenAPI 3.0 estándar para una API CRUD. Importar directamente en WSO2 API Manager
para generar la API con documentación, schemas y respuestas de error predefinidas.

## Uso
1. Personalizar `openapi.yaml` con el nombre y campos de tu recurso
2. En API Manager Publisher → **Create API** → **Import OpenAPI**
3. Subir el archivo `openapi.yaml`
4. Configurar backend endpoint y políticas

## Variables
| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `API_TITLE` | Título de la API | `Clientes API` |
| `API_DESCRIPTION` | Descripción | `API para gestión de clientes` |
| `RESOURCE_NAME` | Nombre del recurso (singular) | `cliente` |
| `RESOURCE_NAME_PLURAL` | Nombre plural | `clientes` |
| `BASE_PATH` | Path base | `/api/v1` |
