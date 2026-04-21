#!/bin/bash
###############################################################################
# create-userstores-prod.sh
# Crea user stores AD desde cero en WSO2 IS - AXA Producción
# y configura claim mappings + verificación SCIM2
#
# User Stores creados:
#   1. TSTF-AXACOLPATRIA  (UniqueIDActiveDirectoryUserStoreManager)
#   2. tstf.axacolpatria.co (UniqueIDReadOnlyLDAPUserStoreManager)
#
# Requiere: curl, jq
###############################################################################
set -euo pipefail

###############################################################################
# CONFIGURACIÓN — Ajustar según el entorno
###############################################################################
BASE_URL="https://dc2tvasam01.uinversion.colpatria.com:9453"
API="${BASE_URL}/api/server/v1/userstores"
CLAIMS_API="${BASE_URL}/api/server/v1/claim-dialects/local/claims"
SCIM2_API="${BASE_URL}/scim2"
CURL="curl -sk --connect-timeout 10 --max-time 30"

# --- Conexión LDAP (Active Directory) ---
LDAP_URL="ldap://10.65.220.169:389"
LDAP_BIND_DN="CN=WSO2 ServiceAccount,OU=Service_accounts,DC=tstf,DC=axacolpatria,DC=co"
LDAP_BASE_DN="DC=tstf,DC=axacolpatria,DC=co"
LDAP_GROUP_BASE="OU=Grupos,DC=tstf,DC=axacolpatria,DC=co"

# --- Nombres de dominio de los user stores ---
STORE1_NAME="TSTF-AXACOLPATRIA"
STORE2_NAME="tstf.axacolpatria.co"

# --- Type IDs (base64 de la clase Java) ---
TYPE_AD="VW5pcXVlSURBY3RpdmVEaXJlY3RvcnlVc2VyU3RvcmVNYW5hZ2Vy"
TYPE_LDAP_RO="VW5pcXVlSURSZWFkT25seUxEQVBVc2VyU3RvcmVNYW5hZ2Vy"

###############################################################################
echo "============================================================"
echo " WSO2 IS - Crear User Stores desde cero"
echo " AXA Producción: ${BASE_URL}"
echo "============================================================"
echo ""

# --- Credenciales WSO2 IS ---
read -p "Usuario admin WSO2 IS [admin]: " ADMIN_USER
ADMIN_USER="${ADMIN_USER:-admin}"
read -sp "Password WSO2 IS: " ADMIN_PASS
echo ""
AUTH=$(printf '%s:%s' "${ADMIN_USER}" "${ADMIN_PASS}" | base64)
AUTH_HEADER="Authorization: Basic ${AUTH}"

# --- Password LDAP (cuenta de servicio) ---
read -sp "Password cuenta de servicio LDAP (${LDAP_BIND_DN}): " LDAP_PASS
echo ""

###############################################################################
# PASO 0 — Verificar conectividad
###############################################################################
echo ""
echo "[0/6] Verificando conectividad con WSO2 IS..."
HTTP_CODE=$($CURL -o /dev/null -w "%{http_code}" \
  "${API}" -H "${AUTH_HEADER}" -H "Accept: application/json")
if [ "${HTTP_CODE}" != "200" ]; then
  echo "  ✗ ERROR: No se pudo conectar (HTTP ${HTTP_CODE}). Verifica URL y credenciales."
  exit 1
fi
echo "  ✓ Conexión OK (HTTP ${HTTP_CODE})"

# --- Mostrar user stores existentes ---
echo ""
echo "  User stores actuales:"
EXISTING=$($CURL "${API}" -H "${AUTH_HEADER}" -H "Accept: application/json")
echo "${EXISTING}" | jq -r '.[] | "    - \(.name) [\(.typeName)] (id: \(.id))"' 2>/dev/null || echo "    (ninguno)"

