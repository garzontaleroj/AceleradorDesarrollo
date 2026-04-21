#!/bin/bash
###############################################################################
# fix-userstores-prod.sh
# Corrige errores en user stores de WSO2 IS - AXA Producción
#
# User Store 1: TSTF-AXACOLPATRIA
#   - MembershipAttribute: "memberOf" → "member"
#
# User Store 2: tstf.axacolpatria.co
#   - DateAndTimePattern: "Date And Time Pattern" → "uuuuMMddHHmmss.SX"
#   - GroupCreatedDateAttribute: "createTimestamp" → "whenCreated"
#   - GroupLastModifiedDateAttribute: "modifyTimestamp" → "whenChanged"
###############################################################################
set -euo pipefail

BASE_URL="https://dc2tvasam01.uinversion.colpatria.com:9453"
API="${BASE_URL}/api/server/v1/userstores"
BACKUP_DIR="/tmp/wso2is-userstore-backup-$(date +%Y%m%d_%H%M%S)"
CURL="curl -sk --connect-timeout 10 --max-time 30"

# IDs base64url de los domain names
STORE1_ID="VFNURS1BWEFDT0xQQVRSSUE"      # TSTF-AXACOLPATRIA
STORE2_ID="dHN0Zi5heGFjb2xwYXRyaWEuY28"   # tstf.axacolpatria.co

###############################################################################
echo "============================================================"
echo " WSO2 IS - Fix User Stores - AXA Producción"
echo " Target: ${BASE_URL}"
echo "============================================================"

# --- Credenciales ---
read -p "Usuario admin [admin]: " ADMIN_USER
ADMIN_USER="${ADMIN_USER:-admin}"
read -sp "Password: " ADMIN_PASS
echo
AUTH=$(printf '%s:%s' "${ADMIN_USER}" "${ADMIN_PASS}" | base64)
AUTH_HEADER="Authorization: Basic ${AUTH}"

# --- Verificar conectividad ---
echo ""
echo "[0/7] Verificando conectividad..."
HTTP_CODE=$($CURL -o /dev/null -w "%{http_code}" \
  "${API}" -H "${AUTH_HEADER}" -H "Accept: application/json")
if [ "${HTTP_CODE}" != "200" ]; then
  echo "ERROR: No se pudo conectar al API (HTTP ${HTTP_CODE}). Verifica URL y credenciales."
  exit 1
fi
echo "  ✓ Conexión OK (HTTP ${HTTP_CODE})"

# --- Listar user stores ---
echo ""
echo "[1/7] User stores encontrados:"
$CURL "${API}" -H "${AUTH_HEADER}" -H "Accept: application/json" | \
  jq -r '.[] | "  - \(.name) (id: \(.id))"'

# --- Crear directorio de backup ---
mkdir -p "${BACKUP_DIR}"
echo ""
echo "  Backups se guardarán en: ${BACKUP_DIR}"

# --- Backup TSTF-AXACOLPATRIA ---
echo ""
echo "[2/7] Backup TSTF-AXACOLPATRIA..."
$CURL "${API}/${STORE1_ID}" \
  -H "${AUTH_HEADER}" -H "Accept: application/json" \
  | jq . > "${BACKUP_DIR}/TSTF-AXACOLPATRIA.json"
echo "  ✓ ${BACKUP_DIR}/TSTF-AXACOLPATRIA.json"

# --- Backup tstf.axacolpatria.co ---
echo ""
echo "[3/7] Backup tstf.axacolpatria.co..."
$CURL "${API}/${STORE2_ID}" \
  -H "${AUTH_HEADER}" -H "Accept: application/json" \
  | jq . > "${BACKUP_DIR}/tstf.axacolpatria.co.json"
echo "  ✓ ${BACKUP_DIR}/tstf.axacolpatria.co.json"

# --- Mostrar cambios y confirmar ---
echo ""
echo "============================================================"
echo " Cambios a aplicar:"
echo "============================================================"
echo ""
echo " TSTF-AXACOLPATRIA:"
echo "   MembershipAttribute:          memberOf → member"
echo ""
echo " tstf.axacolpatria.co:"
echo "   DateAndTimePattern:            Date And Time Pattern → uuuuMMddHHmmss.SX"
echo "   GroupCreatedDateAttribute:     createTimestamp → whenCreated"
echo "   GroupLastModifiedDateAttribute: modifyTimestamp → whenChanged"
echo ""
read -p "¿Aplicar cambios? (si/no): " CONFIRM
if [ "${CONFIRM}" != "si" ]; then
  echo "Cancelado. Backups disponibles en ${BACKUP_DIR}"
  exit 0
