#!/usr/bin/env bash
# =============================================================================
# smoke-test.sh — Smoke tests post-despliegue para productos WSO2
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

ENVIRONMENT="${1:-dev}"
NAMESPACE="wso2-$ENVIRONMENT"

# Dominio base según ambiente
case "$ENVIRONMENT" in
  dev)     DOMAIN="dev.wso2.ticxar.com" ;;
  qa)      DOMAIN="qa.wso2.ticxar.com" ;;
  staging) DOMAIN="staging.wso2.ticxar.com" ;;
  prod)    DOMAIN="wso2.ticxar.com" ;;
  *) echo "❌ Ambiente inválido: $ENVIRONMENT"; exit 1 ;;
esac

echo "============================================="
echo " Smoke Test — Ambiente: $ENVIRONMENT"
echo "============================================="

FAILURES=0
TOTAL=0

smoke_check() {
  local name="$1"
  local url="$2"
  local expected_code="${3:-200}"
  TOTAL=$((TOTAL+1))

  echo -n "  [$name] $url ... "
  HTTP_CODE=$(curl -sk -o /dev/null -w "%{http_code}" --connect-timeout 10 --max-time 30 "$url" 2>/dev/null || echo "000")

  if [ "$HTTP_CODE" = "$expected_code" ]; then
    echo "✅ ($HTTP_CODE)"
  else
    echo "❌ (esperado $expected_code, recibido $HTTP_CODE)"
    FAILURES=$((FAILURES+1))
  fi
}

# --- API Manager ---
echo ""
echo ">> API Manager"
smoke_check "APIM Carbon"    "https://apim.$DOMAIN:9443/carbon/admin/login.jsp" "200"
smoke_check "APIM Publisher" "https://apim.$DOMAIN:9443/publisher/"             "200"
smoke_check "APIM DevPortal" "https://apim.$DOMAIN:9443/devportal/"             "200"
smoke_check "APIM Gateway"   "https://apim.$DOMAIN:8243/services/Version"       "200"

# --- Micro Integrator ---
echo ""
echo ">> Micro Integrator"
smoke_check "MI Management"  "https://mi.$DOMAIN:9164/management/apis"          "200"
smoke_check "MI Health"      "http://mi.$DOMAIN:9201/healthz"                   "200"

# --- Identity Server ---
echo ""
echo ">> Identity Server"
smoke_check "IS Carbon"      "https://is.$DOMAIN:9443/carbon/admin/login.jsp"   "200"
smoke_check "IS OAuth"       "https://is.$DOMAIN:9443/.well-known/openid-configuration" "200"

# --- Streaming Integrator ---
echo ""
echo ">> Streaming Integrator"
smoke_check "SI Health"      "https://si.$DOMAIN:9443/health"                   "200"

# --- Kubernetes pods check ---
echo ""
echo ">> Kubernetes Pods en namespace $NAMESPACE"
PODS_NOT_READY=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | grep -v "Running\|Completed" || true)
if [ -n "$PODS_NOT_READY" ]; then
  echo "  ❌ Pods no saludables:"
  echo "$PODS_NOT_READY" | sed 's/^/     /'
  FAILURES=$((FAILURES+1))
else
  READY_COUNT=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l)
  echo "  ✅ $READY_COUNT pods running."
fi

# --- Resultado ---
echo ""
echo "============================================="
if [ "$FAILURES" -gt 0 ]; then
  echo " ❌ $FAILURES/$TOTAL checks fallaron"
  exit 1
else
  echo " ✅ $TOTAL/$TOTAL checks passed"
fi
echo "============================================="
