# Git Workflow — GitHub Flow para WSO2

## Estrategia de Branching

Este proyecto usa **GitHub Flow**, un modelo simple y efectivo para equipos que hacen despliegues continuos.

```
main ─────●──────●──────●──────●──────●──────→
           \    /        \    /        \    /
            feature/     feature/     hotfix/
            APIM-123     MI-456       IS-789
```

## Ramas

| Rama | Propósito | Protección |
|------|-----------|------------|
| `main` | Código estable, listo para producción | Protegida: requiere PR + review + CI verde |
| `feature/*` | Nuevas funcionalidades | Convención de nombres: `feature/<producto>-<descripción>` |
| `bugfix/*` | Corrección de bugs | Convención: `bugfix/<producto>-<descripción>` |
| `hotfix/*` | Correcciones urgentes en producción | Convención: `hotfix/<producto>-<descripción>` |

## Convención de Nombres de Ramas

```
feature/apim-nueva-politica-rate-limit
feature/mi-servicio-facturacion
feature/is-configuracion-mfa
feature/si-procesador-eventos-iot
feature/bal-servicio-notificaciones
bugfix/mi-timeout-endpoint-pagos
hotfix/apim-fix-cors-produccion
```

## Flujo de Trabajo Diario

### 1. Crear rama desde `main`

```bash
git checkout main
git pull origin main
git checkout -b feature/mi-nuevo-servicio-clientes
```

### 2. Desarrollar y hacer commits

```bash
# Commits frecuentes y descriptivos
git add projects/micro-integrator/src/main/synapse-config/api/ClientesAPI.xml
git commit -m "feat(mi): agregar API de clientes con endpoint REST

- Crea mediación para GET /clientes
- Agrega endpoint hacia backend de CRM
- Incluye manejo de errores con CommonErrorHandler"

git add projects/micro-integrator/src/main/synapse-config/endpoints/CrmBackendEP.xml
git commit -m "feat(mi): agregar endpoint backend CRM"
```

### 3. Push y crear Pull Request

```bash
git push origin feature/mi-nuevo-servicio-clientes
```

Luego, en GitHub:
1. Crear Pull Request hacia `main`
2. Llenar el template de PR
3. Asignar reviewers del equipo correspondiente (ver CODEOWNERS)
4. Esperar que CI pase ✅

### 4. Code Review

- Mínimo **1 aprobación** requerida
- CI debe pasar (validación XML, linting, tests)
- El reviewer debe verificar:
  - [ ] Artefactos WSO2 correctos (XML well-formed, TOML válido)
  - [ ] No hay credenciales hardcodeadas
  - [ ] Los endpoints usan variables de entorno
  - [ ] Tests actualizados si aplica

### 5. Merge a `main`

- Usar **Squash and Merge** para mantener historial limpio
- El merge a `main` dispara automáticamente el deploy a **DEV**

## Flujo de Despliegue

```
 PR merge → main → [Auto] DEV → [Manual] QA → [Manual+Approval] STAGING → [Manual+Approval] PROD
```

| Ambiente | Trigger | Aprobación | Tests |
|----------|---------|------------|-------|
| **DEV** | Automático (merge a main) | No | Smoke tests |
| **QA** | Manual (workflow_dispatch) | No | E2E tests |
| **STAGING** | Manual (workflow_dispatch) | Sí (1 approver) | Regresión |
| **PROD** | Manual (workflow_dispatch) | Sí (2 approvers) | Smoke + Release tag |

## Conventional Commits

Usamos [Conventional Commits](https://www.conventionalcommits.org/) con prefijo de producto:

```
<tipo>(<producto>): <descripción>

[cuerpo opcional]

[footer opcional]
```

### Tipos

| Tipo | Uso |
|------|-----|
| `feat` | Nueva funcionalidad |
| `fix` | Corrección de bug |
| `refactor` | Cambio de código sin cambio funcional |
| `docs` | Documentación |
| `ci` | Cambios en CI/CD |
| `config` | Cambios de configuración |
| `test` | Tests |
| `chore` | Tareas de mantenimiento |

### Productos (scopes)

| Scope | Producto |
|-------|----------|
| `apim` | API Manager |
| `mi` | Micro Integrator |
| `is` | Identity Server |
| `si` | Streaming Integrator |
| `bal` | Ballerina |
| `infra` | Docker / Kubernetes |
| `ci` | GitHub Actions |

### Ejemplos

```
feat(apim): agregar política de rate limiting para API de pagos
fix(mi): corregir timeout en endpoint de facturación
config(is): actualizar configuración OAuth para nuevo proveedor
ci(infra): agregar validación de Kustomize en pipeline
docs(bal): documentar servicio de notificaciones
```

## Protección de Ramas

Configurar en GitHub → Settings → Branches → Branch protection rules para `main`:

- [x] Require a pull request before merging
- [x] Require approvals (1 mínimo)
- [x] Require status checks to pass (CI workflow)
- [x] Require branches to be up to date before merging
- [x] Require conversation resolution before merging
- [x] Do not allow bypassing the above settings
