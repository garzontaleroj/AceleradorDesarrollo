# WSO2 Identity Server — Configuraciones

Este directorio contiene las configuraciones de Identity Server.

## Estructura

```
identity-server/
├── conf/                       # Configuraciones base
├── identity-providers/         # Definiciones de IdPs (federados)
├── service-providers/          # Definiciones de SPs (aplicaciones)
├── claim-configs/              # Mapeo de claims personalizado
├── templates/                  # Templates de autenticación adaptiva
└── README.md
```

## Convenciones

- Configuraciones exportadas como XML desde la consola de IS
- Nombres descriptivos: `<proveedor>-idp.xml`, `<app>-sp.xml`
- Scripts de autenticación adaptiva en `templates/`
- No incluir secretos de client — se configuran via deployment.toml
