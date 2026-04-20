# Escenario 2: Active Directory (Samba AD DC) + WSO2 Identity Server 7.2.0

Escenario avanzado que simula un **Active Directory real** usando **Samba 4 AD DC** como Domain Controller. Replica la infraestructura de producción de **AXA Colpatria TSTF** (`TSTF.AXACOLPATRIA.CO`) para pruebas de integración **SCIM2**.

---

## Arquitectura

```
┌──────────────┐       ┌──────────────────────┐
│   Cliente    │       │     WSO2 IS 7.2.0    │
│  SCIM2/API   │──────►│   :9443 (HTTPS)      │
└──────────────┘       │                       │
                       │  Userstore: TSTF      │
                       │  (AD UserStoreManager) │
                       └──────────┬────────────┘
                                  │ LDAP :389
                       ┌──────────┴────────────┐
                       │   Samba AD DC          │
                       │   dc1.tstf.axacolpatria│
                       │   :389/:636/:88/:3268  │
                       │                        │
                       │  Domain: TSTF          │
                       │  Realm:  TSTF.AXA...   │
                       └────────────────────────┘
```

## Componentes

| Servicio | Imagen | Puertos | Descripción |
|----------|--------|---------|-------------|
| Samba AD DC | Custom (Ubuntu 22.04 + Samba 4) | 389, 636, 88, 3268 | Domain Controller con LDAP, Kerberos, GC |
| WSO2 IS | `wso2/wso2is:7.2.0` | 9443, 9763 | Identity Server con userstore AD |

## Datos del dominio

| Propiedad | Valor |
|-----------|-------|
| **Dominio** | `TSTF.AXACOLPATRIA.CO` |
| **NetBIOS** | `TSTF` |
| **Base DN** | `DC=tstf,DC=axacolpatria,DC=co` |
| **Hostname DC** | `dc1.tstf.axacolpatria.co` |

### Estructura de OUs

```
DC=tstf,DC=axacolpatria,DC=co
├── OU=Service_accounts
│   └── CN=Axaservicewso2Tip    (cuenta de servicio WSO2)
├── OU=Usuarios
│   ├── CN=jperez               (Juan Perez)
│   ├── CN=mgarcia              (Maria Garcia)
│   ├── CN=clopez               (Carlos Lopez)
│   └── CN=arivera              (Ana Rivera)
└── OU=Grupos
    ├── CN=developers           (jperez, clopez)
    ├── CN=admins               (jperez)
    ├── CN=operaciones          (mgarcia, arivera)
    └── CN=soporte              (arivera, clopez)
```

### Usuarios

| sAMAccountName | Nombre | Email | Password | Grupos |
|----------------|--------|-------|----------|--------|
| `jperez` | Juan Perez | jperez@tstf.axacolpatria.co | `P@ssw0rd123!` | developers, admins |
| `mgarcia` | Maria Garcia | mgarcia@tstf.axacolpatria.co | `P@ssw0rd123!` | operaciones |
| `clopez` | Carlos Lopez | clopez@tstf.axacolpatria.co | `P@ssw0rd123!` | developers, soporte |
| `arivera` | Ana Rivera | arivera@tstf.axacolpatria.co | `P@ssw0rd123!` | operaciones, soporte |

### Cuenta de servicio

| Propiedad | Valor |
|-----------|-------|
| DN | `CN=Axaservicewso2Tip,OU=Service_accounts,DC=tstf,DC=axacolpatria,DC=co` |
| sAMAccountName | `Axaservicewso2Tip` |
| Password | `S3rv1c3@WSO2tip` |
| Expira | No |

---

## Configuración del Userstore

Archivo: `userstores-ad/TSTF.xml`

| Propiedad | Valor |
|-----------|-------|
| Manager class | `UniqueIDActiveDirectoryUserStoreManager` |
| ConnectionURL | `ldap://samba-ad:389` |
| ConnectionName | `CN=WSO2 ServiceAccount,OU=Service_accounts,...` |
| UserSearchBase | `DC=tstf,DC=axacolpatria,DC=co` |
| UserNameAttribute | `sAMAccountName` |
| UserIDAttribute | `objectGuid` |
| GroupSearchBase | `OU=Grupos,DC=tstf,DC=axacolpatria,DC=co` |
| GroupEntryObjectClass | `group` |
| GroupNameAttribute | `cn` |
| GroupIdAttribute | `cn` |
| MembershipAttribute | `member` |
| MemberOfAttribute | `memberOf` |
| BackLinksEnabled | `true` |
| Referral | `ignore` |
| ReadOnly | `true` |
| WriteGroups | `false` |
| transformObjectGUIDToUUID | `true` |
| Binary attributes | `objectGuid`, `objectSid` |
| DomainName | `TSTF` |

