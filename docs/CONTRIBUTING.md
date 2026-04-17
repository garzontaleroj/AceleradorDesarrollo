# Guía de Contribución

## Antes de Empezar

1. Lee la [Guía de Git Workflow](GIT_WORKFLOW.md)
2. Revisa la [Arquitectura](ARCHITECTURE.md)
3. Asegúrate de tener el entorno configurado: `./scripts/setup.sh`
4. Revisa el [Catálogo de Plantillas](../templates/catalog.yaml) antes de crear artefactos nuevos

## Requisitos del Entorno

| Herramienta | Versión Mínima | Obligatorio |
|-------------|----------------|-------------|
| Java JDK | 17+ | ✅ |
| Docker | 24+ | ✅ |
| kubectl | 1.28+ | ✅ |
| Git | 2.40+ | ✅ |
| Ballerina | 2201.9.0 | ❌ (solo para proyectos Ballerina) |
| xmllint | cualquier | ❌ (recomendado para validación XML) |
| Node.js | 18+ | ❌ (solo para tests) |
| Minikube | 1.30+ | ❌ (para demos locales) |

### Entorno Local con Minikube

Para probar despliegues en Kubernetes sin un cluster remoto:

```bash
# Iniciar Minikube (recomendado: 4 CPUs y 8 GB para el stack completo)
minikube start --memory=8192 --cpus=4

# Desplegar un producto específico (construye + despliega)
& "C:\Program Files\Git\bin\bash.exe" scripts/minikube-demo.sh --build --product micro-integrator

# Desplegar todo el stack
& "C:\Program Files\Git\bin\bash.exe" scripts/minikube-demo.sh --build

# Ver estado
& "C:\Program Files\Git\bin\bash.exe" scripts/minikube-demo.sh --status

# Acceder a servicios
kubectl port-forward svc/wso2-micro-integrator -n wso2-dev 8290:8290
kubectl port-forward svc/wso2-api-manager -n wso2-dev 9443:9443

# Limpiar
& "C:\Program Files\Git\bin\bash.exe" scripts/minikube-demo.sh --clean
```

> **Windows**: Usa Git Bash, **no** WSL. WSL no tiene acceso al Minikube de Windows.
> Con solo 2 CPUs de Minikube, usa `--product` para desplegar un solo producto.

### Usando las Plantillas

Consulta `templates/catalog.yaml` para ver la lista completa. Para usar una plantilla:

1. Busca la plantilla en el catálogo por producto, categoría o tags
2. Copia los artefactos de `templates/<path>/` al directorio correspondiente en `projects/`
3. Sigue el README de la plantilla para personalizar valores
4. Adapta los endpoints y parámetros para tu caso de uso

## Estructura de Desarrollo por Producto

### API Manager (`projects/api-manager/`)

- Definiciones OpenAPI en `apis/` (formato YAML)
- Políticas en `policies/` (formato XML)
- Seguir convención de nombres: `kebab-case` para archivos
- Validar con Spectral antes del commit

### Micro Integrator (`projects/micro-integrator/`)

- APIs en `src/main/synapse-config/api/`
- Endpoints en `src/main/synapse-config/endpoints/`
- Proxies en `src/main/synapse-config/proxy-services/`
- Secuencias reutilizables en `src/main/synapse-config/sequences/`
- **Usar PascalCase** para nombres de artefactos XML
- **Nunca hardcodear** URLs de backend — usar endpoints con `uri-template`
- Reutilizar `CommonErrorHandler` para manejo de errores

### Identity Server (`projects/identity-server/`)

- Configuraciones de IdP en `identity-providers/`
- Service Providers en `service-providers/`
- Scripts de auth adaptiva en `templates/`
- No incluir secretos en los archivos de configuración

### Streaming Integrator (`projects/streaming-integrator/`)

- Siddhi Apps en `siddhi-apps/`
- Nombrar apps con PascalCase: `NombreDescriptivo.siddhi`
- Documentar sources y sinks en comentarios del archivo

### Ballerina (`projects/ballerina/`)

- Seguir [Ballerina Style Guide](https://ballerina.io/learn/style-guide/)
- Tests en `tests/`
- Ejecutar `bal test` antes del commit

## Checklist antes del PR

- [ ] El código compila / los artefactos son válidos
- [ ] No hay credenciales en el código
- [ ] Se actualizó la configuración por ambiente si es necesario
- [ ] Se escribieron o actualizaron tests
- [ ] Los commits siguen Conventional Commits
- [ ] El PR llena el template completo
- [ ] Se asignaron los reviewers correctos

## Revisión de Código

### Para Reviewers

1. **Funcionalidad**: ¿El artefacto hace lo que se espera?
2. **Seguridad**: ¿No hay secretos? ¿Se usa `$secret{}` en TOML?
3. **Configurabilidad**: ¿Las URLs y parámetros son configurables por ambiente?
4. **Error handling**: ¿Se manejan los errores correctamente?
5. **Reutilización**: ¿Se reutilizan secuencias/templates existentes?
6. **Naming**: ¿Se siguen las convenciones de nombres?

### Tiempos de Respuesta

| Prioridad | Tiempo máximo de review |
|-----------|------------------------|
| Hotfix | 2 horas |
| Bug | 4 horas |
| Feature | 1 día laboral |
| Refactor | 2 días laborales |

## Reporte de Bugs

Usar el template de [Bug Report](../.github/ISSUE_TEMPLATE/bug_report.md) incluyendo:
- Producto WSO2 afectado
- Ambiente donde se reproduce
- Pasos para reproducir
- Logs relevantes

## Solicitar Features

Usar el template de [Feature Request](../.github/ISSUE_TEMPLATE/feature_request.md) incluyendo:
- Sistemas involucrados
- Diagramas de flujo si aplica
- Impacto en otros productos

## Troubleshooting Común

### Pod no arranca (Insufficient CPU)

Minikube con 2 CPUs no puede correr los 4 productos simultáneamente. Usa `--product` para desplegar solo uno:

```bash
& "C:\Program Files\Git\bin\bash.exe" scripts/minikube-demo.sh --build --product micro-integrator
```

O aumenta los recursos de Minikube:

```bash
minikube stop
minikube delete
minikube start --cpus=4 --memory=8192
```

### Pod en CrashLoopBackOff

```bash
# Ver logs del pod
kubectl logs deployment/wso2-<producto> -n wso2-dev --previous

# Ver eventos del pod
kubectl describe pod -l app.kubernetes.io/name=<producto> -n wso2-dev
```

### Imágenes Docker no se encuentran (ErrImagePull)

Asegúrate de usar `--build` para construir las imágenes directamente en Minikube:

```bash
& "C:\Program Files\Git\bin\bash.exe" scripts/minikube-demo.sh --build
```

### WSL no encuentra Minikube

El script `minikube-demo.sh` requiere **Git Bash**, no WSL. WSL no puede ver el cluster de Minikube que corre en Windows.

### Kustomize genera warnings de commonLabels

Este proyecto ya usa la sintaxis `labels` + `includeSelectors: true`. Si ves warnings en otro overlay, actualiza la kustomization.yaml correspondiente.