# --- Verificar si ya existen ---
HAS_STORE1=$(echo "${EXISTING}" | jq -r ".[] | select(.name==\"${STORE1_NAME}\") | .id" 2>/dev/null || true)
HAS_STORE2=$(echo "${EXISTING}" | jq -r ".[] | select(.name==\"${STORE2_NAME}\") | .id" 2>/dev/null || true)

if [ -n "${HAS_STORE1}" ] || [ -n "${HAS_STORE2}" ]; then
  echo ""
  echo "  ⚠  Ya existen user stores con estos nombres:"
  [ -n "${HAS_STORE1}" ] && echo "     - ${STORE1_NAME} (id: ${HAS_STORE1})"
  [ -n "${HAS_STORE2}" ] && echo "     - ${STORE2_NAME} (id: ${HAS_STORE2})"
  echo ""
  read -p "  ¿Eliminar los existentes y recrear? (si/no): " DELETE_CONFIRM
  if [ "${DELETE_CONFIRM}" != "si" ]; then
    echo "  Cancelado."
    exit 0
  fi

  if [ -n "${HAS_STORE1}" ]; then
    echo "  Eliminando ${STORE1_NAME}..."
    $CURL -X DELETE "${API}/${HAS_STORE1}" -H "${AUTH_HEADER}" -o /dev/null -w "    HTTP %{http_code}\n"
  fi
  if [ -n "${HAS_STORE2}" ]; then
    echo "  Eliminando ${STORE2_NAME}..."
    $CURL -X DELETE "${API}/${HAS_STORE2}" -H "${AUTH_HEADER}" -o /dev/null -w "    HTTP %{http_code}\n"
  fi
  echo "  ✓ User stores eliminados"
  sleep 3
fi

###############################################################################
# PASO 1 — Crear TSTF-AXACOLPATRIA (ActiveDirectory)
###############################################################################
echo ""
echo "[1/6] Creando user store ${STORE1_NAME} (ActiveDirectory)..."

PAYLOAD_STORE1=$(cat <<EOJSON
{
  "typeId": "${TYPE_AD}",
  "name": "${STORE1_NAME}",
  "description": "Funcionarios AXA - Active Directory",
  "properties": [
    {"name":"ConnectionURL","value":"${LDAP_URL}"},
    {"name":"ConnectionName","value":"${LDAP_BIND_DN}"},
    {"name":"ConnectionPassword","value":"${LDAP_PASS}"},
    {"name":"UserSearchBase","value":"${LDAP_BASE_DN}"},
    {"name":"UserEntryObjectClass","value":"person"},
    {"name":"UserNameAttribute","value":"sAMAccountName"},
    {"name":"UserNameSearchFilter","value":"(&(objectClass=person)(sAMAccountName=?))"},
    {"name":"UserNameListFilter","value":"(objectClass=person)"},
    {"name":"UserIDAttribute","value":"objectGuid"},
    {"name":"UserIdSearchFilter","value":"(&(objectClass=person)(objectGuid=?))"},
    {"name":"DisplayNameAttribute","value":"sAMAccountName"},
    {"name":"ReadGroups","value":"true"},
    {"name":"WriteGroups","value":"false"},
    {"name":"GroupSearchBase","value":"${LDAP_GROUP_BASE}"},
    {"name":"GroupEntryObjectClass","value":"group"},
    {"name":"GroupNameAttribute","value":"cn"},
    {"name":"GroupNameSearchFilter","value":"(&(objectClass=group)(cn=?))"},
    {"name":"GroupNameListFilter","value":"(objectClass=group)"},
    {"name":"GroupIdAttribute","value":"cn"},
    {"name":"MembershipAttribute","value":"member"},
    {"name":"MemberOfAttribute","value":"memberOf"},
    {"name":"BackLinksEnabled","value":"true"},
    {"name":"Referral","value":"ignore"},
    {"name":"ReadOnly","value":"true"},
    {"name":"Disabled","value":"false"},
    {"name":"MaxUserNameListLength","value":"100"},
    {"name":"MaxRoleNameListLength","value":"100"},
    {"name":"UserRolesCacheEnabled","value":"true"},
    {"name":"ConnectionPoolingEnabled","value":"false"},
    {"name":"LDAPConnectionTimeout","value":"10000"},
    {"name":"ReadTimeout","value":"10000"},
    {"name":"StartTLSEnabled","value":"false"},
    {"name":"EmptyRolesAllowed","value":"true"},
    {"name":"MultiAttributeSeparator","value":","},
    {"name":"PasswordHashMethod","value":"PLAIN_TEXT"},
    {"name":"DomainName","value":"${STORE1_NAME}"},
    {"name":"transformObjectGUIDToUUID","value":"true"},
    {"name":"java.naming.ldap.attributes.binary","value":"objectGuid objectSid"},
    {"name":"TimestampAttributes","value":"whenChanged,whenCreated"},
    {"name":"ImmutableAttributes","value":"objectGuid,whenCreated,whenChanged"},
    {"name":"DateAndTimePattern","value":"uuuuMMddHHmmss.SX"}
  ],
  "claimAttributeMappings": [
    {"claimURI":"http://wso2.org/claims/userid","mappedAttribute":"objectGuid"},
    {"claimURI":"http://wso2.org/claims/username","mappedAttribute":"sAMAccountName"},
    {"claimURI":"http://wso2.org/claims/givenname","mappedAttribute":"givenName"},
    {"claimURI":"http://wso2.org/claims/lastname","mappedAttribute":"sn"},
    {"claimURI":"http://wso2.org/claims/emailaddress","mappedAttribute":"mail"},
    {"claimURI":"http://wso2.org/claims/groups","mappedAttribute":"memberOf"},
    {"claimURI":"http://wso2.org/claims/created","mappedAttribute":"whenCreated"},
    {"claimURI":"http://wso2.org/claims/modified","mappedAttribute":"whenChanged"}
  ]
}
EOJSON
)

