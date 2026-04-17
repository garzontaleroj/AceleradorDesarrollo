# Plantilla: Servicio HTTP REST — Ballerina

## Descripción
Servicio HTTP en Ballerina con endpoints CRUD, manejo de errores tipado,
y tests unitarios incluidos.

## Caso de uso
Crear microservicios ligeros que se integran con el ecosistema WSO2
o funcionan de forma independiente.

## Artefactos
| Archivo | Tipo | Descripción |
|---------|------|-------------|
| `Ballerina.toml` | Config | Configuración del proyecto |
| `service.bal` | Source | Servicio HTTP principal |
| `types.bal` | Source | Tipos y records del dominio |
| `tests/service_test.bal` | Test | Tests unitarios |

## Variables
| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `ORG_NAME` | Organización Ballerina | `ticxar` |
| `PACKAGE_NAME` | Nombre del paquete | `product_service` |
| `SERVICE_PORT` | Puerto del servicio | `9090` |
| `BASE_PATH` | Ruta base del servicio | `/api/v1` |
| `RESOURCE_NAME` | Nombre del recurso | `products` |

## Uso rápido
```bash
# Copiar plantilla y renombrar
cp -r templates/ballerina/http-service/ projects/ballerina/mi-servicio/

# Reemplazar variables
# (usar script o manualmente)

# Compilar y ejecutar
cd projects/ballerina/mi-servicio/
bal build
bal run
```
