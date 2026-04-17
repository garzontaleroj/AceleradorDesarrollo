# Plantilla: Federación con Azure AD — Identity Server

## Descripción
Configuración de Identity Provider para federar WSO2 Identity Server con
Microsoft Entra ID (Azure AD) usando OpenID Connect.

## Caso de uso
Permitir a usuarios de Azure AD autenticarse en aplicaciones protegidas por
WSO2 IS, habilitando Single Sign-On corporativo con Microsoft 365.

## Artefactos
| Archivo | Tipo | Descripción |
|---------|------|-------------|
| `azure-ad-idp.xml` | IdP Config | Configuración del Identity Provider federado |

## Variables
| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `AZURE_TENANT_ID` | Tenant ID de Azure AD | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `AZURE_CLIENT_ID` | Application (client) ID registrado en Azure | `yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy` |
| `AZURE_CLIENT_SECRET` | Client Secret del App Registration | `secret-value` |
| `IS_HOST` | Hostname del Identity Server | `is.ejemplo.com` |

## Prerequisitos en Azure
1. Azure Portal → **App registrations** → **New registration**
2. Redirect URI: `https://{{IS_HOST}}/commonauth`
3. Anotar **Application (client) ID** y **Directory (tenant) ID**
4. **Certificates & secrets** → Crear nuevo client secret

## Configuración en IS
1. **Identity Providers** → **Add** → Nombre: `AzureAD`
2. **Federated Authenticators** → **OAuth2/OpenID Connect**
3. Configurar según `azure-ad-idp.xml`
4. **Claim Configuration** → Mapear claims de Azure a claims locales
