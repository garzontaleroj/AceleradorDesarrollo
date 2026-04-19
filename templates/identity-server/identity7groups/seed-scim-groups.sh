#!/bin/bash
# =============================================================
# Seed SCIM metadata for LDAP groups in WSO2 IS H2 database
#
# DYNAMIC: Discovers all groups in ou=groups from OpenLDAP
# via ldapsearch, then seeds SCIM metadata for each one.
# Can be re-run after adding/removing groups in LDAP.
#
# WSO2 IS 7.x does NOT auto-provision SCIM metadata for groups
# from external LDAP/AD userstores. Without this metadata in
# IDN_SCIM_GROUP, SCIM2 /Groups returns empty Resources array.
#
# Strategy: H2 2.x embedded mode — stop WSO2 IS, run
# DELETE+INSERT via temp container, then restart.
# =============================================================
set -e

WSO2_URL="https://localhost:9443"
WSO2_USER="admin"
WSO2_PASS="admin"
TENANT_ID="-1234"
DB_VOLUME="identity7groups_wso2is_db"
WSO2_IMAGE="wso2/wso2is:7.2.0"
DB_PATH="/home/wso2carbon/wso2is-7.2.0/repository/database"
H2_JAR="/home/wso2carbon/wso2is-7.2.0/repository/components/plugins/h2-engine_2.2.224.wso2v2.jar"

# OpenLDAP connection
LDAP_CONTAINER="openldap"
LDAP_ADMIN_DN="cn=admin,dc=tsf,dc=axacolpatria,dc=co"
LDAP_ADMIN_PASS="admin"
GROUPS_BASE_DN="ou=groups,dc=tsf,dc=axacolpatria,dc=co"
DOMAIN="LDAPSecondary"
ID_BASE=5001

echo "============================================="
echo " Seeding SCIM metadata for LDAP groups"
echo " (dynamic discovery from OpenLDAP)"
echo "============================================="

# Wait for WSO2 IS to be ready (ensures DB schema exists and groups discovered from LDAP)
echo ""
echo ">> Waiting for WSO2 Identity Server..."
until curl -sk -o /dev/null -w "%{http_code}" "${WSO2_URL}/carbon/admin/login.jsp" | grep -q "200"; do
  sleep 5
done
echo "   WSO2 IS is ready."

# Wait for userstore initialization
echo ">> Waiting for ${DOMAIN} userstore to initialize..."
sleep 15

# Discover groups from OpenLDAP
echo ""
echo ">> Discovering groups in ${GROUPS_BASE_DN}..."
GROUPS=$(docker exec ${LDAP_CONTAINER} ldapsearch -LLL -x -H ldap://localhost:389 \
  -D "${LDAP_ADMIN_DN}" -w "${LDAP_ADMIN_PASS}" \
  -b "${GROUPS_BASE_DN}" -s one "(objectClass=groupOfNames)" cn \
  2>/dev/null | grep "^cn: " | sed 's/^cn: //' | tr -d '\r')

if [ -z "$GROUPS" ]; then
  echo "   ERROR: No groups found in ${GROUPS_BASE_DN}"
  echo "   Verify OpenLDAP is running and groups exist."
  exit 1
fi

GROUP_COUNT=$(echo "$GROUPS" | wc -l | tr -d ' ')
echo "   Found ${GROUP_COUNT} group(s):"
echo "$GROUPS" | while IFS= read -r g; do echo "     - ${g}"; done

# Check current SCIM state
echo ""
echo ">> Current SCIM2 state for ${DOMAIN} domain:"
curl -sk -u "${WSO2_USER}:${WSO2_PASS}" "${WSO2_URL}/scim2/Groups?domain=${DOMAIN}" 2>/dev/null | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(f'   totalResults: {d.get(\"totalResults\", 0)}, Resources: {len(d.get(\"Resources\", []))}')
" 2>/dev/null || echo "   (could not parse response)"

# Stop WSO2 IS to release H2 lock
echo ""
echo ">> Stopping WSO2 IS to access H2 database..."
docker stop wso2is > /dev/null 2>&1
echo "   WSO2 IS stopped."

H2_URL="jdbc:h2:${DB_PATH}/WSO2IDENTITY_DB;DB_CLOSE_ON_EXIT=FALSE;LOCK_TIMEOUT=60000;IFEXISTS=TRUE"
H2_USER="wso2carbon"
H2_PASS_DB="wso2carbon"
NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Build SQL dynamically
echo ""
echo ">> Building SCIM metadata SQL for ${GROUP_COUNT} group(s)..."

