#!/usr/bin/env bash
# =============================================================================
# build.sh — Construye imágenes Docker de productos WSO2
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Cargar .env si existe
if [ -f "$ROOT_DIR/.env" ]; then
  set -a; source "$ROOT_DIR/.env"; set +a
fi

REGISTRY="${DOCKER_REGISTRY:-ghcr.io/ticxar}"
PRODUCTS=("api-manager" "micro-integrator" "identity-server" "streaming-integrator")

usage() {
  echo "Uso: $0 [producto|all] [--tag TAG] [--env ENVIRONMENT]"
  echo ""
  echo "Productos disponibles:"
  for p in "${PRODUCTS[@]}"; do echo "  - $p"; done
  echo "  - ballerina"
  echo "  - all (todos)"
  echo ""
  echo "Opciones:"
  echo "  --tag TAG          Tag de la imagen (default: latest)"
  echo "  --env ENVIRONMENT  Ambiente (dev|qa|staging|prod, default: dev)"
  exit 1
}

PRODUCT="${1:-}"
TAG="latest"
ENVIRONMENT="dev"

shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag) TAG="$2"; shift 2 ;;
    --env) ENVIRONMENT="$2"; shift 2 ;;
    *) echo "Opción desconocida: $1"; usage ;;
  esac
done

[ -z "$PRODUCT" ] && usage

build_product() {
  local product="$1"
  local dockerfile="$ROOT_DIR/infrastructure/docker/$product/Dockerfile"

  if [ ! -f "$dockerfile" ]; then
    echo "❌ Dockerfile no encontrado: $dockerfile"
    return 1
  fi

  local image_name="$REGISTRY/wso2-$product:$TAG"
  echo ""
  echo ">> Construyendo $image_name (env=$ENVIRONMENT)..."
  docker build \
    --build-arg ENVIRONMENT="$ENVIRONMENT" \
    -t "$image_name" \
    -f "$dockerfile" \
    "$ROOT_DIR"

  echo "✅ Imagen construida: $image_name"
}

build_ballerina() {
  echo ""
  echo ">> Construyendo proyecto Ballerina..."
  cd "$ROOT_DIR/projects/ballerina"
  if command -v bal &>/dev/null; then
    bal build
    echo "✅ Ballerina build completado."
  else
    echo "⚠️  Ballerina CLI no encontrado. Saltando."
  fi
}

if [ "$PRODUCT" = "all" ]; then
  for p in "${PRODUCTS[@]}"; do
    build_product "$p"
  done
  build_ballerina
elif [ "$PRODUCT" = "ballerina" ]; then
  build_ballerina
else
  # Validar producto
  VALID=0
  for p in "${PRODUCTS[@]}"; do
    [ "$p" = "$PRODUCT" ] && VALID=1
  done
  if [ "$VALID" -eq 0 ]; then
    echo "❌ Producto inválido: $PRODUCT"
    usage
  fi
  build_product "$PRODUCT"
fi

echo ""
echo "============================================="
echo " ✅ Build completado"
echo "============================================="
