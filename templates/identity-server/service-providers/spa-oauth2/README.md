# Plantilla: SPA con OAuth2/OIDC — Identity Server

## Descripción
Configuración de Service Provider para Single Page Application (React, Angular, Vue)
con OAuth2 Authorization Code + PKCE. Este es el flujo recomendado para SPAs modernas.

## Caso de uso
Aplicación frontend que necesita autenticar usuarios y obtener tokens de acceso
para consumir APIs protegidas por el API Manager.

## Artefactos
| Archivo | Tipo | Descripción |
|---------|------|-------------|
| `sp-config.xml` | Service Provider | Configuración del SP |

## Variables
| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `SP_NAME` | Nombre del Service Provider | `MiAppWeb` |
| `CALLBACK_URL` | URL de callback OAuth2 | `http://localhost:3000/callback` |
| `CLIENT_ID` | OAuth2 Client ID (generar en IS) | `abc123` |

## Flujo OAuth2 + PKCE
```
1. SPA genera code_verifier + code_challenge
2. SPA → IS: /authorize?response_type=code&code_challenge=...
3. Usuario se autentica en IS
4. IS → SPA: redirect con authorization_code
5. SPA → IS: /token con code + code_verifier
6. IS → SPA: access_token + id_token
7. SPA → API Manager: requests con Bearer token
```

## Configuración en IS Console
1. **Main** → **Service Providers** → **Add**
2. Nombre: `{{SP_NAME}}`
3. **Inbound Authentication** → **OAuth/OpenID Connect** → **Configure**
4. Callback URL: `{{CALLBACK_URL}}`
5. Habilitar **PKCE Mandatory**
6. Grant Types: `authorization_code`, `refresh_token`
