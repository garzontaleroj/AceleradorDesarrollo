#!/usr/bin/env bash
# =============================================================================
# setup.sh — Configura el entorno de desarrollo local
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "============================================="
echo " WSO2 Acelerador — Setup del entorno local"
echo "============================================="

# --- Validar prerequisitos ---------------------------------------------------
check_command() {
  if ! command -v "$1" &>/dev/null; then
    echo "❌ $1 no encontrado. Por favor instálalo antes de continuar."
    return 1
  fi
  echo "✅ $1 encontrado: $(command -v "$1")"
}

echo ""
echo ">> Verificando prerequisitos..."
MISSING=0
check_command "java" || MISSING=1
check_command "docker" || MISSING=1
check_command "docker-compose" || MISSING=1
check_command "kubectl" || MISSING=1
check_command "git" || MISSING=1

# Opcional
check_command "bal" 2>/dev/null && echo "   (Ballerina disponible)" || echo "⚠️  bal (Ballerina) no encontrado — opcional"
check_command "xmllint" 2>/dev/null && echo "   (xmllint disponible)" || echo "⚠️  xmllint no encontrado — opcional para validación XML"

if [ "$MISSING" -eq 1 ]; then
  echo ""
  echo "❌ Faltan dependencias obligatorias. Abortando."
  exit 1
fi

# --- Verificar versión de Java -----------------------------------------------
JAVA_VERSION=$(java -version 2>&1 | head -1 | awk -F '"' '{print $2}' | cut -d . -f 1)
if [ "$JAVA_VERSION" -lt 17 ]; then
  echo "❌ Se requiere Java 17+. Versión actual: $JAVA_VERSION"
  exit 1
fi
echo "✅ Java versión: $JAVA_VERSION"

# --- Crear archivo .env local si no existe ------------------------------------
if [ ! -f "$ROOT_DIR/.env" ]; then
  echo ""
  echo ">> Creando .env a partir de .env.example..."
  cp "$ROOT_DIR/.env.example" "$ROOT_DIR/.env"
  echo "✅ .env creado. Edita los valores según tu entorno local."
else
  echo "✅ .env ya existe."
fi

# --- Crear directorios de trabajo --------------------------------------------
echo ""
echo ">> Creando directorios de trabajo..."
mkdir -p "$ROOT_DIR/tmp"
mkdir -p "$ROOT_DIR/logs"
echo "✅ Directorios tmp/ y logs/ listos."

# --- Git hooks ----------------------------------------------------------------
echo ""
echo ">> Configurando Git hooks..."
HOOKS_DIR="$ROOT_DIR/.git/hooks"
if [ -d "$HOOKS_DIR" ]; then
  cat > "$HOOKS_DIR/pre-commit" << 'HOOK'
#!/usr/bin/env bash
# Pre-commit: validar XML si hay cambios en synapse-config
CHANGED_XML=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.xml$' || true)
if [ -n "$CHANGED_XML" ]; then
  echo ">> Validando archivos XML modificados..."
  for f in $CHANGED_XML; do
    if command -v xmllint &>/dev/null; then
      xmllint --noout "$f" || { echo "❌ XML inválido: $f"; exit 1; }
    fi
  done
  echo "✅ XML válido."
fi
HOOK
  chmod +x "$HOOKS_DIR/pre-commit"
  echo "✅ Pre-commit hook instalado."
else
  echo "⚠️  No se encontró .git/hooks — ejecuta 'git init' primero."
fi

echo ""
echo "============================================="
echo " ✅ Setup completado"
echo "============================================="
echo ""
echo "Próximos pasos:"
echo "  1. Edita .env con tus valores locales"
echo "  2. Ejecuta: ./scripts/build.sh <producto>"
echo "  3. Ejecuta: docker-compose up -d"
