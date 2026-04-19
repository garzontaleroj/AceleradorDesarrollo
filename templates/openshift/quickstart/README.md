# OpenShift Container Platform — Quickstart Template

Plantilla base para desplegar aplicaciones en **Red Hat OpenShift Container Platform (OCP)**.
Incluye un OpenShift Template completo con BuildConfig, ImageStream, Deployment, Service y Route,
además de manifiestos Kubernetes individuales para despliegues con `oc apply` o Kustomize.

Basado en las prácticas de [Red Hat CoP — Container Quickstarts](https://github.com/jminthorne/ocp-quickstarts/).

## Contenido

```
openshift/quickstart/
├── README.md                      ← Este archivo
├── Dockerfile                     ← Multi-stage Dockerfile (Java 17)
├── openshift-template.yaml        ← OpenShift Template (BuildConfig + IS + Deploy + Svc + Route)
└── k8s/
    ├── kustomization.yaml         ← Base Kustomize
    ├── namespace.yaml             ← Namespace del proyecto
    ├── deployment.yaml            ← Deployment con health checks
    ├── service.yaml               ← ClusterIP Service
    └── route.yaml                 ← Route con TLS edge
```

## Requisitos

| Herramienta | Versión |
|-------------|---------|
| OpenShift CLI (`oc`) | 4.12+ |
| Docker / Podman | 24+ / 4+ |
| Java JDK (si construye local) | 17+ |
| Maven (si construye local) | 3.9+ |

## Uso Rápido

### Opción 1: OpenShift Template (recomendado para OCP)

Despliega todo de una vez usando el template parametrizado:

```bash
# Crear un nuevo proyecto
oc new-project mi-app-dev

# Procesar e instanciar el template
oc process -f openshift-template.yaml \
  -p APP_NAME=mi-aplicacion \
  -p SOURCE_REPOSITORY_URL=https://github.com/tu-org/tu-repo.git \
  -p SOURCE_REPOSITORY_REF=main \
  | oc apply -f -

# Seguir la build
oc logs -f bc/mi-aplicacion

# Verificar el despliegue
oc get pods -w
oc get route mi-aplicacion
```

### Opción 2: Manifiestos individuales con Kustomize

Para entornos donde se prefiere `oc apply` o pipelines GitOps:

```bash
# Aplicar base
oc apply -k k8s/

# O aplicar individualmente
oc apply -f k8s/namespace.yaml
oc apply -f k8s/deployment.yaml
oc apply -f k8s/service.yaml
oc apply -f k8s/route.yaml
```

### Opción 3: Build + Deploy manual

```bash
# Construir imagen con Podman/Docker
podman build -t mi-app:latest .

# Subir a registro interno de OCP
podman tag mi-app:latest image-registry.openshift-image-registry.svc:5000/mi-app-dev/mi-app:latest
oc registry login --insecure=true
podman push image-registry.openshift-image-registry.svc:5000/mi-app-dev/mi-app:latest

# Desplegar
oc apply -f k8s/deployment.yaml
oc apply -f k8s/service.yaml
oc apply -f k8s/route.yaml
```

## Personalización

### Parámetros del Template

| Parámetro | Descripción | Default |
|-----------|-------------|---------|
| `APP_NAME` | Nombre de la aplicación | `ocp-quickstart` |
| `NAMESPACE` | Proyecto OCP | `ocp-quickstart-dev` |
| `SOURCE_REPOSITORY_URL` | URL del repositorio Git | (requerido) |
| `SOURCE_REPOSITORY_REF` | Rama o tag del repositorio | `main` |
| `SOURCE_CONTEXT_DIR` | Subdirectorio con el Dockerfile | `.` |
| `APP_PORT` | Puerto de la aplicación | `8080` |
| `REPLICAS` | Número de réplicas | `1` |
| `CPU_REQUEST` | CPU request por pod | `100m` |
| `CPU_LIMIT` | CPU limit por pod | `500m` |
| `MEMORY_REQUEST` | Memoria request por pod | `256Mi` |
| `MEMORY_LIMIT` | Memoria limit por pod | `512Mi` |

### Adaptar a tu aplicación

1. **Dockerfile**: Modificar la imagen base y los pasos de build según tu stack (Node.js, Python, Go, etc.)
2. **Health checks**: Ajustar los paths `/health/live` y `/health/ready` a tus endpoints
3. **Variables de entorno**: Agregar ConfigMaps/Secrets en el Deployment
4. **TLS**: Cambiar la terminación TLS en la Route si necesitas passthrough o re-encrypt
5. **Autoscaling**: Agregar HorizontalPodAutoscaler si se requiere escalado automático

## Troubleshooting

```bash
# Ver eventos del proyecto
oc get events --sort-by='.lastTimestamp'

# Ver logs del build
oc logs -f bc/mi-aplicacion

# Ver logs del pod
oc logs -f deployment/mi-aplicacion

# Depurar pod
oc debug deployment/mi-aplicacion

# Verificar route
oc describe route mi-aplicacion
```

## Referencias

- [Red Hat OpenShift Documentation](https://docs.openshift.com/)
- [OCP Quickstarts — Red Hat CoP](https://github.com/jminthorne/ocp-quickstarts/)
- [S2I (Source-to-Image)](https://github.com/openshift/source-to-image)
- [OpenShift Templates](https://docs.openshift.com/container-platform/latest/openshift_images/using-templates.html)
