# Escenario 1: OpenLDAP + WSO2 Identity Server 7.2.0

Escenario simple con **OpenLDAP** como directorio externo, **phpLDAPAdmin** como herramienta de administración visual, y **WSO2 IS 7.2.0** exponiendo usuarios y grupos vía **SCIM2**.

---

## Arquitectura

```
┌──────────────┐       ┌──────────────┐       ┌──────────────┐
│ phpLDAPAdmin │       │  WSO2 IS     │       │   Cliente    │
│  :8080       │       │  :9443       │◄──────│  SCIM2/API   │
└──────┬───────┘       └──────┬───────┘       └──────────────┘
       │                      │
       │     LDAP :389        │
       └──────┬───────────────┘
              │
       ┌──────┴───────┐
       │   OpenLDAP   │
       │   :389/:636  │
       └──────────────┘
```

## Componentes

| Servicio | Imagen | Puertos |
|----------|--------|---------|
| WSO2 Identity Server | `wso2/wso2is:7.2.0` | 9443 (HTTPS), 9763 (HTTP) |
| OpenLDAP | `osixia/openldap:latest` | 389 (LDAP), 636 (LDAPS) |
| phpLDAPAdmin | `osixia/phpldapadmin:latest` | 8080 (HTTP) |

## Datos del directorio

**Dominio:** `tsf.axacolpatria.co`  
**Base DN:** `dc=tsf,dc=axacolpatria,dc=co`

### Usuarios (ou=users)

| uid | Nombre | Email | Password |
|-----|--------|-------|----------|
| `jperez` | Juan Perez | jperez@axacolpatria.co | `password123` |
| `mgarcia` | Maria Garcia | mgarcia@axacolpatria.co | `password123` |

### Grupos (ou=groups)

| Grupo | Miembros |
|-------|----------|
| `developers` | jperez, mgarcia |
| `admins` | jperez |

## Configuración del Userstore

Archivo: `userstores/LDAPSecondary.xml`

| Propiedad | Valor |
|-----------|-------|
| Manager class | `UniqueIDReadWriteLDAPUserStoreManager` |
| ConnectionURL | `ldap://openldap:389` |
| ConnectionName | `cn=admin,dc=tsf,dc=axacolpatria,dc=co` |
| UserSearchBase | `ou=users,dc=tsf,dc=axacolpatria,dc=co` |
| UserNameAttribute | `uid` |
| UserIDAttribute | `employeeNumber` |
| GroupSearchBase | `ou=groups,dc=tsf,dc=axacolpatria,dc=co` |
| GroupEntryObjectClass | `groupOfNames` |
| GroupNameAttribute | `cn` |
| GroupIdAttribute | `entryUUID` |
| MembershipAttribute | `member` |
| DomainName | `LDAPSecondary` |
| ReadOnly | `false` |

## Claim mappings

El script `init-claims.sh` / `init-claims.bat` configura los mapeos de claims para el userstore `LDAPSecondary`:

| Claim WSO2 | Atributo LDAP | Descripción |
|-------------|---------------|-------------|
| `http://wso2.org/claims/userid` | `employeeNumber` | Identificador único del usuario |
| `http://wso2.org/claims/username` | `uid` | Nombre de usuario |
| `http://wso2.org/claims/givenname` | `givenName` | Nombre |
| `http://wso2.org/claims/lastname` | `sn` | Apellido |
| `http://wso2.org/claims/emailaddress` | `mail` | Correo electrónico |
| `http://wso2.org/claims/groups` | `memberOf` | Grupos del usuario |
| `http://wso2.org/claims/created` | `createTimestamp` | Fecha de creación |
| `http://wso2.org/claims/modified` | `modifyTimestamp` | Fecha de modificación |

---

## Procedimiento: Construir e iniciar

### Paso 1 — Iniciar los contenedores

```bash
docker compose up -d
```

Esto levanta 3 contenedores:
- `openldap` — Directorio LDAP con datos seed de `ldif/seed.ldif`
- `wso2is` — Identity Server con userstore `LDAPSecondary` auto-desplegado
- `phpldapadmin` — Interfaz web para administrar OpenLDAP

### Paso 2 — Esperar a que WSO2 IS esté listo

```bash
# Verificar logs
docker logs -f wso2is

# Esperar hasta ver: "WSO2 Carbon started in XX sec"
```

O usar el script que ya incluye espera:
```bash
bash init-claims.sh
```

### Paso 3 — Aplicar claim mappings

**Linux / macOS / Git Bash:**
```bash
bash init-claims.sh
```

**Windows CMD:**
```cmd
init-claims.bat
```

### Paso 4 — Seed SCIM metadata para grupos LDAP (OBLIGATORIO)

> **Sin este paso, `GET /scim2/Groups` puede retornar `Resources: []`.**  
> WSO2 IS 7.x no siempre auto-provisiona metadatos SCIM para grupos de userstores externos.