HTTP_CODE=$($CURL -o /tmp/resp_store1.json -w "%{http_code}" \
  -X POST "${API}" \
  -H "${AUTH_HEADER}" \
  -H "Content-Type: application/json" \
  -d "${PAYLOAD_STORE1}")

if [ "${HTTP_CODE}" = "201" ]; then
  echo "  ✓ ${STORE1_NAME} creado (HTTP ${HTTP_CODE})"
else
  echo "  ✗ Error creando ${STORE1_NAME} (HTTP ${HTTP_CODE}):"
  jq . /tmp/resp_store1.json 2>/dev/null || cat /tmp/resp_store1.json
  echo ""
  echo "  Abortando. Revisa la configuración."
  exit 1
fi

###############################################################################
# PASO 2 — Crear tstf.axacolpatria.co (ReadOnly LDAP)
###############################################################################
echo ""
echo "[2/6] Creando user store ${STORE2_NAME} (ReadOnly LDAP)..."

PAYLOAD_STORE2=$(cat <<EOJSON
{
  "typeId": "${TYPE_LDAP_RO}",
  "name": "${STORE2_NAME}",
  "description": "Funcionarios AXA - LDAP Read-Only",
  "properties": [
    {"name":"ConnectionURL","value":"${LDAP_URL}"},
    {"name":"ConnectionName","value":"${LDAP_BIND_DN}"},
    {"name":"ConnectionPassword","value":"${LDAP_PASS}"},
    {"name":"UserSearchBase","value":"${LDAP_BASE_DN}"},
    {"name":"UserEntryObjectClass","value":"person"},
    {"name":"UserNameAttribute","value":"sAMAccountName"},
    {"name":"UserNameSearchFilter","value":"(&(objectClass=person)(sAMAccountName=?))"},
    {"name":"UserNameListFilter","value":"(objectClass=person)"},
    {"name":"UserIDAttribute","value":"objectSid"},
    {"name":"UserIdSearchFilter","value":"(&(objectClass=person)(sAMAccountName=?))"},
    {"name":"DisplayNameAttribute","value":"sAMAccountName"},
    {"name":"ReadGroups","value":"true"},
    {"name":"GroupSearchBase","value":"${LDAP_GROUP_BASE}"},
    {"name":"GroupEntryObjectClass","value":"group"},
    {"name":"GroupNameAttribute","value":"cn"},
    {"name":"GroupNameSearchFilter","value":"(&(objectClass=group)(cn=?))"},
    {"name":"GroupNameListFilter","value":"(objectClass=group)"},
    {"name":"GroupIdAttribute","value":"cn"},
    {"name":"MembershipAttribute","value":"member"},
    {"name":"MemberOfAttribute","value":"memberOf"},
    {"name":"BackLinksEnabled","value":"false"},
    {"name":"Referral","value":"ignore"},
    {"name":"ReadOnly","value":"true"},
    {"name":"Disabled","value":"false"},
    {"name":"MaxUserNameListLength","value":"100"},
    {"name":"MaxRoleNameListLength","value":"100"},
    {"name":"UserRolesCacheEnabled","value":"true"},
    {"name":"ConnectionPoolingEnabled","value":"false"},
    {"name":"LDAPConnectionTimeout","value":"10000"},
    {"name":"ReadTimeout","value":"10000"},
    {"name":"StartTLSEnabled","value":"false"},
    {"name":"EmptyRolesAllowed","value":"true"},
    {"name":"MultiAttributeSeparator","value":","},
    {"name":"PasswordHashMethod","value":"PLAIN_TEXT"},
    {"name":"DomainName","value":"${STORE2_NAME}"},
    {"name":"LDAPBinaryAttributes","value":"objectGUID"},
    {"name":"DateAndTimePattern","value":"uuuuMMddHHmmss.SX"},
    {"name":"GroupCreatedDateAttribute","value":"whenCreated"},
    {"name":"GroupLastModifiedDateAttribute","value":"whenChanged"}
  ],
  "claimAttributeMappings": [
    {"claimURI":"http://wso2.org/claims/userid","mappedAttribute":"sAMAccountName"},
    {"claimURI":"http://wso2.org/claims/username","mappedAttribute":"sAMAccountName"},
    {"claimURI":"http://wso2.org/claims/givenname","mappedAttribute":"givenName"},
    {"claimURI":"http://wso2.org/claims/lastname","mappedAttribute":"sn"},
    {"claimURI":"http://wso2.org/claims/emailaddress","mappedAttribute":"mail"},
    {"claimURI":"http://wso2.org/claims/groups","mappedAttribute":"memberOf"}
  ]
}
EOJSON
)