## Claim mappings

El script `init-claims-ad.sh` configura 8 mapeos de claims entre WSO2 IS y atributos AD:

| Claim WSO2 | Atributo AD | Descripción |
|-------------|-------------|-------------|
| `http://wso2.org/claims/userid` | `objectGuid` | Identificador único del usuario |
| `http://wso2.org/claims/username` | `sAMAccountName` | Nombre de usuario |
| `http://wso2.org/claims/givenname` | `givenName` | Nombre |
| `http://wso2.org/claims/lastname` | `sn` | Apellido |
| `http://wso2.org/claims/emailaddress` | `mail` | Correo electrónico |
| `http://wso2.org/claims/groups` | `memberOf` | Grupos del usuario |
| `http://wso2.org/claims/created` | `whenCreated` | Fecha de creación |
| `http://wso2.org/claims/modified` | `whenChanged` | Fecha de modificación |

---

## Procedimiento: Construir e iniciar

### Paso 1 — Construir e iniciar los contenedores

```bash
docker compose -f docker-compose-ad.yml up -d --build
```

La primera ejecución:
1. Construye la imagen `samba-ad` desde `samba-ad/Dockerfile`
2. Inicia Samba AD DC y provisiona el dominio (`samba-tool domain provision`)
3. Crea OUs, usuarios y grupos automáticamente (`init-users.sh`)
4. Inicia WSO2 IS (espera a que Samba esté healthy vía healthcheck)

### Paso 2 — Verificar que Samba AD está listo

```bash
# Ver estado de salud
docker inspect --format='{{.State.Health.Status}}' samba-ad

# Debería mostrar: healthy

# Verificar LDAP
docker exec samba-ad ldapsearch -x -H ldap://127.0.0.1:389 -D "CN=Administrator,CN=Users,DC=tstf,DC=axacolpatria,DC=co" -w "P@ssw0rd2024" -b "OU=Grupos,DC=tstf,DC=axacolpatria,DC=co" cn
```

# Crear Nuevo grupo LDAP
docker exec samba-ad samba-tool group add nuevo-grupo --groupou="OU=Grupos"
```

# Asociar usuario clopez a nuevo-grupo LDAP
docker exec samba-ad samba-tool group addmember nuevo-grupo clopez
```

### Paso 3 — Esperar a que WSO2 IS esté listo

```bash
docker logs -f wso2is
# Esperar: "WSO2 Carbon started in XX sec"
```

### Paso 4 — Aplicar claim mappings

**Linux / macOS / Git Bash:**
```bash
bash init-claims-ad.sh
```

**Windows CMD:**
```cmd
init-claims-ad.bat
```

### Paso 5 — Seed SCIM metadata para grupos AD (OBLIGATORIO)