SQL="DELETE FROM IDN_SCIM_GROUP WHERE ROLE_NAME LIKE '${DOMAIN}/%' AND TENANT_ID=${TENANT_ID};"

ID=${ID_BASE}
while IFS= read -r GROUP_NAME; do
  UUID=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || python3 -c "import uuid; print(uuid.uuid4())")
  ROLE_NAME="${DOMAIN}/${GROUP_NAME}"
  echo "   ${ROLE_NAME} -> UUID: ${UUID} (IDs: ${ID}-$((ID+3)))"
  SQL="${SQL} INSERT INTO IDN_SCIM_GROUP (ID,TENANT_ID,ROLE_NAME,ATTR_NAME,ATTR_VALUE,AUDIENCE_REF_ID) VALUES (${ID},${TENANT_ID},'${ROLE_NAME}','urn:ietf:params:scim:schemas:core:2.0:id','${UUID}',-1);"
  SQL="${SQL} INSERT INTO IDN_SCIM_GROUP (ID,TENANT_ID,ROLE_NAME,ATTR_NAME,ATTR_VALUE,AUDIENCE_REF_ID) VALUES ($((ID+1)),${TENANT_ID},'${ROLE_NAME}','urn:ietf:params:scim:schemas:core:2.0:meta.created','${NOW}',-1);"
  SQL="${SQL} INSERT INTO IDN_SCIM_GROUP (ID,TENANT_ID,ROLE_NAME,ATTR_NAME,ATTR_VALUE,AUDIENCE_REF_ID) VALUES ($((ID+2)),${TENANT_ID},'${ROLE_NAME}','urn:ietf:params:scim:schemas:core:2.0:meta.lastModified','${NOW}',-1);"
  SQL="${SQL} INSERT INTO IDN_SCIM_GROUP (ID,TENANT_ID,ROLE_NAME,ATTR_NAME,ATTR_VALUE,AUDIENCE_REF_ID) VALUES ($((ID+3)),${TENANT_ID},'${ROLE_NAME}','urn:ietf:params:scim:schemas:core:2.0:meta.location','${WSO2_URL}/scim2/Groups/${UUID}',-1);"
  ID=$((ID+4))
done <<< "$GROUPS"

echo ""
echo ">> Executing SQL (DELETE + ${GROUP_COUNT} groups x 4 rows)..."
docker run --rm -v "${DB_VOLUME}:${DB_PATH}" --entrypoint="" ${WSO2_IMAGE} \
    java -cp "${H2_JAR}" org.h2.tools.Shell \
    -url "${H2_URL}" -user "${H2_USER}" -password "${H2_PASS_DB}" \
    -sql "${SQL}"

echo "   SQL executed successfully."

# Restart WSO2 IS
echo ""
echo ">> Restarting WSO2 IS..."
docker start wso2is > /dev/null 2>&1
echo "   WSO2 IS restarting..."

# Wait for WSO2 IS to come back
echo ">> Waiting for WSO2 IS to start again..."
until curl -sk -o /dev/null -w "%{http_code}" "${WSO2_URL}/carbon/admin/login.jsp" | grep -q "200"; do
  sleep 5
done
echo "   WSO2 IS is ready."
sleep 5

# Verify
echo ""
echo ">> Verification - SCIM2 Groups (${DOMAIN} domain):"
curl -sk -u "${WSO2_USER}:${WSO2_PASS}" "${WSO2_URL}/scim2/Groups?domain=${DOMAIN}" | python3 -c "
import sys, json
data = json.load(sys.stdin)
resources = data.get('Resources', [])
print(f'   totalResults: {data.get(\"totalResults\", 0)}')
print(f'   Resources:    {len(resources)}')
for r in resources:
    members = r.get('members', [])
    member_names = [m.get('display','?') for m in members]
    print(f'     - {r.get(\"displayName\",\"?\")} (id: {r.get(\"id\",\"?\")[:8]}...) members: {member_names}')
" 2>/dev/null || echo "   Could not verify (python3 not available on host)"

echo ""
echo "============================================="
echo " SCIM Group seeding complete!"
echo " ${GROUP_COUNT} group(s) seeded for ${DOMAIN} domain."
echo "============================================="
