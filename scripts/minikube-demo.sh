#!/usr/bin/env bash
# =============================================================================
# minikube-demo.sh — Despliegue local con Minikube para demos y desarrollo
# =============================================================================
# Uso: ./scripts/minikube-demo.sh [--product PRODUCT] [--build] [--clean]
#
# Este script permite a los desarrolladores:
#   1. Construir imágenes Docker directamente en Minikube
#   2. Desplegar productos WSO2 en el cluster local
#   3. Exponer servicios para pruebas locales
#   4. Limpiar el entorno cuando se necesite
# =============================================================================
# REQUISITO: Ejecutar con Git Bash en Windows, NO con WSL.
#   & "C:\Program Files\Git\bin\bash.exe" scripts/minikube-demo.sh [opciones]
# =============================================================================
set -euo pipefail

# --- Detección de entorno: rechazar WSL (no ve el minikube de Windows) ---
case "$(uname -s)" in
  Linux*)
    if grep -qi microsoft /proc/version 2>/dev/null || [ -f /proc/sys/fs/binfmt_misc/WSLInterop ]; then
      echo "❌ Este script se está ejecutando en WSL, que no tiene acceso al minikube de Windows."
      echo "   Ejecuta con Git Bash:"
      echo "   & \"C:\\Program Files\\Git\\bin\\bash.exe\" scripts/minikube-demo.sh $*"
      exit 1
    fi
    ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

PRODUCT=""
BUILD=false
CLEAN=false
NAMESPACE="wso2-dev"

PRODUCTS=("api-manager" "micro-integrator" "identity-server" "streaming-integrator")

usage() {
  cat <<EOF
Uso: $0 [opciones]

Opciones:
  --product PRODUCT   Despliega solo un producto (api-manager|micro-integrator|identity-server|streaming-integrator)
  --build             Construye las imágenes Docker en Minikube antes de desplegar
  --clean             Limpia el namespace y todos los recursos
  --status            Muestra el estado actual del despliegue
  --logs PRODUCT      Muestra los logs de un producto
  --tunnel            Abre un túnel para acceder a los servicios
  -h, --help          Muestra esta ayuda

Ejemplos:
  $0 --build                           # Construye y despliega todo
  $0 --product micro-integrator --build # Construye y despliega solo MI
  $0 --status                          # Muestra estado
  $0 --clean                           # Limpia todo
  $0 --logs micro-integrator           # Ver logs de MI
  $0 --tunnel                          # Accede a los servicios

EOF
  exit 0
}

show_status() {
  echo ""
  echo "============================================="
  echo " Estado del Despliegue WSO2 en Minikube"
  echo "============================================="
  echo ""
  echo ">> Nodo Minikube:"
  minikube status 2>/dev/null || echo "   Minikube no está corriendo"
  echo ""
  echo ">> Pods en namespace $NAMESPACE:"
  kubectl get pods -n "$NAMESPACE" -o wide 2>/dev/null || echo "   Namespace no existe"
  echo ""
  echo ">> Servicios en namespace $NAMESPACE:"
  kubectl get svc -n "$NAMESPACE" 2>/dev/null || echo "   Namespace no existe"
  echo ""
  echo ">> URLs de acceso (si tunnel activo):"
  for p in "${PRODUCTS[@]}"; do
    local_url=$(minikube service "wso2-$p" -n "$NAMESPACE" --url 2>/dev/null || true)
    if [ -n "$local_url" ]; then
      echo "   $p: $local_url"
    fi
  done
  echo ""
  exit 0
}

show_logs() {
  local product="$1"
  echo ">> Logs de wso2-$product:"
  kubectl logs -f deployment/wso2-"$product" -n "$NAMESPACE" --tail=100
  exit 0
}

