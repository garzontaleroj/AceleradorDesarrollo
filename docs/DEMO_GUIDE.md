# Guía de Presentación — WSO2 Development Accelerator

## Objetivo

Guía paso a paso para demostrar el **AceleradorDesarrollo** a equipos de desarrollo.
Cubre preparación, flujo de demo en vivo, y puntos clave a comunicar.

---

## Antes de la Demo

### Checklist Pre-Demo

- [ ] Minikube corriendo: `minikube status`
- [ ] kubectl configurado: `kubectl cluster-info`
- [ ] Docker accesible: `docker ps` (sin errores)
- [ ] Git Bash disponible: `C:\Program Files\Git\bin\bash.exe`
- [ ] Repositorio clonado y actualizado: `git pull origin main`
- [ ] Terminal con fuente legible (tamaño 14+ para proyección)
- [ ] Navegador listo con pestañas cerradas (pantalla limpia)

### Limpieza Previa (Entorno Fresco)

```powershell
# Desde PowerShell
& "C:\Program Files\Git\bin\bash.exe" scripts/minikube-demo.sh --clean
```

### Tiempo Estimado

| Sección | Duración |
|---------|----------|
| Introducción y contexto | 5 min |
| Estructura del proyecto | 5 min |
| Demo en vivo: Build + Deploy | 10 min |
| Acceso y verificación | 5 min |
| Plantillas y catálogo | 10 min |
| Ambientes y CI/CD | 5 min |
| Q&A | 10 min |
| **Total** | **~50 min** |

---

## Flujo de la Presentación

### 1. Introducción (5 min)

**Qué comunicar:**
- Problema que resuelve: estandarización de proyectos WSO2 en TICXAR
- 4 productos WSO2 + Ballerina en un solo repositorio
- CI/CD automatizado con GitHub Actions
- Ambientes desde local (Minikube) hasta producción

**Puntos clave:**
> "Este acelerador les da a los desarrolladores una base lista para producción
> desde el día 1 — con estructura, plantillas, Docker, Kubernetes y CI/CD
> ya configurados."

### 2. Estructura del Proyecto (5 min)

Abrir VS Code o la terminal y mostrar la estructura:

```bash
# Mostrar estructura de alto nivel
tree -L 2 -d
```

**Carpetas clave a señalar:**

| Carpeta | Qué contiene | Por qué importa |
|---------|-------------|------------------|
| `projects/` | Artefactos WSO2 (APIs, Siddhi, SPs) | Donde el equipo trabaja día a día |
| `templates/` | 24 plantillas reutilizables | Arranque rápido, no empezar de cero |
| `infrastructure/` | Docker + K8s (Kustomize) | Infraestructura reproducible |
| `config/` | `deployment.toml` por ambiente | Configuración separada del código |
| `scripts/` | Build, deploy, test, demo | Automatización con un comando |
| `docs/` | Arquitectura, workflow, ambientes | Onboarding rápido |

### 3. Demo en Vivo: Build + Deploy (10 min)

**Este es el momento más impactante de la demo.** Mostrar que con un solo
comando se construye y despliega un producto WSO2 en Kubernetes local.

#### Paso 1 — Ejecutar el deploy

```powershell
& "C:\Program Files\Git\bin\bash.exe" scripts/minikube-demo.sh --build --product micro-integrator
```

**Mientras construye, comentar:**
- "Estamos construyendo la imagen Docker directamente en Minikube"
- "Usa el Dockerfile de `infrastructure/docker/micro-integrator/`"
- "Aplica los manifiestos de Kubernetes con Kustomize"
- "Solo desplegamos MI porque Minikube tiene recursos limitados"

#### Paso 2 — Verificar estado

```powershell
& "C:\Program Files\Git\bin\bash.exe" scripts/minikube-demo.sh --status
```

Mostrar que el pod está `Running` y `1/1 Ready`.

#### Paso 3 — Ver logs

```powershell
& "C:\Program Files\Git\bin\bash.exe" scripts/minikube-demo.sh --logs micro-integrator
```

Señalar el mensaje de startup exitoso de WSO2 MI.

### 4. Acceso y Verificación (5 min)

#### Opción A — Port-forward automático

```powershell
& "C:\Program Files\Git\bin\bash.exe" scripts/minikube-demo.sh --tunnel
```

Esto abre port-forwards a todos los productos desplegados y muestra las URLs.

#### Opción B — Port-forward manual

```powershell
kubectl port-forward svc/wso2-micro-integrator -n wso2-dev 8290:8290 8253:8253
```

#### Verificar en navegador o curl

```bash
# Verificar que MI responde
curl -k http://localhost:8290/services
```

**Tabla de puertos locales por producto:**

| Producto | Puerto Local | URL |
|----------|-------------|-----|
| API Manager | 9443 | `https://localhost:9443/carbon` |
| API Manager Gateway | 8243 / 8280 | `https://localhost:8243` / `http://localhost:8280` |
| Micro Integrator | 8290 | `http://localhost:8290/services` |
| Identity Server | 9444 | `https://localhost:9444/console` |
| Streaming Integrator | 9445 | `https://localhost:9445/carbon` |

> **Nota:** IS usa `9444` y SI usa `9445` para evitar conflicto con APIM en `9443`.

### 5. Plantillas y Catálogo (10 min)

Abrir `templates/catalog.yaml` y mostrar el catálogo de 24 plantillas:

