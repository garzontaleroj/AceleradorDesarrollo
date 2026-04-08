# WSO2 Micro Integrator — Artefactos

Este directorio contiene los artefactos de mediación del Micro Integrator.

## Estructura

```
micro-integrator/
├── src/main/
│   ├── synapse-config/
│   │   ├── api/                  # REST APIs (proxy inverso, mediación)
│   │   ├── endpoints/            # Definición de endpoints backend
│   │   ├── proxy-services/       # Proxy services SOAP/REST
│   │   ├── sequences/            # Secuencias reutilizables
│   │   ├── message-stores/       # Message stores (JMS, JDBC, etc.)
│   │   ├── message-processors/   # Message processors
│   │   ├── tasks/                # Scheduled tasks
│   │   ├── templates/            # Sequence/endpoint templates
│   │   └── local-entries/        # Entradas locales (schemas, WSDL, etc.)
│   └── registry-resources/       # Recursos de registro
├── pom.xml                       # Maven build (si aplica)
└── README.md
```

## Convenciones

- Archivos XML con indentación de **4 espacios**
- Nombres en **PascalCase** para servicios: `SampleAPI.xml`
- Endpoints separados del API/proxy para reutilización
- Secuencias comunes en `sequences/` (error handling, logging, etc.)
- No hardcodear URLs — usar propiedades del `deployment.toml`