HTTP_CODE=$($CURL -o /tmp/resp_store2.json -w "%{http_code}" \
  -X POST "${API}" \
  -H "${AUTH_HEADER}" \
  -H "Content-Type: application/json" \
  -d "${PAYLOAD_STORE2}")

if [ "${HTTP_CODE}" = "201" ]; then
  echo "  ✓ ${STORE2_NAME} creado (HTTP ${HTTP_CODE})"
else
  echo "  ✗ Error creando ${STORE2_NAME} (HTTP ${HTTP_CODE}):"
  jq . /tmp/resp_store2.json 2>/dev/null || cat /tmp/resp_store2.json
  echo ""
  echo "  ⚠  ${STORE1_NAME} ya fue creado. Puedes eliminarlo manualmente si necesitas reiniciar."
  exit 1
fi

echo ""
echo "  Esperando 5s a que WSO2 IS registre los stores..."
sleep 5

###############################################################################
# PASO 3 — Configurar Claim Mappings (ambos stores)
###############################################################################
echo ""
echo "[3/6] Configurando claim mappings para ambos user stores..."

apply_claim() {
  local CLAIM_URI_B64="$1"
  local CLAIM_URI="$2"
  local DESCRIPTION="$3"
  local DISPLAY_NAME="$4"
  local DISPLAY_ORDER="$5"
  local READ_ONLY="$6"
  local REQUIRED="$7"
  local SUPPORTED="$8"
  local PRIMARY_ATTR="$9"
  local STORE1_ATTR="${10}"
  local STORE2_ATTR="${11}"
  local IS_SYSTEM="${12:-false}"

  local PROPS="[]"
  if [ "${IS_SYSTEM}" = "true" ]; then
    PROPS='[{"key":"isSystemClaim","value":"true"}]'
  fi

  # Construir attributeMapping dinámicamente
  local MAPPINGS="[{\"mappedAttribute\":\"${PRIMARY_ATTR}\",\"userstore\":\"PRIMARY\"}"
  if [ -n "${STORE1_ATTR}" ]; then
    MAPPINGS="${MAPPINGS},{\"mappedAttribute\":\"${STORE1_ATTR}\",\"userstore\":\"${STORE1_NAME}\"}"
  fi
  if [ -n "${STORE2_ATTR}" ]; then
    MAPPINGS="${MAPPINGS},{\"mappedAttribute\":\"${STORE2_ATTR}\",\"userstore\":\"${STORE2_NAME}\"}"
  fi
  MAPPINGS="${MAPPINGS}]"

  local PAYLOAD
  PAYLOAD=$(jq -n \
    --arg uri "${CLAIM_URI}" \
    --arg desc "${DESCRIPTION}" \
    --arg dn "${DISPLAY_NAME}" \
    --argjson order "${DISPLAY_ORDER}" \
    --argjson ro "${READ_ONLY}" \
    --argjson req "${REQUIRED}" \
    --argjson sup "${SUPPORTED}" \
    --argjson mappings "${MAPPINGS}" \
    --argjson props "${PROPS}" \
    '{
      claimURI: $uri,
      description: $desc,
      displayOrder: $order,
      displayName: $dn,
      readOnly: $ro,
      required: $req,
      supportedByDefault: $sup,
      attributeMapping: $mappings,
      properties: $props
    }')

  local HC
  HC=$($CURL -o /tmp/resp_claim.json -w "%{http_code}" \
    -X PUT "${CLAIMS_API}/${CLAIM_URI_B64}" \
    -H "${AUTH_HEADER}" \
    -H "Content-Type: application/json" \
    -d "${PAYLOAD}")

  if [ "${HC}" = "200" ]; then
    printf "  ✓ %-35s → %s / %s\n" "${DISPLAY_NAME} (${CLAIM_URI})" "${STORE1_ATTR:-n/a}" "${STORE2_ATTR:-n/a}"
  else
    printf "  ✗ %-35s → HTTP %s\n" "${DISPLAY_NAME}" "${HC}"
    jq -r '.description // .message // empty' /tmp/resp_claim.json 2>/dev/null
  fi
}