| Producto | Plantillas | Ejemplos |
|----------|-----------|----------|
| Micro Integrator | 7 | REST CRUD, Proxy, OAuth2, Content Router, Store & Forward, OpenTelemetry |
| API Manager | 3 | OpenAPI spec, Rate Limiting, OpenTelemetry |
| Identity Server | 4 | SPA OAuth2, Azure AD, Adaptive Auth, SCIM2 Groups |
| Streaming Integrator | 1 | Event Processor |
| Ballerina | 1 | HTTP Service |
| OpenChoreo | 1 | Getting Started |
| Karate | 1 | API Testing |
| Quarkus | 2 | REST API, Quickstarts (100+ ejemplos oficiales) |
| Spring Boot | 1 | REST API |
| Python | 1 | FastAPI REST |
| OpenShift (OCP) | 1 | Quickstart (BuildConfig + Deploy + Route) |
| Docker Compose | 1 | Awesome Compose (40+ stacks multi-servicio) |
| **Total** | **24** | |

**Demo sugerida — mostrar una plantilla concreta:**

```bash
# Abrir la plantilla REST CRUD
cat templates/micro-integrator/rest-api/crud-api/api.xml
```

**Qué comunicar:**
> "Cada plantilla tiene su XML/YAML listo para copiar y adaptar.
> El catálogo tiene descripción, dificultad, tiempo estimado y prerequisitos.
> Un desarrollador nuevo puede desplegar su primera API en 15 minutos."

### 6. Ambientes y CI/CD (5 min)

Mostrar la tabla de ambientes (abrir `docs/ENVIRONMENTS.md` o proyectar):

| Ambiente | Trigger | Aprobación |
|----------|---------|------------|
| LOCAL | Manual (minikube-demo.sh) | N/A |
| DEV | Auto al merge a main | Automático |
| QA | Manual + E2E tests | Manual |
| STAGING | Manual + aprobación | Manual + Approval |
| PROD | Manual + release | Manual + 2 Approvals |

**Puntos clave:**
- "Cada ambiente tiene su propio namespace en Kubernetes"
- "La configuración (`deployment.toml`) está separada por ambiente en `config/`"
- "Los overlays de Kustomize aplican patches específicos por ambiente"
- "El pipeline de CI valida estructura, XML y corre tests antes de merge"

### 7. Q&A (10 min)

**Preguntas frecuentes y respuestas preparadas:**

**P: ¿Puedo usar esto con mi proyecto WSO2 existente?**
> Sí. Copias tus artefactos a `projects/<producto>/` y ajustas la configuración
> en `config/`. La infraestructura Docker y K8s funciona sin cambios.

**P: ¿Qué pasa si solo uso Micro Integrator, no los 4 productos?**
> Perfecto. Usa `--product micro-integrator` para desplegar solo MI.
> En K8s los demás deployments se escalan a 0 réplicas.

**P: ¿Cómo agrego una nueva API?**
> 1. Copia una plantilla de `templates/micro-integrator/rest-api/`
> 2. Adapta los XML en `projects/micro-integrator/src/main/synapse-config/api/`
> 3. Haz commit, push, y el CI valida automáticamente

**P: ¿Necesito Minikube para desarrollar?**
> No es obligatorio. Docker Compose (`infrastructure/docker/docker-compose.yml`)
> también levanta el stack. Minikube da la experiencia más cercana a producción.

**P: ¿Qué versiones de WSO2 soporta?**
> APIM 4.3.0, MI 4.3.0, IS 7.0.0, SI 4.2.0 y Ballerina 2201.9.0.

---

## Troubleshooting en Vivo

Problemas comunes durante la demo y cómo resolverlos rápidamente:

| Problema | Solución rápida |
|----------|----------------|
| Minikube no arranca | `minikube delete && minikube start --memory=8192 --cpus=4` |
| Pod en CrashLoopBackOff | Recursos insuficientes — usar `--product` para desplegar 1 solo |
| Port-forward no conecta | Verificar que el pod esté `Running`: `kubectl get pods -n wso2-dev` |
| "image pull backoff" | Asegurar que se usó `--build` para construir las imágenes locales |
| WSL error | Usar Git Bash, no WSL: `& "C:\Program Files\Git\bin\bash.exe" ...` |
| Timeout en rollout | WSO2 tarda 1-3 min en iniciar — esperar y revisar logs |

---

## Demo Rápida (5 minutos)

Si el tiempo es limitado, esta es la versión condensada:

```powershell
# 1. Build + deploy (3 min)
& "C:\Program Files\Git\bin\bash.exe" scripts/minikube-demo.sh --build --product micro-integrator

# 2. Verificar (30 seg)
& "C:\Program Files\Git\bin\bash.exe" scripts/minikube-demo.sh --status

# 3. Acceder (1 min)
kubectl port-forward svc/wso2-micro-integrator -n wso2-dev 8290:8290
# → Abrir http://localhost:8290/services en navegador

# 4. Mostrar plantillas (30 seg)
# → Abrir templates/catalog.yaml y señalar las 24 plantillas
```

**Mensaje final:**
> "Con este acelerador, un desarrollador nuevo puede tener un entorno WSO2
> completo corriendo en Kubernetes en menos de 10 minutos, con plantillas
> listas para empezar a desarrollar integraciones."

---

## Limpieza Post-Demo

```powershell
& "C:\Program Files\Git\bin\bash.exe" scripts/minikube-demo.sh --clean
```