**Linux / macOS / Git Bash:**
```bash
bash seed-scim-groups.sh
```

**Windows CMD:**
```cmd
seed-scim-groups.bat
```

El script:
1. Espera a que WSO2 IS esté listo
2. **Descubre automáticamente** todos los grupos en `ou=groups` de OpenLDAP vía `ldapsearch`
3. Verifica que WSO2 IS detecta los grupos del directorio LDAP
4. **Detiene WSO2 IS** para liberar el lock exclusivo de H2 2.x
5. Ejecuta un contenedor temporal montando el volumen `wso2is_db` para acceder a la base H2
6. Ejecuta DELETE+INSERT idempotente — elimina toda metadata LDAPSecondary previa, luego inserta 4 filas por grupo
7. **Reinicia WSO2 IS** y verifica que los grupos aparecen en SCIM2

> **Nota:** El script es **idempotente** y **dinámico** — puede ejecutarse múltiples veces y descubre automáticamente grupos nuevos o eliminados en OpenLDAP. No necesita editarse al agregar o quitar grupos.

> **Nota técnica:** Aunque `ReadWriteLDAPUserStoreManager` puede auto-provisionar metadata SCIM en algunos casos, el script garantiza que los grupos estén siempre disponibles vía SCIM2.

### Paso 5 — Verificar

```bash
# Usuarios SCIM2
curl -sk -u admin:admin https://localhost:9443/scim2/Users | python -m json.tool

# Grupos del dominio LDAPSECONDARY (debe mostrar 2 grupos con miembros)
curl -sk -u admin:admin "https://localhost:9443/scim2/Groups?domain=LDAPSECONDARY" | python -m json.tool

# Grupos PRIMARY (solo debe tener 'admin')
curl -sk -u admin:admin "https://localhost:9443/scim2/Groups?domain=PRIMARY" | python -m json.tool
```

**Resultado esperado de `/scim2/Groups?domain=LDAPSECONDARY`:**
```json
{
    "totalResults": 2,
    "itemsPerPage": 2,
    "Resources": [
        { "displayName": "LDAPSECONDARY/developers", "members": [{"display": "LDAPSECONDARY/jperez"}, {"display": "LDAPSECONDARY/mgarcia"}] },
        { "displayName": "LDAPSECONDARY/admins", "members": [{"display": "LDAPSECONDARY/jperez"}] }
    ]
}
```

> **Importante:** Los grupos LDAPSECONDARY NO deben aparecer en el dominio PRIMARY. PRIMARY solo contiene el grupo `admin` por defecto.

**Acceso a phpLDAPAdmin:**
1. Abrir http://localhost:8080
2. Login DN: `cn=admin,dc=tsf,dc=axacolpatria,dc=co`
3. Password: `admin`

**Acceso a WSO2 IS Console:**
1. Abrir https://localhost:9443/console
2. Usuario: `admin`
3. Password: `admin`

---

## Gestión de grupos y asignación de usuarios

> **WSO2 IS NO gestiona grupos ni membresías.** Aunque el userstore LDAPSecondary usa `ReadWriteLDAPUserStoreManager`, la gestión de grupos y asignación de usuarios se realiza directamente en el **directorio OpenLDAP** usando herramientas LDAP externas.

### Herramientas disponibles

| Herramienta | Tipo | Descripción |
|-------------|------|-------------|
| phpLDAPAdmin | Web (puerto 8080) | Incluido en el docker-compose — interfaz web para gestión visual |
| Apache Directory Studio | Cliente desktop | Conecta vía LDAP a OpenLDAP (localhost:389) |
| `ldapadd` / `ldapmodify` | CLI | Herramientas LDAP estándar por línea de comandos |

### phpLDAPAdmin (incluido)

1. Abrir http://localhost:8080
2. Login DN: `cn=admin,dc=tsf,dc=axacolpatria,dc=co`
3. Password: `admin`
4. Navegar a `ou=groups` para crear/modificar grupos y membresías

### Conexión con Apache Directory Studio

| Parámetro | Valor |
|-----------|-------|
| Hostname | `localhost` |
| Puerto | `389` |
| Bind DN | `cn=admin,dc=tsf,dc=axacolpatria,dc=co` |
| Password | `admin` |
| Base DN | `dc=tsf,dc=axacolpatria,dc=co` |

### Ejemplos con CLI (`ldapmodify`)

```bash
# Agregar usuario mgarcia al grupo admins
docker exec openldap ldapmodify -x \
  -D "cn=admin,dc=tsf,dc=axacolpatria,dc=co" -w admin <<EOF
dn: cn=admins,ou=groups,dc=tsf,dc=axacolpatria,dc=co
changetype: modify
add: member
member: uid=mgarcia,ou=users,dc=tsf,dc=axacolpatria,dc=co
EOF

# Crear un nuevo grupo
docker exec openldap ldapadd -x \
  -D "cn=admin,dc=tsf,dc=axacolpatria,dc=co" -w admin <<EOF
dn: cn=soporte,ou=groups,dc=tsf,dc=axacolpatria,dc=co
objectClass: groupOfNames
cn: soporte
member: uid=jperez,ou=users,dc=tsf,dc=axacolpatria,dc=co
EOF
```

