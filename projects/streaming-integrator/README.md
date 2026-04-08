# WSO2 Streaming Integrator — Siddhi Apps

Este directorio contiene las aplicaciones Siddhi para procesamiento de eventos.

## Estructura

```
streaming-integrator/
├── siddhi-apps/            # Aplicaciones Siddhi (.siddhi)
├── connectors/             # Conectores custom
└── README.md
```

## Convenciones

- Cada app Siddhi debe incluir `@App:name` y `@App:description`
- Nombres descriptivos: `SampleEventProcessor.siddhi`
- Documentar los streams de entrada y salida
- Parametrizar conexiones con variables de entorno
