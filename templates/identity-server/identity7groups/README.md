# WSO2 Identity Server 7.2.0 — Integración SCIM2 con LDAP / Active Directory

Entorno local Docker para pruebas de integración **SCIM2** de **WSO2 Identity Server 7.2.0** con directorios externos.  
Simula la infraestructura de **AXA Colpatria TSTF** (`TSTF.AXACOLPATRIA.CO`).

---

## Escenarios

| # | Escenario | Directorio externo | Compose file | Documentación |
|---|-----------|-------------------|--------------|---------------|
| 1 | **OpenLDAP** (simple) | `osixia/openldap` + phpLDAPAdmin | `docker-compose.yml` | [docs/SCENARIO-LDAP.md](docs/SCENARIO-LDAP.md) |
| 2 | **Active Directory** (Samba AD DC) | Samba 4 Domain Controller | `docker-compose-ad.yml` | [docs/SCENARIO-AD.md](docs/SCENARIO-AD.md) |

Ambos escenarios comparten el archivo `deployment.toml` (configuración base de WSO2 IS).

---

## Requisitos previos

- **Docker Desktop** (Windows/macOS) o **Docker Engine + Docker Compose** (Linux)
- **curl** (para scripts de claim mapping y SCIM seeding)
- **Git Bash** o **WSL** (para ejecutar scripts `.sh` en Windows)
- Puerto **9443** libre (WSO2 IS console)
- Puerto **389** libre (LDAP/AD)

---

## Inicio rápido

### Escenario 1 — OpenLDAP

```bash
# Construir e iniciar
docker compose up -d

# Aplicar claim mappings (Linux/macOS/Git Bash)
bash init-claims.sh

# Seed SCIM metadata para grupos LDAP (OBLIGATORIO)
bash seed-scim-groups.sh
```

> **Windows (CMD):** Usar `init-claims.bat` y `seed-scim-groups.bat`.

**Verificar:**
```bash
# Usuarios SCIM2
curl -sk -u admin:admin https://localhost:9443/scim2/Users | python -m json.tool

# Grupos SCIM2 del dominio LDAPSECONDARY
curl -sk -u admin:admin "https://localhost:9443/scim2/Groups?domain=LDAPSECONDARY" | python -m json.tool
```

### Escenario 2 — Active Directory (Samba AD DC)

```bash
# Construir e iniciar (primera vez incluye build de imagen Samba)
docker compose -f docker-compose-ad.yml up -d --build

# Esperar ~30s a que Samba provisione el dominio y cree usuarios
# Luego aplicar claim mappings
bash init-claims-ad.sh

# Seed SCIM metadata para grupos AD (OBLIGATORIO)
bash seed-scim-groups-ad.sh
```

**Verificar:**
```bash
# Usuarios SCIM2 (debería devolver ~5 usuarios)
curl -sk -u admin:admin https://localhost:9443/scim2/Users?count=10 | python -m json.tool

# Grupos SCIM2 del dominio TSTF (debería devolver 4 grupos AD)
curl -sk -u admin:admin "https://localhost:9443/scim2/Groups?domain=TSTF" | python -m json.tool
```

> **Windows (CMD):**  Usar `init-claims-ad.bat` y `seed-scim-groups-ad.bat` en lugar de los `.sh`.

---

## Detener y limpiar

```bash
# Escenario 1 (LDAP)
docker compose down -v

# Escenario 2 (AD)
docker compose -f docker-compose-ad.yml down -v
```

El flag `-v` elimina volúmenes (bases H2, datos LDAP/Samba). Omitirlo para preservar datos entre reinicios.

> **Nota:** Después de recrear con `-v`, es necesario ejecutar nuevamente los scripts de claims y seed SCIM.

---

## Estructura del proyecto

```
├── README.md                          ← Este archivo
├── docs/
│   ├── SCENARIO-LDAP.md               ← Documentación escenario OpenLDAP
│   └── SCENARIO-AD.md                 ← Documentación escenario Active Directory
│
├── deployment.toml                     ← Configuración WSO2 IS (compartida)
│
├── docker-compose.yml                  ← Compose: OpenLDAP + WSO2 IS + phpLDAPAdmin
├── docker-compose-ad.yml               ← Compose: Samba AD DC + WSO2 IS
│
├── ldif/
│   └── seed.ldif                       ← Datos iniciales OpenLDAP (usuarios + grupos)
│
├── userstores/
│   ├── LDAPSecondary.xml               ← Userstore para OpenLDAP
│   └── ADReadOnly.xml                  ← (referencia)
│
├── userstores-ad/
│   ├── TSTF.xml                        ← Userstore Active Directory
│   └── AGENT.xml                       ← Userstore AgentUserStoreManager
│
├── samba-ad/
│   ├── Dockerfile                      ← Imagen Docker Samba AD DC
│   ├── entrypoint.sh                   ← Provisioning + startup Samba
│   └── init-users.sh                   ← Crea OUs, usuarios, grupos en AD
│
├── init-claims.sh / .bat               ← Claim mappings escenario LDAP
├── init-claims-ad.sh / .bat            ← Claim mappings escenario AD├── seed-scim-groups.sh / .bat          ← Seed SCIM metadata para grupos LDAP├── seed-scim-groups-ad.sh / .bat       ← Seed SCIM metadata para grupos AD
```

---

## Problema conocido: SCIM2 Groups vacío con userstores externos

WSO2 IS 7.x con separación rol/grupo habilitada **no auto-provisiona** metadatos SCIM para grupos de userstores LDAP/AD externos. Esto causa que `GET /scim2/Groups` retorne `totalResults > 0` pero `Resources: []`.

**Solución:** Los scripts `seed-scim-groups-ad.sh` y `seed-scim-groups.sh` insertan los metadatos SCIM (id, meta.created, meta.lastModified, meta.location) directamente en la tabla `IDN_SCIM_GROUP` de la base H2 `WSO2IDENTITY_DB`. Estos scripts deben ejecutarse después de cada recreación del entorno Docker.

> **Técnica:** Los scripts detienen WSO2 IS, montan el volumen `wso2is_db` en un contenedor temporal, ejecutan DELETE+INSERT idempotente, y reinician WSO2 IS.

Para detalles técnicos completos de la causa raíz, ver [docs/SCENARIO-AD.md](docs/SCENARIO-AD.md#problema-scim2-groups-vacío).

---

## Credenciales

| Servicio | Usuario | Contraseña |
|----------|---------|------------|
| WSO2 IS Console | `admin` | `admin` |
| OpenLDAP Admin | `cn=admin,dc=tsf,dc=axacolpatria,dc=co` | `admin` |
| phpLDAPAdmin | `cn=admin,dc=tsf,dc=axacolpatria,dc=co` | `admin` |
| Samba AD Admin | `Administrator` | `P@ssw0rd2024` |
| WSO2 Service Account (AD) | `Axaservicewso2Tip` | `S3rv1c3@WSO2tip` |
| Usuarios de prueba AD | `jperez` / `mgarcia` / `clopez` / `arivera` | `P@ssw0rd123!` |
| Usuarios de prueba LDAP | `jperez` / `mgarcia` | `password123` |

---

## URLs de acceso

| Servicio | URL |
|----------|-----|
| WSO2 IS Console | https://localhost:9443/console |
| WSO2 Carbon Admin | https://localhost:9443/carbon |
| SCIM2 Users | https://localhost:9443/scim2/Users |
| SCIM2 Groups | https://localhost:9443/scim2/Groups |
| phpLDAPAdmin (solo escenario LDAP) | http://localhost:8080 |