# Claim URI (base64url)                  | claim URI                              | desc               | display    | order | RO    | req   | supp  | PRIMARY         | STORE1 (AD)  | STORE2 (LDAP-RO) | system
apply_claim "aHR0cDovL3dzbzIub3JnL2NsYWltcy91c2VyaWQ"       "http://wso2.org/claims/userid"       "Unique ID"          "User ID"         0 true  false false "scimId"          "objectGuid"     "sAMAccountName"  "true"
apply_claim "aHR0cDovL3dzbzIub3JnL2NsYWltcy91c2VybmFtZQ"    "http://wso2.org/claims/username"     "Username"           "Username"        0 true  true  true  "uid"             "sAMAccountName" "sAMAccountName"  ""
apply_claim "aHR0cDovL3dzbzIub3JnL2NsYWltcy9naXZlbm5hbWU"   "http://wso2.org/claims/givenname"    "First Name"         "First Name"      1 true  false true  "givenName"       "givenName"      "givenName"       ""
apply_claim "aHR0cDovL3dzbzIub3JnL2NsYWltcy9sYXN0bmFtZQ"    "http://wso2.org/claims/lastname"     "Last Name"          "Last Name"       2 true  false true  "sn"              "sn"             "sn"              ""
apply_claim "aHR0cDovL3dzbzIub3JnL2NsYWltcy9lbWFpbGFkZHJlc3M" "http://wso2.org/claims/emailaddress" "Email Address"    "Email"           5 true  false true  "mail"            "mail"           "mail"            ""
apply_claim "aHR0cDovL3dzbzIub3JnL2NsYWltcy9ncm91cHM"       "http://wso2.org/claims/groups"       "Groups"             "Groups"          0 true  false false "groups"          "memberOf"       "memberOf"        ""
apply_claim "aHR0cDovL3dzbzIub3JnL2NsYWltcy9jcmVhdGVk"      "http://wso2.org/claims/created"      "Created Time"       "Created"         0 true  false false "createdDate"     "whenCreated"    ""                ""
apply_claim "aHR0cDovL3dzbzIub3JnL2NsYWltcy9tb2RpZmllZA"    "http://wso2.org/claims/modified"     "Last Modified Time" "Last Modified"   0 true  false false "lastModifiedDate" "whenChanged"   ""                ""