open_tunnel() {
  echo "============================================="
  echo " Acceso a Servicios WSO2 — Port Forward"
  echo "============================================="
  echo ""

  local pids=()

  for p in "${PRODUCTS[@]}"; do
    replicas=$(kubectl get deployment "wso2-$p" -n "$NAMESPACE" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
    if [ "$replicas" = "0" ] || [ -z "$replicas" ]; then
      continue
    fi

    case "$p" in
      api-manager)
        echo "   🔗 API Manager:          https://localhost:9443/carbon"
        echo "                             https://localhost:8243 (Gateway HTTPS)"
        echo "                             http://localhost:8280  (Gateway HTTP)"
        kubectl port-forward svc/wso2-api-manager -n "$NAMESPACE" 9443:9443 8243:8243 8280:8280 &>/dev/null &
        ;;
      micro-integrator)
        echo "   🔗 Micro Integrator:     http://localhost:8290  (HTTP passthrough)"
        echo "                             https://localhost:8253 (HTTPS passthrough)"
        kubectl port-forward svc/wso2-micro-integrator -n "$NAMESPACE" 8290:8290 8253:8253 &>/dev/null &
        ;;
      identity-server)
        echo "   🔗 Identity Server:      https://localhost:9444/console"
        kubectl port-forward svc/wso2-identity-server -n "$NAMESPACE" 9444:9443 &>/dev/null &
        ;;
      streaming-integrator)
        echo "   🔗 Streaming Integrator: https://localhost:9445/carbon"
        echo "                             http://localhost:9090  (Siddhi API)"
        kubectl port-forward svc/wso2-streaming-integrator -n "$NAMESPACE" 9445:9443 9090:9090 &>/dev/null &
        ;;
    esac
    pids+=($!)
  done

  if [ ${#pids[@]} -eq 0 ]; then
    echo "   ⚠️  No hay productos desplegados con réplicas > 0"
    exit 1
  fi

  echo ""
  echo "✅ Port-forwards activos. Presiona Ctrl+C para cerrar."

  trap 'kill "${pids[@]}" 2>/dev/null; exit 0' INT TERM
  wait
}

# Parse argumentos
SHOW_STATUS=false
SHOW_LOGS=""
OPEN_TUNNEL=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --product) PRODUCT="$2"; shift 2 ;;
    --build) BUILD=true; shift ;;
    --clean) CLEAN=true; shift ;;
    --status) SHOW_STATUS=true; shift ;;
    --logs) SHOW_LOGS="$2"; shift 2 ;;
    --tunnel) OPEN_TUNNEL=true; shift ;;
    -h|--help) usage ;;
    *) echo "Opción desconocida: $1"; usage ;;
  esac
done

# Verificar que Minikube está corriendo
if ! minikube status &>/dev/null; then
  echo "❌ Minikube no está corriendo."
  echo "   Ejecuta: minikube start --memory=8192 --cpus=4"
  exit 1
fi

# Acciones rápidas
$SHOW_STATUS && show_status
[ -n "$SHOW_LOGS" ] && show_logs "$SHOW_LOGS"
$OPEN_TUNNEL && open_tunnel

# Limpiar
if $CLEAN; then
  echo "============================================="
  echo " Limpiando namespace $NAMESPACE"
  echo "============================================="
  kubectl delete namespace "$NAMESPACE" --ignore-not-found
  echo "✅ Namespace $NAMESPACE eliminado."
  exit 0
fi

echo "============================================="
echo " WSO2 Demo — Despliegue Local en Minikube"
echo "============================================="
echo ""
echo "📋 Cluster: minikube"
echo "📋 Namespace: $NAMESPACE"
echo ""

# Configurar Docker para usar el daemon de Minikube
if $BUILD; then
  echo ">> Configurando Docker para usar Minikube..."
  eval $(minikube docker-env --shell bash 2>/dev/null || minikube docker-env)
  echo "✅ Docker apuntando a Minikube"
  echo ""

  # Construir imágenes
  echo ">> Construyendo imágenes Docker..."
  cd "$ROOT_DIR"

  for p in "${PRODUCTS[@]}"; do
    if [ -n "$PRODUCT" ] && [ "$PRODUCT" != "$p" ]; then
      continue
    fi

    echo ""
    echo "   🔨 Construyendo wso2-$p..."
    docker build \
      -f "infrastructure/docker/$p/Dockerfile" \
      -t "wso2-$p:dev-latest" \
      --build-arg ENVIRONMENT=dev \
      . 2>&1 | tail -3

    # Etiquetar con el nombre que Kustomize genera (ghcr.io/ticxar/...)
    docker tag "wso2-$p:dev-latest" "ghcr.io/ticxar/wso2-$p:dev-latest"
    echo "   ✅ wso2-$p:dev-latest construida (+ tag ghcr.io/ticxar/)"
  done
  echo ""
fi

# Crear namespace si no existe
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Aplicar manifiestos con Kustomize
OVERLAY_DIR="$ROOT_DIR/infrastructure/kubernetes/overlays/dev"

