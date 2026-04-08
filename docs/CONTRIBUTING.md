# Guía de Contribución

## Antes de Empezar

1. Lee la [Guía de Git Workflow](GIT_WORKFLOW.md)
2. Revisa la [Arquitectura](ARCHITECTURE.md)
3. Asegúrate de tener el entorno configurado: `./scripts/setup.sh`

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