###############################################################################
# PASO 4 — Verificar User Stores creados
###############################################################################
echo ""
echo "[4/6] Verificando user stores creados..."
$CURL "${API}" -H "${AUTH_HEADER}" -H "Accept: application/json" | \
  jq -r '.[] | "  [\(.typeName)] \(.name) — \(.description) (id: \(.id))"'

###############################################################################
# PASO 5 — Verificar Claims (leer config actual de cada claim)
###############################################################################
echo ""
echo "[5/6] Verificando claim mappings configurados..."

CLAIM_IDS=(
  "aHR0cDovL3dzbzIub3JnL2NsYWltcy91c2VyaWQ"
  "aHR0cDovL3dzbzIub3JnL2NsYWltcy91c2VybmFtZQ"
  "aHR0cDovL3dzbzIub3JnL2NsYWltcy9naXZlbm5hbWU"
  "aHR0cDovL3dzbzIub3JnL2NsYWltcy9sYXN0bmFtZQ"
  "aHR0cDovL3dzbzIub3JnL2NsYWltcy9lbWFpbGFkZHJlc3M"
  "aHR0cDovL3dzbzIub3JnL2NsYWltcy9ncm91cHM"
  "aHR0cDovL3dzbzIub3JnL2NsYWltcy9jcmVhdGVk"
  "aHR0cDovL3dzbzIub3JnL2NsYWltcy9tb2RpZmllZA"
)

echo ""
printf "  %-35s %-15s %-20s %-20s\n" "CLAIM" "PRIMARY" "${STORE1_NAME}" "${STORE2_NAME}"
printf "  %-35s %-15s %-20s %-20s\n" "-----------------------------------" "---------------" "--------------------" "--------------------"

for CID in "${CLAIM_IDS[@]}"; do
  CLAIM_DATA=$($CURL "${CLAIMS_API}/${CID}" -H "${AUTH_HEADER}" -H "Accept: application/json" 2>/dev/null)

  CLAIM_NAME=$(echo "${CLAIM_DATA}" | jq -r '.displayName // "?"')
  PRIMARY_ATTR=$(echo "${CLAIM_DATA}" | jq -r '[.attributeMapping[]? | select(.userstore=="PRIMARY") | .mappedAttribute] | first // "-"')
  S1_ATTR=$(echo "${CLAIM_DATA}" | jq -r --arg s "${STORE1_NAME}" '[.attributeMapping[]? | select(.userstore==$s) | .mappedAttribute] | first // "-"')
  S2_ATTR=$(echo "${CLAIM_DATA}" | jq -r --arg s "${STORE2_NAME}" '[.attributeMapping[]? | select(.userstore==$s) | .mappedAttribute] | first // "-"')

  printf "  %-35s %-15s %-20s %-20s\n" "${CLAIM_NAME}" "${PRIMARY_ATTR}" "${S1_ATTR}" "${S2_ATTR}"
done

###############################################################################
# PASO 6 — Verificar SCIM2 (Grupos y Usuarios)
###############################################################################
echo ""
echo "[6/6] Verificando SCIM2..."

