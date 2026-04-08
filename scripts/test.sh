#!/usr/bin/env bash
# =============================================================================
# test.sh — Ejecuta tests de los proyectos WSO2
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

usage() {
  echo "Uso: $0 [unit|integration|e2e|all] [--product PRODUCT]"
  echo ""
  echo "Tipos de test:"
  echo "  unit         — Tests unitarios"
  echo "  integration  — Tests de integración"
  echo "  e2e          — Tests end-to-end"
  echo "  all          — Todos los tests (default)"
  exit 1
}

TEST_TYPE="${1:-all}"
shift || true
PRODUCT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --product) PRODUCT="$2"; shift 2 ;;
    *) echo "Opción desconocida: $1"; usage ;;
  esac
done

FAILURES=0

run_xml_validation() {
  echo ">> Validando archivos XML (Synapse Config)..."
  local count=0
  while IFS= read -r -d '' file; do
    if command -v xmllint &>/dev/null; then
      xmllint --noout "$file" 2>/dev/null || { echo "  ❌ $file"; FAILURES=$((FAILURES+1)); continue; }
    fi
    count=$((count+1))
  done < <(find "$ROOT_DIR/projects" -name "*.xml" -print0)
  echo "  ✅ $count archivos XML validados."
}

run_ballerina_tests() {
  echo ">> Ejecutando tests de Ballerina..."
  if command -v bal &>/dev/null; then
    cd "$ROOT_DIR/projects/ballerina"
    bal test || FAILURES=$((FAILURES+1))
  else
    echo "  ⚠️  Ballerina CLI no disponible. Saltando."
  fi
}

run_unit_tests() {
  echo ""
  echo "============================================="
  echo " Tests Unitarios"
  echo "============================================="
  run_xml_validation
  run_ballerina_tests

  # Tests con npm si existen
  if [ -f "$ROOT_DIR/tests/unit/package.json" ]; then
    echo ">> Ejecutando tests unitarios Node.js..."
    cd "$ROOT_DIR/tests/unit"
    npm test || FAILURES=$((FAILURES+1))
  fi
}

run_integration_tests() {
  echo ""
  echo "============================================="
  echo " Tests de Integración"
  echo "============================================="
  if [ -f "$ROOT_DIR/tests/integration/package.json" ]; then
    echo ">> Ejecutando tests de integración..."
    cd "$ROOT_DIR/tests/integration"
    npm test || FAILURES=$((FAILURES+1))
  else
    echo "  ⚠️  No hay tests de integración configurados."
  fi
}

run_e2e_tests() {
  echo ""
  echo "============================================="
  echo " Tests End-to-End"
  echo "============================================="
  if [ -f "$ROOT_DIR/tests/e2e/package.json" ]; then
    echo ">> Ejecutando tests E2E..."
    cd "$ROOT_DIR/tests/e2e"
    npm test || FAILURES=$((FAILURES+1))
  else
    echo "  ⚠️  No hay tests E2E configurados."
  fi
}

case "$TEST_TYPE" in
  unit) run_unit_tests ;;
  integration) run_integration_tests ;;
  e2e) run_e2e_tests ;;
  all) run_unit_tests; run_integration_tests; run_e2e_tests ;;
  *) usage ;;
esac

echo ""
if [ "$FAILURES" -gt 0 ]; then
  echo "❌ $FAILURES test(s) fallaron."
  exit 1
else
  echo "✅ Todos los tests pasaron."
fi
