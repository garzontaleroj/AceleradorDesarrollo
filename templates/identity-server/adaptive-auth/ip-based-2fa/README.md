# Plantilla: 2FA basado en IP — Identity Server

## Descripción
Script de autenticación adaptativa que solicita un segundo factor (TOTP)
cuando el login proviene de una IP fuera del rango corporativo conocido.

## Caso de uso
Usuarios internos (red corporativa) se autentican solo con usuario/contraseña.
Usuarios externos (VPN, remoto) necesitan adicionalmente un código TOTP.

## Artefactos
| Archivo | Tipo | Descripción |
|---------|------|-------------|
| `adaptive-auth-ip-2fa.js` | Script | Script de autenticación adaptativa |

## Variables
| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `CORPORATE_IPS` | Rangos IP corporativos | `["10.0.0.0/8", "192.168.1.0/24"]` |

## Configuración en IS
1. Crear Service Provider con autenticación en 2 pasos
2. Step 1: BasicAuthenticator
3. Step 2: TOTP Authenticator
4. En **Adaptive Authentication Script** pegar el contenido de `adaptive-auth-ip-2fa.js`
5. Ajustar `corporateIPs` con los rangos de la organización
