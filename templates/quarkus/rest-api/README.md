# Plantilla: API REST con Quarkus

## Descripción

Proyecto base de API REST con [Quarkus](https://quarkus.io/), el framework Java supersónico y subatómico.
Incluye endpoints CRUD, health checks, OpenAPI/Swagger UI, inyección de dependencias CDI,
y configuración lista para ejecución en modo JVM y compilación nativa con GraalVM.

**Referencia**: [quarkusio/quarkus-quickstarts](https://github.com/quarkusio/quarkus-quickstarts)

## Estructura

```
rest-api/
├── README.md                          ← Este archivo
├── pom.xml                            ← Configuración Maven + extensiones Quarkus
├── src/
│   └── main/
│       ├── java/
│       │   └── com/ticxar/
│       │       ├── GreetingResource.java      ← Endpoint REST /hello
│       │       ├── ItemResource.java          ← CRUD completo /items
│       │       ├── Item.java                  ← Modelo de entidad
│       │       └── ItemService.java           ← Servicio de negocio
│       └── resources/
│           └── application.properties         ← Configuración Quarkus
└── src/
    └── test/
        └── java/
            └── com/ticxar/
                └── GreetingResourceTest.java  ← Test del endpoint
```

## Requisitos

| Herramienta | Versión |
|-------------|---------|
| Java JDK    | 17+     |
| Maven       | 3.9+    |
| GraalVM (opcional) | 23+ |

## Inicio Rápido

### 1. Copiar la plantilla

```bash
cp -r templates/quarkus/rest-api/ projects/quarkus/mi-servicio/
cd projects/quarkus/mi-servicio/
```

### 2. Modo desarrollo (hot reload)

```bash
mvn quarkus:dev
```

La aplicación estará disponible en:
- API: http://localhost:8080/hello
- CRUD: http://localhost:8080/items
- Swagger UI: http://localhost:8080/q/swagger-ui
- Health: http://localhost:8080/q/health
- Métricas: http://localhost:8080/q/metrics

### 3. Ejecutar tests

```bash
mvn test
```

### 4. Empaquetar

```bash
# JAR ejecutable
mvn package

# Ejecutable nativo (requiere GraalVM)
mvn package -Pnative
```

### 5. Ejecutar

```bash
# Modo JVM
java -jar target/quarkus-app/quarkus-run.jar

# Modo nativo
./target/quarkus-rest-api-1.0.0-runner
```

## Extensiones Incluidas

| Extensión | Descripción |
|-----------|-------------|
| `quarkus-rest` | JAX-RS reactivo (RESTEasy Reactive) |
| `quarkus-rest-jackson` | Serialización JSON con Jackson |
| `quarkus-smallrye-openapi` | Generación OpenAPI + Swagger UI |
| `quarkus-smallrye-health` | Health checks (liveness + readiness) |
| `quarkus-micrometer-registry-prometheus` | Métricas Prometheus |
| `quarkus-arc` | CDI (inyección de dependencias) |

## Personalización

### Cambiar grupo/artefacto Maven
Editar `pom.xml`:
```xml
<groupId>com.ticxar</groupId>
<artifactId>quarkus-rest-api</artifactId>
```

### Agregar persistencia (Panache + PostgreSQL)
```bash
mvn quarkus:add-extension -Dextensions="hibernate-orm-panache,jdbc-postgresql"
```

### Agregar seguridad JWT
```bash
mvn quarkus:add-extension -Dextensions="smallrye-jwt"
```

## Integración con el Acelerador

Esta plantilla puede integrarse con otros componentes del acelerador WSO2:

- **API Manager**: Publicar la API en APIM usando la definición OpenAPI generada automáticamente
- **Identity Server**: Proteger endpoints con OAuth2/OIDC via IS
- **Karate**: Usar la plantilla `karate/api-testing` para validar los endpoints

## Referencias

- [Quarkus Getting Started](https://quarkus.io/guides/getting-started)
- [Quarkus REST Guide](https://quarkus.io/guides/rest)
- [Quarkus Quickstarts](https://github.com/quarkusio/quarkus-quickstarts)
