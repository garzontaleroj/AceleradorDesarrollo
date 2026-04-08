# WSO2 API Manager — Artefactos

Este directorio contiene los artefactos del API Manager.

## Estructura

```
api-manager/
├── apis/                    # Definiciones OpenAPI / Swagger
│   └── sample-api.yaml      # Ejemplo de API
├── policies/                # Políticas de mediación / throttling
│   └── custom-policy.xml
├── certificates/            # Certificados públicos (NO privados)
├── .spectral.yaml           # Reglas de linting para OpenAPI
└── README.md
```

## Convenciones

- Las APIs se definen en formato **OpenAPI 3.0+** (YAML preferido)
- Nombrar archivos: `<nombre-api>.yaml` (kebab-case)
- Políticas en XML siguiendo la estructura de WSO2 APIM
- Los certificados privados van en secrets de K8s, NUNCA aquí