fi

# --- Fix TSTF-AXACOLPATRIA ---
echo ""
echo "[4/7] Corrigiendo TSTF-AXACOLPATRIA (MembershipAttribute → member)..."
jq '(.properties[] | select(.name == "MembershipAttribute")).value = "member"' \
  "${BACKUP_DIR}/TSTF-AXACOLPATRIA.json" > "${BACKUP_DIR}/fix_TSTF-AXACOLPATRIA.json"

HTTP_CODE=$($CURL -o "${BACKUP_DIR}/response1.json" -w "%{http_code}" \
  -X PUT "${API}/${STORE1_ID}" \
  -H "${AUTH_HEADER}" \
  -H "Content-Type: application/json" \
  -d @"${BACKUP_DIR}/fix_TSTF-AXACOLPATRIA.json")

if [ "${HTTP_CODE}" = "200" ]; then
  echo "  ✓ TSTF-AXACOLPATRIA actualizado (HTTP ${HTTP_CODE})"
else
  echo "  ✗ Error HTTP ${HTTP_CODE}:"
  jq . "${BACKUP_DIR}/response1.json"
  echo "  Backup disponible para rollback: ${BACKUP_DIR}/TSTF-AXACOLPATRIA.json"
fi

# --- Fix tstf.axacolpatria.co ---
echo ""
echo "[5/7] Corrigiendo tstf.axacolpatria.co (DateAndTimePattern + GroupDate attrs)..."
jq '
  (.properties[] | select(.name == "DateAndTimePattern")).value = "uuuuMMddHHmmss.SX" |
  (.properties[] | select(.name == "GroupCreatedDateAttribute")).value = "whenCreated" |
  (.properties[] | select(.name == "GroupLastModifiedDateAttribute")).value = "whenChanged"
' "${BACKUP_DIR}/tstf.axacolpatria.co.json" > "${BACKUP_DIR}/fix_tstf.axacolpatria.co.json"

HTTP_CODE=$($CURL -o "${BACKUP_DIR}/response2.json" -w "%{http_code}" \
  -X PUT "${API}/${STORE2_ID}" \
  -H "${AUTH_HEADER}" \
  -H "Content-Type: application/json" \
  -d @"${BACKUP_DIR}/fix_tstf.axacolpatria.co.json")

if [ "${HTTP_CODE}" = "200" ]; then
  echo "  ✓ tstf.axacolpatria.co actualizado (HTTP ${HTTP_CODE})"
else
  echo "  ✗ Error HTTP ${HTTP_CODE}:"
  jq . "${BACKUP_DIR}/response2.json"
  echo "  Backup disponible para rollback: ${BACKUP_DIR}/tstf.axacolpatria.co.json"
fi

# --- Verificar SCIM2 Groups ---
echo ""
echo "[6/7] Verificando SCIM2 Groups - TSTF-AXACOLPATRIA..."
$CURL "${BASE_URL}/scim2/Groups?domain=TSTF-AXACOLPATRIA" \
  -H "${AUTH_HEADER}" -H "Accept: application/json" \
  | jq '{totalResults, groups: [.Resources[]? | {displayName, members: [.members[]?.display]}]}'

echo ""
echo "[7/7] Verificando SCIM2 Groups - tstf.axacolpatria.co..."
$CURL "${BASE_URL}/scim2/Groups?domain=tstf.axacolpatria.co" \
  -H "${AUTH_HEADER}" -H "Accept: application/json" \
  | jq '{totalResults, groups: [.Resources[]? | {displayName, members: [.members[]?.display]}]}'

echo ""
echo "============================================================"
echo " Completado."
echo " Backups en: ${BACKUP_DIR}"
echo ""
echo " Para rollback:"
echo "   curl -sk -X PUT '${API}/${STORE1_ID}' \\"
echo "     -H 'Authorization: Basic ...' \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d @${BACKUP_DIR}/TSTF-AXACOLPATRIA.json"
echo ""
echo "   curl -sk -X PUT '${API}/${STORE2_ID}' \\"
echo "     -H 'Authorization: Basic ...' \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d @${BACKUP_DIR}/tstf.axacolpatria.co.json"
echo "============================================================"
