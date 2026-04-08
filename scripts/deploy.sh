#!/usr/bin/env bash
# =============================================================================
# deploy.sh — Despliega productos WSO2 a Kubernetes via Kustomize
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

VALID_ENVS=("dev" "qa" "staging" "prod")

usage() {
  echo "Uso: $0 <environment> [--dry-run] [--product PRODUCT]"
  echo ""
  echo "Ambientes: ${VALID_ENVS[*]}"
  echo ""
  echo "Opciones:"
  echo "  --dry-run          Solo muestra lo que se desplegaría"
  echo "  --product PRODUCT  Despliega solo un producto específico"
  exit 1
}

ENVIRONMENT="${1:-}"
[ -z "$ENVIRONMENT" ] && usage
shift

DRY_RUN=""
PRODUCT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN="--dry-run=client"; shift ;;
    --product) PRODUCT="$2"; shift 2 ;;
    *) echo "Opción desconocida: $1"; usage ;;
  esac
done

# Validar ambiente
VALID=0
for e in "${VALID_ENVS[@]}"; do
  [ "$e" = "$ENVIRONMENT" ] && VALID=1
done
if [ "$VALID" -eq 0 ]; then
  echo "❌ Ambiente inválido: $ENVIRONMENT"
  usage
fi

OVERLAY_DIR="$ROOT_DIR/infrastructure/kubernetes/overlays/$ENVIRONMENT"

if [ ! -d "$OVERLAY_DIR" ]; then
  echo "❌ Overlay no encontrado: $OVERLAY_DIR"
  exit 1
fi

echo "============================================="
echo " WSO2 Deploy — Ambiente: $ENVIRONMENT"
echo "============================================="

# Confirmación para staging/prod
if [[ "$ENVIRONMENT" =~ ^(staging|prod)$ ]] && [ -z "$DRY_RUN" ]; then
  echo ""
  echo "⚠️  Estás a punto de desplegar en $ENVIRONMENT."
  read -p "¿Continuar? (y/N): " CONFIRM
  if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "Abortado."
    exit 0
  fi
fi

# Validar manifiestos
echo ""
echo ">> Validando manifiestos con kustomize..."
kubectl kustomize "$OVERLAY_DIR" > /dev/null
echo "✅ Manifiestos válidos."

# Aplicar
echo ""
echo ">> Aplicando manifiestos..."
if [ -n "$DRY_RUN" ]; then
  echo "   (modo dry-run)"
fi

kubectl apply -k "$OVERLAY_DIR" $DRY_RUN

echo ""
echo ">> Esperando rollout..."
NAMESPACE="wso2-$ENVIRONMENT"
PRODUCTS=("api-manager" "micro-integrator" "identity-server" "streaming-integrator")

for p in "${PRODUCTS[@]}"; do
  if [ -n "$PRODUCT" ] && [ "$PRODUCT" != "$p" ]; then
    continue
  fi
  echo "   Esperando wso2-$p..."
  kubectl rollout status deployment/wso2-$p -n "$NAMESPACE" --timeout=300s $DRY_RUN 2>/dev/null || \
    echo "   ⚠️  Timeout o deployment no encontrado para wso2-$p"
done

echo ""
echo "============================================="
echo " ✅ Deploy completado en $ENVIRONMENT"
echo "============================================="

# Smoke test automático para dev
if [ "$ENVIRONMENT" = "dev" ] && [ -z "$DRY_RUN" ]; then
  echo ""
  echo ">> Ejecutando smoke test..."
  "$SCRIPT_DIR/smoke-test.sh" "$ENVIRONMENT" || echo "⚠️  Smoke test con errores."
fi
