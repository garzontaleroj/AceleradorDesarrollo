# Plantilla: API REST con Spring Boot

## Descripción

Proyecto base de API REST con [Spring Boot](https://spring.io/projects/spring-boot), el framework más popular del
ecosistema Java. Incluye endpoints CRUD, Actuator (health/metrics/info), OpenAPI/Swagger UI,
inyección de dependencias, y configuración por perfiles (dev/qa/prod).

**Referencia**: [spring-projects/spring-boot](https://github.com/spring-projects/spring-boot)

## Estructura

```
rest-api/
├── README.md                          ← Este archivo
├── pom.xml                            ← Configuración Maven + starters Spring Boot
├── src/
│   └── main/
│       ├── java/
│       │   └── com/ticxar/springboot/
│       │       ├── Application.java           ← Clase principal @SpringBootApplication
│       │       ├── GreetingController.java    ← Endpoint REST /hello
│       │       ├── ItemController.java        ← CRUD completo /api/items
│       │       ├── Item.java                  ← Modelo de entidad
│       │       └── ItemService.java           ← Servicio de negocio
│       └── resources/
│           └── application.yaml               ← Configuración Spring Boot
└── src/
    └── test/
        └── java/
            └── com/ticxar/springboot/
                └── ApplicationTests.java      ← Tests de la aplicación
```

## Requisitos

| Herramienta | Versión |
|-------------|---------|
| Java JDK    | 17+     |
| Maven       | 3.9+    |

## Inicio Rápido

### 1. Copiar la plantilla

```bash
cp -r templates/spring-boot/rest-api/ projects/spring-boot/mi-servicio/
cd projects/spring-boot/mi-servicio/
```

### 2. Ejecutar en desarrollo

```bash
mvn spring-boot:run
```

La aplicación estará disponible en:
- API: http://localhost:8081/hello
- CRUD: http://localhost:8081/api/items
- Swagger UI: http://localhost:8081/swagger-ui.html
- Health: http://localhost:8081/actuator/health
- Info: http://localhost:8081/actuator/info
- Métricas: http://localhost:8081/actuator/metrics

### 3. Ejecutar tests

```bash
mvn test
```

### 4. Empaquetar

```bash
mvn package
```

### 5. Ejecutar

```bash
java -jar target/spring-boot-rest-api-1.0.0.jar
```

## Starters Incluidos

| Starter | Descripción |
|---------|-------------|
| `spring-boot-starter-web` | Web MVC + Tomcat embebido |
| `spring-boot-starter-actuator` | Health checks, métricas e info |
| `spring-boot-starter-validation` | Validación Bean Validation |
| `springdoc-openapi-starter-webmvc-ui` | OpenAPI 3 + Swagger UI |
| `spring-boot-starter-test` | JUnit 5, Mockito, MockMvc |

## Personalización

### Cambiar grupo/artefacto Maven
Editar `pom.xml`:
```xml
<groupId>com.ticxar</groupId>
<artifactId>spring-boot-rest-api</artifactId>
```

### Agregar persistencia (JPA + PostgreSQL)
Agregar al `pom.xml`:
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-jpa</artifactId>
</dependency>
<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
    <scope>runtime</scope>
</dependency>
```

### Agregar seguridad OAuth2
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-oauth2-resource-server</artifactId>
</dependency>
```

## Integración con el Acelerador

Esta plantilla puede integrarse con otros componentes del acelerador WSO2:

- **API Manager**: Publicar la API en APIM usando la definición OpenAPI generada automáticamente
- **Identity Server**: Proteger endpoints con OAuth2/OIDC via IS
- **Karate**: Usar la plantilla `karate/api-testing` para validar los endpoints

## Referencias

- [Spring Boot Reference Documentation](https://docs.spring.io/spring-boot/reference/)
- [Building a RESTful Web Service](https://spring.io/guides/gs/rest-service/)
- [Spring Boot GitHub](https://github.com/spring-projects/spring-boot)
