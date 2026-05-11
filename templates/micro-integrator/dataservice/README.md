# Plantilla: Data Service Templates — WSO2 Micro Integrator

## Descripción
Colección de plantillas reutilizables para la creación rápida de Data Services en WSO2 Micro Integrator.

Estas plantillas permiten acelerar el desarrollo de integraciones con bases de datos mediante estructuras estándar para operaciones CRUD utilizando:
- Queries SQL reutilizables
- Operations SOAP
- Resources REST
- Response mappings
- Parametrización reutilizable

El objetivo es reducir tiempos de implementación, evitar configuraciones repetitivas y estandarizar el desarrollo de Data Services dentro del equipo.

---

# Estructura del repositorio

```plaintext
dataservice-templates/
│
├── DataServiceBase.dbs
├── DS_Select_Template.dbs
├── DS_Insert_Template.dbs
├── DS_Update_Template.dbs
├── DS_Delete_Template.dbs
└── README.md
```

---

# Plantillas disponibles

| Archivo | Descripción |
|----------|-------------|
| `DataServiceBase.dbs` | Plantilla base completa para Data Services |
| `DS_Select_Template.dbs` | Plantilla para consultas SELECT |
| `DS_Insert_Template.dbs` | Plantilla para operaciones INSERT |
| `DS_Update_Template.dbs` | Plantilla para operaciones UPDATE |
| `DS_Delete_Template.dbs` | Plantilla para operaciones DELETE |

---

# Caso de uso

Utilizar estas plantillas cuando se requiera:

- Exponer información desde bases de datos
- Crear operaciones CRUD rápidamente
- Centralizar consultas SQL
- Reducir configuraciones repetitivas
- Estandarizar Data Services corporativos
- Acelerar onboarding de desarrolladores

---

# Flujo general

```plaintext
Cliente
   ↓
Operation / Resource
   ↓
Query SQL
   ↓
Datasource
   ↓
Base de Datos
   ↓
Respuesta
```

---

# Variables parametrizadas

| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `{{NAME}}` | Nombre Data Service | `DataServiceClientes` |
| `{{ID}}` | Identificador datasource | `clientDS` |
| `{{DATABASE_DRIVERCLASSNAME}}` | Driver JDBC | `org.postgresql.Driver` |
| `{{DATABASE_URL}}` | URL conexión BD | `jdbc:postgresql://localhost:5432/clientesdb` |
| `{{DATABASE_USER}}` | Usuario BD | `postgres` |
| `{{DATABASE_PASSWORD}}` | Contraseña BD | `postgres` |
| `{{QUERY_NAME}}` | Nombre query | `q_get_clientes` |
| `{{OPERATION_NAME}}` | Nombre operación SOAP | `GetClientes` |
| `{{DATASOURCE_ID}}` | ID datasource reutilizable | `clientDS` |

---

# Funcionalidades incluidas

- Queries SQL reutilizables
- Operations SOAP
- Resources REST opcionales
- Parametrización estándar
- Response mappings
- Separación por operación CRUD
- Estructura comentada
- Templates reutilizables

---

# Tipos de plantillas

## 1. SELECT Template

Permite:
- Consultas SQL
- Mapeo de resultados
- Exposición SOAP/REST

Operaciones típicas:
```sql
SELECT * FROM tabla
```

---

## 2. INSERT Template

Permite:
- Inserción de registros
- Parametrización de datos
- Exposición SOAP/REST

Operaciones típicas:
```sql
INSERT INTO tabla (...)
VALUES (...)
```

---

## 3. UPDATE Template

Permite:
- Actualización de registros
- Manejo de parámetros
- Exposición SOAP/REST

Operaciones típicas:
```sql
UPDATE tabla
SET campo = valor
WHERE id = :id
```

---

## 4. DELETE Template

Permite:
- Eliminación de registros
- Parametrización por identificador
- Exposición SOAP/REST

Operaciones típicas:
```sql
DELETE FROM tabla
WHERE id = :id
```

---

## 5. CRUD Template

Incluye:
- SELECT
- INSERT
- UPDATE
- DELETE

Ideal para:
- Nuevos proyectos
- Servicios completos
- Quick Start implementations

---

# Exposición del servicio

Las plantillas soportan:

## SOAP
Mediante:
```xml
<operation>
```

## REST
Mediante:
```xml
<resource>
```

> Se recomienda utilizar únicamente uno dependiendo del tipo de integración requerida.

---

# Tipos SQL comunes

| Tipo | Descripción |
|------|-------------|
| `STRING` | Texto |
| `INTEGER` | Número entero |
| `DOUBLE` | Decimal |
| `BOOLEAN` | Verdadero/Falso |
| `DATE` | Fecha |
| `TIMESTAMP` | Fecha y hora |

---

# Beneficios

- Reduce tiempos de desarrollo
- Facilita reutilización
- Mejora mantenibilidad
- Reduce errores de configuración
- Estandariza integraciones
- Facilita onboarding técnico
- Simplifica construcción de Data Services

---

# Próximas mejoras

- Manejo de errores SQL
- Secure Vault integration
- Templates con paginación
- Auditoría de consultas
- Pool de conexiones configurable
- CRUD generators automáticos
- Templates para procedimientos almacenados
- Manejo de transacciones