> **Sin este paso, `GET /scim2/Groups` retorna `Resources: []`.**  
> Ver sección [Problema SCIM2 Groups vacío](#problema-scim2-groups-vacío) para detalles.

**Linux / macOS / Git Bash:**
```bash
bash seed-scim-groups-ad.sh
```

**Windows CMD:**
```cmd
seed-scim-groups-ad.bat
```

El script:
1. Espera a que WSO2 IS esté completamente iniciado
2. **Descubre automáticamente** todos los grupos en `OU=Grupos` de Samba AD vía `ldapsearch`
3. Verifica que WSO2 IS detecta los grupos del dominio TSTF
4. **Detiene WSO2 IS** para liberar el lock exclusivo de H2 2.x
5. Ejecuta un contenedor temporal montando el volumen `wso2is_db` para acceder a la base H2
6. Ejecuta DELETE+INSERT idempotente — elimina toda metadata TSTF previa, luego inserta 4 filas por grupo
7. Genera UUIDs únicos para cada grupo (id, meta.created, meta.lastModified, meta.location)
8. **Reinicia WSO2 IS** y espera a que esté listo
9. Verifica que todos los grupos descubiertos aparecen en SCIM2 con sus miembros

> **Nota:** El script es **idempotente** y **dinámico** — puede ejecutarse múltiples veces y descubre automáticamente grupos nuevos o eliminados en Samba AD. No necesita editarse al agregar o quitar grupos.

### Paso 6 — Verificar

```bash
# Usuarios SCIM2
curl -sk -u admin:admin https://localhost:9443/scim2/Users?count=10 | python -m json.tool

# Grupos SCIM2 del dominio TSTF (debe mostrar 4 grupos con miembros)
curl -sk -u admin:admin "https://localhost:9443/scim2/Groups?domain=TSTF" | python -m json.tool

# Grupos PRIMARY (solo debe tener 'admin')
curl -sk -u admin:admin "https://localhost:9443/scim2/Groups?domain=PRIMARY" | python -m json.tool

# Detalle de un grupo con miembros
curl -sk -u admin:admin "https://localhost:9443/scim2/Groups?filter=displayName+eq+TSTF/developers" | python -m json.tool
```

**Resultado esperado de `/scim2/Groups?domain=TSTF`:**
```json
{
    "totalResults": 4,
    "itemsPerPage": 4,
    "Resources": [
        { "displayName": "TSTF/developers", "members": [{"display": "TSTF/jperez"}, {"display": "TSTF/clopez"}] },
        { "displayName": "TSTF/admins", "members": [{"display": "TSTF/jperez"}] },
        { "displayName": "TSTF/operaciones", "members": [{"display": "TSTF/mgarcia"}, {"display": "TSTF/arivera"}] },
        { "displayName": "TSTF/soporte", "members": [{"display": "TSTF/arivera"}, {"display": "TSTF/clopez"}] }
    ]
}
```

> **Importante:** Los grupos TSTF NO deben aparecer en el dominio PRIMARY. PRIMARY solo contiene el grupo `admin` por defecto.
```

**Acceso a WSO2 IS Console:**
1. Abrir https://localhost:9443/console
2. Usuario: `admin`
3. Password: `admin`

---

## Gestión de grupos y asignación de usuarios

> **WSO2 IS NO gestiona grupos ni membresías.** El userstore TSTF está configurado como **ReadOnly** (`ReadOnly=true`, `WriteGroups=false`). Toda la gestión de grupos y asignación de usuarios a grupos se realiza directamente en el **directorio Samba AD**, no desde la consola de WSO2 IS.

### Herramientas disponibles

| Herramienta | Tipo | Descripción |
|-------------|------|-------------|
| `samba-tool` | CLI (dentro del contenedor) | Herramienta nativa de Samba AD — la más directa |
| Apache Directory Studio | Cliente desktop | Conecta vía LDAP al DC (localhost:389) |
| RSAT | Windows GUI | Remote Server Administration Tools — para entornos Windows con AD nativo |

### Ejemplos con `samba-tool`

```bash
# Crear un nuevo grupo
docker exec samba-ad samba-tool group add nuevo-grupo \
  --groupou="OU=Grupos"

# Agregar usuario a un grupo
docker exec samba-ad samba-tool group addmembers developers clopez

# Eliminar usuario de un grupo
docker exec samba-ad samba-tool group removemembers developers clopez

# Listar miembros de un grupo
docker exec samba-ad samba-tool group listmembers developers

# Listar todos los grupos
docker exec samba-ad samba-tool group list
```

### Conexión con Apache Directory Studio

| Parámetro | Valor |
|-----------|-------|
| Hostname | `localhost` |
| Puerto | `389` |
| Bind DN | `CN=Administrator,CN=Users,DC=tstf,DC=axacolpatria,DC=co` |
| Password | `P@ssw0rd2024` |
| Base DN | `DC=tstf,DC=axacolpatria,DC=co` |

### Después de modificar grupos

Si se crean nuevos grupos o se eliminan grupos existentes en Samba AD, simplemente re-ejecutar el script de seed SCIM. El script **descubre automáticamente** todos los grupos actuales en `OU=Grupos`:

```bash
# Linux / macOS / Git Bash
bash seed-scim-groups-ad.sh

# Windows CMD
seed-scim-groups-ad.bat
```

> **No es necesario editar el script** al agregar o quitar grupos — la detección es dinámica.

> **Nota:** Los cambios de **membresía** (agregar/quitar usuarios de grupos existentes) se reflejan automáticamente en WSO2 IS sin re-ejecutar el seed, ya que WSO2 IS consulta las membresías en tiempo real desde Samba AD.

---

## Detener

```bash
# Detener manteniendo datos (Samba no re-provisiona)
docker compose -f docker-compose-ad.yml down

# Detener y eliminar todo (reinicio limpio completo)
docker compose -f docker-compose-ad.yml down -v
```

> **Nota:** Con `-v` se elimina el volumen `samba_data` y las bases H2. En el próximo `up`, Samba re-provisionará el dominio y será necesario ejecutar nuevamente los scripts de claims y seed SCIM.

---

## Procedimiento completo de reconstrucción

Cuando se necesita un entorno limpio desde cero:

```bash
# 1. Destruir todo
docker compose -f docker-compose-ad.yml down -v

# 2. Reconstruir e iniciar
docker compose -f docker-compose-ad.yml up -d --build

# 3. Esperar ~60 segundos (provisioning Samba + inicio WSO2 IS)

# 4. Aplicar claims
bash init-claims-ad.sh

# 5. Seed SCIM groups
bash seed-scim-groups-ad.sh

# 6. Verificar
curl -sk -u admin:admin https://localhost:9443/scim2/Groups | python -m json.tool
```

**En Windows CMD:**
```cmd
docker compose -f docker-compose-ad.yml down -v
docker compose -f docker-compose-ad.yml up -d --build
REM Esperar ~60 segundos
init-claims-ad.bat
seed-scim-groups-ad.bat
curl -sk -u admin:admin https://localhost:9443/scim2/Groups | python -m json.tool
```

---

## Problema SCIM2 Groups vacío

### Síntoma

`GET /scim2/Groups` retorna:
```json
{
    "totalResults": 4,
    "Resources": []
}
```

### Causa raíz

WSO2 IS 7.x con separación rol/grupo habilitada (`isRoleAndGroupSeparationEnabled() = true`) usa el método `getGroupNamesForGroupsEndpoint()` en `SCIMUserManager.java`. Este método:

1. Obtiene los nombres de grupos del userstore externo (AD) — **funciona correctamente**
2. Consulta metadatos SCIM en `IDN_SCIM_GROUP` para cada grupo — **FALLA porque no existen**
3. Sin metadatos SCIM → `SCIMGroupResolver.getGroupID()` retorna `null`
4. `buildGroup()` establece ID = `null`
5. `setGroupRoles()` lanza error: "Group id cannot be empty"
6. `listGroups()` verifica `if (group.getId() != null)` → **FALLA** → grupo descartado silenciosamente
7. Resultado: `Resources` vacío

### Por qué no se auto-provisionan

El método `createSCIMAttributesForSCIMDisabledHybridRoles()` solo auto-provisiona metadatos para roles **internos** híbridos (Internal/admin, Internal/everyone, etc.). Los grupos de userstores externos LDAP/AD **nunca** reciben auto-provisionamiento.

### Solución

**Solución:** El script `seed-scim-groups-ad.sh` / `.bat` **descubre automáticamente** los grupos del directorio AD vía `ldapsearch` e inserta directamente en la tabla `IDN_SCIM_GROUP` de la base H2 usando un enfoque **DELETE+INSERT idempotente**:

1. **Detiene WSO2 IS** — H2 2.x no soporta acceso concurrente (AUTO_SERVER fue eliminado en H2 2.x)
2. **Monta el volumen Docker `wso2is_db`** en un contenedor temporal para acceder a la base H2
3. **DELETE** previo de toda metadata existente para el dominio TSTF (`ROLE_NAME LIKE 'TSTF/%'`)
4. **INSERT** dinámico — 4 filas por grupo descubierto:

```sql
-- Limpiar toda metadata previa del dominio TSTF
DELETE FROM IDN_SCIM_GROUP WHERE ROLE_NAME LIKE 'TSTF/%' AND TENANT_ID=-1234;

-- 4 filas por grupo descubierto: id, meta.created, meta.lastModified, meta.location
INSERT INTO IDN_SCIM_GROUP (ID, TENANT_ID, ROLE_NAME, ATTR_NAME, ATTR_VALUE, AUDIENCE_REF_ID) 
VALUES (1001, -1234, 'TSTF/developers', 'urn:ietf:params:scim:schemas:core:2.0:id', '<uuid>', -1);
-- ... (1002: meta.created, 1003: meta.lastModified, 1004: meta.location)
-- ... (IDs auto-incrementan para cada grupo descubierto)
```

5. **Reinicia WSO2 IS** y verifica que los grupos aparecen con miembros

**Tabla IDN_SCIM_GROUP:**

| Columna | Tipo | Descripción |
|---------|------|-------------|
| ID | INT (PK) | Auto-incremento |
| TENANT_ID | INT | `-1234` para tenant por defecto |
| ROLE_NAME | VARCHAR(255) | `DOMAIN/groupName` (ej: `TSTF/developers`) |
| ATTR_NAME | VARCHAR(1024) | URN del atributo SCIM |
| ATTR_VALUE | VARCHAR(1024) | Valor del atributo |
| AUDIENCE_REF_ID | INT | `-1` para grupos externos |

---

## Archivos del escenario

| Archivo | Descripción |
|---------|-------------|
| `docker-compose-ad.yml` | Orquestación Samba AD DC + WSO2 IS |
| `deployment.toml` | Configuración base WSO2 IS |
| `samba-ad/Dockerfile` | Imagen Docker del Domain Controller |
| `samba-ad/entrypoint.sh` | Provisioning y startup de Samba |
| `samba-ad/init-users.sh` | Creación de OUs, usuarios y grupos |
| `userstores-ad/TSTF.xml` | Userstore ActiveDirectory |
| `userstores-ad/AGENT.xml` | Userstore Agent |
| `init-claims-ad.sh` | Claim mappings AD (bash) |
| `init-claims-ad.bat` | Claim mappings AD (Windows CMD) |
| `seed-scim-groups-ad.sh` | Seed SCIM metadata (bash) |
| `seed-scim-groups-ad.bat` | Seed SCIM metadata (Windows CMD) |

---

## Troubleshooting

### Samba no se inicia / healthcheck falla

```bash
docker logs samba-ad
# Verificar que no hay conflictos de puerto 389
netstat -an | findstr 389
```

### WSO2 IS no conecta a Samba

```bash
# Verificar que Samba está healthy
docker inspect --format='{{.State.Health.Status}}' samba-ad

# Probar LDAP bind desde WSO2 IS
docker exec wso2is apt-get update && docker exec wso2is apt-get install -y ldap-utils
docker exec wso2is ldapsearch -x -H ldap://samba-ad:389 \
  -D "CN=Axaservicewso2Tip,OU=Service_accounts,DC=tstf,DC=axacolpatria,DC=co" \
  -w "S3rv1c3@WSO2tip" -b "OU=Grupos,DC=tstf,DC=axacolpatria,DC=co" cn
```

### Grupos no aparecen después del seed

El script usa un volumen Docker compartido. Para verificar manualmente la inserción (WSO2 IS debe estar detenido):

```bash
# Detener WSO2 IS primero
docker stop wso2is

# Consultar via contenedor temporal
docker run --rm \
  -v identity7groups_wso2is_db:/home/wso2carbon/wso2is-7.2.0/repository/database \
  --entrypoint="" wso2/wso2is:7.2.0 \
  java -cp "/home/wso2carbon/wso2is-7.2.0/repository/components/plugins/h2-engine_2.2.224.wso2v2.jar" \
  org.h2.tools.Shell \
  -url "jdbc:h2:/home/wso2carbon/wso2is-7.2.0/repository/database/WSO2IDENTITY_DB;IFEXISTS=TRUE" \
  -user wso2carbon -password wso2carbon \
  -sql "SELECT * FROM IDN_SCIM_GROUP WHERE ROLE_NAME LIKE 'TSTF/%'"

# Reiniciar WSO2 IS
docker start wso2is
```

> **Nota:** NO usar `docker exec wso2is` para acceder a H2 mientras WSO2 IS está corriendo.  
> H2 2.2.224 no soporta `AUTO_SERVER=TRUE` — el acceso concurrente causa errores.
