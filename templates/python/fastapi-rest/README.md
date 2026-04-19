# Plantilla: API REST con Python + FastAPI

## Descripción

Proyecto base de API REST con [FastAPI](https://fastapi.tiangolo.com/), el framework moderno y de alto rendimiento
para Python. Incluye endpoints CRUD, documentación OpenAPI automática (Swagger UI + ReDoc),
validación con Pydantic, health check, y tests con pytest.

## Estructura

```
fastapi-rest/
├── README.md                ← Este archivo
├── requirements.txt         ← Dependencias Python
├── app/
│   ├── __init__.py
│   ├── main.py              ← Aplicación FastAPI con rutas
│   ├── models.py            ← Modelos Pydantic
│   └── service.py           ← Lógica de negocio (CRUD in-memory)
└── tests/
    ├── __init__.py
    └── test_main.py         ← Tests con pytest + httpx
```

## Requisitos

| Herramienta | Versión |
|-------------|---------|
| Python      | 3.10+   |
| pip         | 23+     |

## Inicio Rápido

### 1. Copiar la plantilla

```bash
cp -r templates/python/fastapi-rest/ projects/python/mi-servicio/
cd projects/python/mi-servicio/
```

### 2. Crear entorno virtual e instalar dependencias

```bash
python -m venv .venv
source .venv/bin/activate   # Linux/Mac
# .venv\Scripts\activate    # Windows
pip install -r requirements.txt
```

### 3. Ejecutar en desarrollo

```bash
uvicorn app.main:app --reload --port 8082
```

La aplicación estará disponible en:
- API: http://localhost:8082/hello
- CRUD: http://localhost:8082/api/items
- Swagger UI: http://localhost:8082/docs
- ReDoc: http://localhost:8082/redoc
- Health: http://localhost:8082/health
- OpenAPI JSON: http://localhost:8082/openapi.json

### 4. Ejecutar tests

```bash
pytest
```

### 5. Ejecutar con Gunicorn (producción)

```bash
pip install gunicorn
gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker -b 0.0.0.0:8082
```

## Dependencias

| Paquete | Descripción |
|---------|-------------|
| `fastapi` | Framework web asíncrono de alto rendimiento |
| `uvicorn[standard]` | Servidor ASGI para desarrollo y producción |
| `pydantic` | Validación de datos y modelos |
| `httpx` | Cliente HTTP async para tests |
| `pytest` | Framework de testing |
| `pytest-asyncio` | Soporte async en pytest |

## Personalización

### Agregar base de datos (SQLAlchemy + PostgreSQL)
```bash
pip install sqlalchemy asyncpg databases
```

### Agregar autenticación OAuth2
```python
from fastapi.security import OAuth2PasswordBearer
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")
```

### Agregar Docker
```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app/ app/
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8082"]
```

## Integración con el Acelerador

Esta plantilla puede integrarse con otros componentes del acelerador WSO2:

- **API Manager**: Publicar la API en APIM usando la definición OpenAPI en `/openapi.json`
- **Identity Server**: Proteger endpoints con OAuth2/OIDC via IS
- **Karate**: Usar la plantilla `karate/api-testing` para validar los endpoints

## Referencias

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Pydantic Documentation](https://docs.pydantic.dev/)
- [Uvicorn](https://www.uvicorn.org/)
