# Plantilla: Política de Rate Limiting — API Manager

## Descripción
Política de throttling personalizada para limitar el número de peticiones
por aplicación, por usuario, o globalmente.

## Caso de uso
Proteger APIs backend contra sobrecarga limitando las llamadas por unidad de tiempo.

## Artefactos
| Archivo | Tipo | Descripción |
|---------|------|-------------|
| `rate-limit-policy.xml` | Mediation Policy | Política de mediación para rate limiting |

## Variables
| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `POLICY_NAME` | Nombre de la política | `CustomRateLimit` |
| `MAX_REQUESTS` | Máximo de requests permitidos | `100` |
| `TIME_WINDOW` | Ventana de tiempo en segundos | `60` |

## Aplicación
### Vía Publisher Portal
1. **APIs** → seleccionar API → **Policies**
2. **Add Policy** → subir `rate-limit-policy.xml`
3. Arrastrar al flujo **Request** en los recursos deseados

### Vía deployment.toml (global)
```toml
[apim.throttling]
enable_data_publishing = true
enable_policy_deploy = true

[[apim.throttling.custom_throttle_properties]]
name = "{{POLICY_NAME}}"
value = "{{MAX_REQUESTS}}"
```