### Después de modificar grupos

Si se crean nuevos grupos o se eliminan grupos existentes en OpenLDAP, simplemente re-ejecutar el script de seed SCIM. El script **descubre automáticamente** todos los grupos actuales en `ou=groups`:

```bash
# Linux / macOS / Git Bash
bash seed-scim-groups.sh

# Windows CMD
seed-scim-groups.bat
```

> **No es necesario editar el script** al agregar o quitar grupos — la detección es dinámica.

> **Nota:** Los cambios de **membresía** (agregar/quitar usuarios de grupos existentes) se reflejan automáticamente en WSO2 IS sin re-ejecutar el seed, ya que WSO2 IS consulta las membresías en tiempo real desde OpenLDAP.

---

## Detener

```bash
# Detener manteniendo datos
docker compose down

# Detener y eliminar volúmenes (reinicio limpio)
docker compose down -v
```

> **Nota:** Con `-v` se eliminan los volúmenes (bases H2, datos LDAP). En el próximo `up` será necesario ejecutar nuevamente los scripts de claims y seed SCIM.

---

## Procedimiento completo de reconstrucción

Cuando se necesita un entorno limpio desde cero:

```bash
# 1. Destruir todo
docker compose down -v

# 2. Iniciar
docker compose up -d

# 3. Esperar a que WSO2 IS esté listo (~30s)

# 4. Aplicar claims
bash init-claims.sh

# 5. Seed SCIM groups
bash seed-scim-groups.sh

# 6. Verificar
curl -sk -u admin:admin "https://localhost:9443/scim2/Groups?domain=LDAPSECONDARY" | python -m json.tool
```

**En Windows CMD:**
```cmd
docker compose down -v
docker compose up -d
REM Esperar ~30 segundos
init-claims.bat
seed-scim-groups.bat
curl -sk -u admin:admin "https://localhost:9443/scim2/Groups?domain=LDAPSECONDARY" | python -m json.tool
```

---

## Problema conocido: SCIM2 Groups vacío

WSO2 IS 7.x con separación rol/grupo habilitada **no auto-provisiona** metadatos SCIM para grupos de userstores externos. Esto causa que `GET /scim2/Groups` retorne `totalResults > 0` pero `Resources: []`.

**Solución:** El script `seed-scim-groups.sh` / `.bat` inserta los metadatos SCIM directamente en la tabla `IDN_SCIM_GROUP` de la base H2 `WSO2IDENTITY_DB`, usando la misma técnica que el escenario AD (ver [SCENARIO-AD.md](SCENARIO-AD.md#problema-scim2-groups-vacío) para detalles técnicos completos).

---

## Troubleshooting

### WSO2 IS no conecta a OpenLDAP

```bash
# Verificar que OpenLDAP está corriendo
docker logs openldap

# Probar búsqueda LDAP
docker exec openldap ldapsearch -x -H ldap://localhost:389 \
  -D "cn=admin,dc=tsf,dc=axacolpatria,dc=co" \
  -w admin -b "ou=groups,dc=tsf,dc=axacolpatria,dc=co" cn
```

### Grupos no aparecen después del seed

El script usa un volumen Docker compartido. Para verificar manualmente (WSO2 IS debe estar detenido):

```bash
docker stop wso2is

docker run --rm \
  -v identity7groups_wso2is_db:/home/wso2carbon/wso2is-7.2.0/repository/database \
  --entrypoint="" wso2/wso2is:7.2.0 \
  java -cp "/home/wso2carbon/wso2is-7.2.0/repository/components/plugins/h2-engine_2.2.224.wso2v2.jar" \
  org.h2.tools.Shell \
  -url "jdbc:h2:/home/wso2carbon/wso2is-7.2.0/repository/database/WSO2IDENTITY_DB;IFEXISTS=TRUE" \
  -user wso2carbon -password wso2carbon \
  -sql "SELECT * FROM IDN_SCIM_GROUP WHERE ROLE_NAME LIKE 'LDAPSECONDARY/%'"

docker start wso2is
```

---

## Archivos del escenario

| Archivo | Descripción |
|---------|-------------|
| `docker-compose.yml` | Orquestación de los 3 servicios |
| `deployment.toml` | Configuración base WSO2 IS |
| `ldif/seed.ldif` | Usuarios y grupos iniciales |
| `userstores/LDAPSecondary.xml` | Configuración del userstore LDAP |
| `init-claims.sh` | Claim mappings (bash) |
| `init-claims.bat` | Claim mappings (Windows CMD) |
| `seed-scim-groups.sh` | Seed SCIM metadata (bash) |
| `seed-scim-groups.bat` | Seed SCIM metadata (Windows CMD) |
