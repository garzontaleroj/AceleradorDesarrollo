# Plantilla: Despliegue en OpenChoreo — Plataforma de Desarrollo Kubernetes

## Descripción
Plantilla base para desplegar componentes WSO2 (API Manager, Micro Integrator)
y servicios Ballerina en [OpenChoreo](https://github.com/openchoreo/openchoreo),
la plataforma de desarrollo open-source para Kubernetes (CNCF Sandbox).

OpenChoreo proporciona una experiencia de plataforma interna de desarrollo (IDP)
con portal de desarrolladores (Backstage), CI/CD integrado (Argo Workflows),
y observabilidad nativa.

## Caso de uso
Desplegar y gestionar componentes de integración WSO2 en una plataforma Kubernetes
con experiencia de desarrollador mejorada: catálogo de servicios, builds automáticos,
despliegues declarativos y observabilidad out-of-the-box.

## Artefactos

| Archivo | Tipo | Descripción |
|---------|------|-------------|
| `component.yaml` | Manifiesto | Definición de componente OpenChoreo |
| `endpoints.yaml` | Configuración | Exposición de endpoints del servicio |
| `docker-compose.yml` | Infraestructura | Stack local OpenChoreo (Kubernetes in Docker) |

## Variables

| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `COMPONENT_NAME` | Nombre del componente | `mi-customers-api` |
| `COMPONENT_TYPE` | Tipo de componente (`service`, `web-app`, `job`) | `service` |
| `CONTAINER_IMAGE` | Imagen Docker del componente | `wso2/wso2mi:4.3.0` |
| `CONTAINER_PORT` | Puerto del contenedor | `8290` |
| `ORGANIZATION` | Organización en OpenChoreo | `ticxar` |
| `PROJECT` | Proyecto en OpenChoreo | `integraciones` |

## Requisitos previos

- Kubernetes 1.28+ (Minikube, kind, o cluster real)
- kubectl 1.28+
- Helm 3.x
- Git 2.40+
- 8 GB RAM disponible mínimo (para OpenChoreo + componentes)

## Instalación de OpenChoreo

### Opción 1: Minikube (desarrollo local)

```bash
# Iniciar Minikube con recursos suficientes
minikube start --memory=8192 --cpus=4 --kubernetes-version=v1.28.0

# Agregar el repositorio Helm de OpenChoreo
helm repo add openchoreo https://openchoreo.github.io/openchoreo
helm repo update

# Instalar OpenChoreo
helm install openchoreo openchoreo/openchoreo \
  --namespace openchoreo-system \
  --create-namespace \
  --wait --timeout 10m
```

### Opción 2: kind (Kubernetes in Docker)

```bash
# Crear cluster kind
kind create cluster --name openchoreo --config kind-config.yaml

# Instalar OpenChoreo
helm install openchoreo openchoreo/openchoreo \
  --namespace openchoreo-system \
  --create-namespace \
  --wait --timeout 10m
```

## Despliegue de un componente

### 1. Crear el componente

Aplicar el manifiesto `component.yaml`:

```bash
kubectl apply -f component.yaml
```

### 2. Verificar el despliegue

```bash
# Ver estado del componente
kubectl get components -n {{ORGANIZATION}}-{{PROJECT}}

# Ver los pods
kubectl get pods -n {{ORGANIZATION}}-{{PROJECT}}

# Ver los logs
kubectl logs -l app={{COMPONENT_NAME}} -n {{ORGANIZATION}}-{{PROJECT}}
```

### 3. Acceder al portal de desarrolladores

```bash
# Port-forward al portal Backstage
kubectl port-forward svc/openchoreo-backstage -n openchoreo-system 7007:7007

# Abrir http://localhost:7007
```

## Ejemplo: Desplegar Micro Integrator

```yaml
# component.yaml para MI
apiVersion: core.choreo.dev/v1alpha1
kind: Component
metadata:
  name: mi-customers-api
  namespace: ticxar-integraciones
spec:
  type: service
  source:
    image: wso2/wso2mi:4.3.0
  ports:
    - name: http
      port: 8290
      protocol: HTTP
    - name: https
      port: 8253
      protocol: HTTPS
```

## Ejemplo: Desplegar API Manager

```yaml
# component.yaml para APIM
apiVersion: core.choreo.dev/v1alpha1
kind: Component
metadata:
  name: apim-gateway
  namespace: ticxar-integraciones
spec:
  type: service
  source:
    image: wso2/wso2am:4.3.0
  ports:
    - name: console
      port: 9443
      protocol: HTTPS
    - name: gateway-https
      port: 8243
      protocol: HTTPS
    - name: gateway-http
      port: 8280
      protocol: HTTP
```

## Diagrama

```
┌──────────────────────────────────────────────────────────┐
│                   OpenChoreo Platform                     │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Backstage   │  │     Argo     │  │ Observability│  │
│  │   Portal      │  │   Workflows  │  │    Plane     │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │              Kubernetes Cluster                     │  │
│  │                                                    │  │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────────────┐  │  │
│  │  │   APIM   │ │    MI    │ │  Ballerina Svc   │  │  │
│  │  │ Gateway  │ │  APIs    │ │                   │  │  │
│  │  └──────────┘ └──────────┘ └──────────────────┘  │  │
│  └────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

## Notas

- OpenChoreo es un proyecto CNCF Sandbox (v1.0.0 publicado).
- La API de componentes (`core.choreo.dev/v1alpha1`) puede cambiar en versiones futuras.
- OpenChoreo usa **Cloud Native Buildpacks** para builds automáticos desde código fuente.
- El portal Backstage permite registrar y descubrir todos los componentes del equipo.
- Para producción, configurar un Ingress Controller y certificados TLS.