echo ""
echo "  --- Grupos ${STORE1_NAME} ---"
GROUPS1=$($CURL "${SCIM2_API}/Groups?domain=${STORE1_NAME}" \
  -H "${AUTH_HEADER}" -H "Accept: application/json" 2>/dev/null)
TOTAL1=$(echo "${GROUPS1}" | jq -r '.totalResults // 0')
echo "  Total: ${TOTAL1}"
echo "${GROUPS1}" | jq -r '.Resources[]? | "    - \(.displayName) [\(.members // [] | length) miembros]"' 2>/dev/null

echo ""
echo "  --- Grupos ${STORE2_NAME} ---"
GROUPS2=$($CURL "${SCIM2_API}/Groups?domain=${STORE2_NAME}" \
  -H "${AUTH_HEADER}" -H "Accept: application/json" 2>/dev/null)
TOTAL2=$(echo "${GROUPS2}" | jq -r '.totalResults // 0')
echo "  Total: ${TOTAL2}"
echo "${GROUPS2}" | jq -r '.Resources[]? | "    - \(.displayName) [\(.members // [] | length) miembros]"' 2>/dev/null

echo ""
echo "  --- Usuarios ${STORE1_NAME} (primeros 5) ---"
USERS1=$($CURL "${SCIM2_API}/Users?domain=${STORE1_NAME}&count=5" \
  -H "${AUTH_HEADER}" -H "Accept: application/json" 2>/dev/null)
TOTAL_U1=$(echo "${USERS1}" | jq -r '.totalResults // 0')
echo "  Total: ${TOTAL_U1}"
echo "${USERS1}" | jq -r '.Resources[]? | "    - \(.userName) | \(.name.givenName // "-") \(.name.familyName // "-") | \(.emails[0].value // "-")"' 2>/dev/null

echo ""
echo "  --- Usuarios ${STORE2_NAME} (primeros 5) ---"
USERS2=$($CURL "${SCIM2_API}/Users?domain=${STORE2_NAME}&count=5" \
  -H "${AUTH_HEADER}" -H "Accept: application/json" 2>/dev/null)
TOTAL_U2=$(echo "${USERS2}" | jq -r '.totalResults // 0')
echo "  Total: ${TOTAL_U2}"
echo "${USERS2}" | jq -r '.Resources[]? | "    - \(.userName) | \(.name.givenName // "-") \(.name.familyName // "-") | \(.emails[0].value // "-")"' 2>/dev/null

###############################################################################
# RESUMEN
###############################################################################
echo ""
echo "============================================================"
echo " RESUMEN"
echo "============================================================"
echo ""
echo " User Stores:"
echo "   ✓ ${STORE1_NAME}  (ActiveDirectory)      — ${TOTAL1} grupos, ${TOTAL_U1} usuarios"
echo "   ✓ ${STORE2_NAME}  (ReadOnly LDAP)  — ${TOTAL2} grupos, ${TOTAL_U2} usuarios"
echo ""
echo " Claims configurados: 8 (userid, username, givenname,"
echo "   lastname, email, groups, created, modified)"
echo ""
if [ "${TOTAL1}" = "0" ] && [ "${TOTAL2}" = "0" ]; then
  echo " ⚠  No se encontraron grupos. Posibles causas:"
  echo "    - GroupSearchBase incorrecto (verificar OU=Grupos existe en AD)"
  echo "    - Firewall bloqueando ${LDAP_URL}"
  echo "    - Credenciales LDAP incorrectas"
  echo "    - WSO2 IS necesita reinicio para cargar los stores"
  echo ""
  echo " Diagnóstico rápido:"
  echo "   # Test LDAP directo:"
  echo "   ldapsearch -x -H ${LDAP_URL} -D '${LDAP_BIND_DN}' -W \\"
  echo "     -b '${LDAP_GROUP_BASE}' '(objectClass=group)' cn"
fi
echo ""
echo " Para eliminar los stores (rollback):"
echo "   curl -sk -X DELETE '${API}/<store-id>' -H 'Authorization: Basic ...'"
echo "============================================================"