echo ">> Validando manifiestos..."
kubectl kustomize "$OVERLAY_DIR" > /dev/null
echo "✅ Manifiestos válidos."
echo ""

# Para Minikube, inyectar imagePullPolicy: Never (usamos imágenes locales)
echo ">> Aplicando manifiestos..."
if $BUILD; then
  # Generar manifiestos, inyectar imagePullPolicy: Never después de cada línea image: y aplicar
  kubectl kustomize "$OVERLAY_DIR" | \
    sed 's/^\([[:space:]]*\)image: .*/&\n\1imagePullPolicy: Never/' | \
    kubectl apply -f -
else
  kubectl apply -k "$OVERLAY_DIR"
fi

# Si se especificó --product, escalar a 0 los demás deployments para liberar recursos
if [ -n "$PRODUCT" ]; then
  for p in "${PRODUCTS[@]}"; do
    if [ "$p" != "$PRODUCT" ]; then
      kubectl scale deployment "wso2-$p" -n "$NAMESPACE" --replicas=0 2>/dev/null || true
    fi
  done
  echo "   📌 Solo se despliega: $PRODUCT (demás escalados a 0)"
fi

echo ""
echo ">> Esperando que los pods estén listos..."

DEPLOY_PRODUCTS=("${PRODUCTS[@]}")
if [ -n "$PRODUCT" ]; then
  DEPLOY_PRODUCTS=("$PRODUCT")
fi

for p in "${DEPLOY_PRODUCTS[@]}"; do
  echo "   ⏳ Esperando wso2-$p..."
  kubectl rollout status deployment/wso2-"$p" -n "$NAMESPACE" --timeout=300s 2>/dev/null || \
    echo "   ⚠️  Timeout para wso2-$p (puede requerir más tiempo de inicio)"
done

echo ""
echo "============================================="
echo " ✅ Despliegue completado en Minikube"
echo "============================================="
echo ""
echo ">> Estado de los pods:"
kubectl get pods -n "$NAMESPACE"
echo ""
echo ">> Servicios disponibles:"
kubectl get svc -n "$NAMESPACE"
echo ""
echo "============================================="
echo " Acceso desde el host (port-forward):"
echo "============================================="
echo ""
for p in "${DEPLOY_PRODUCTS[@]}"; do
  case "$p" in
    api-manager)
      echo "  kubectl port-forward svc/wso2-api-manager -n $NAMESPACE 9443:9443 8243:8243 8280:8280"
      echo "    → https://localhost:9443/carbon     (Publisher / DevPortal / Admin)"
      echo "    → https://localhost:8243             (Gateway HTTPS)"
      echo "    → http://localhost:8280              (Gateway HTTP)"
      ;;
    micro-integrator)
      echo "  kubectl port-forward svc/wso2-micro-integrator -n $NAMESPACE 8290:8290 8253:8253"
      echo "    → http://localhost:8290/services     (HTTP passthrough)"
      echo "    → https://localhost:8253             (HTTPS passthrough)"
      ;;
    identity-server)
      echo "  kubectl port-forward svc/wso2-identity-server -n $NAMESPACE 9444:9443"
      echo "    → https://localhost:9444/console     (IS Console)"
      ;;
    streaming-integrator)
      echo "  kubectl port-forward svc/wso2-streaming-integrator -n $NAMESPACE 9445:9443 9090:9090"
      echo "    → https://localhost:9445/carbon      (SI Console)"
      echo "    → http://localhost:9090              (Siddhi API)"
      ;;
  esac
  echo ""
done
echo "  O abre todos a la vez: ./scripts/minikube-demo.sh --tunnel"
echo ""
echo "============================================="
echo " Próximos pasos:"
echo "============================================="
echo ""
echo "  Ver estado:    ./scripts/minikube-demo.sh --status"
echo "  Ver logs:      ./scripts/minikube-demo.sh --logs micro-integrator"
echo "  Limpiar:       ./scripts/minikube-demo.sh --clean"
echo "  Limpiar:       ./scripts/minikube-demo.sh --clean"
echo ""
echo "  Acceso rápido con port-forward:"
echo "    kubectl port-forward svc/wso2-api-manager -n $NAMESPACE 9443:9443"
echo "    kubectl port-forward svc/wso2-micro-integrator -n $NAMESPACE 8290:8290"
echo ""
