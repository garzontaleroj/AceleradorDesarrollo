#!/bin/bash
# =============================================================
# Claim Mapping for AD (TSTF) User Store
# Maps WSO2 IS claims to Active Directory LDAP attributes
# =============================================================

echo "Waiting for WSO2 Identity Server to start..."
until curl -sk -o /dev/null -w "%{http_code}" https://localhost:9443/carbon/admin/login.jsp | grep -q "200"; do
  sleep 5
done
echo "WSO2 IS is ready. Applying AD claim mappings..."

# -----------------------------------------------------------
# User ID claim -> objectGuid for TSTF userstore
# -----------------------------------------------------------
curl -sk -X PUT -u admin:admin \
  -H "Content-Type: application/json" \
  -d '{
    "claimURI": "http://wso2.org/claims/userid",
    "description": "Unique ID of the user",
    "displayOrder": 0,
    "displayName": "User ID",
    "readOnly": true,
    "required": false,
    "supportedByDefault": false,
    "attributeMapping": [
      {"mappedAttribute": "scimId", "userstore": "PRIMARY"},
      {"mappedAttribute": "objectGuid", "userstore": "TSTF"}
    ],
    "properties": [
      {"key": "isSystemClaim", "value": "true"}
    ]
  }' \
  "https://localhost:9443/api/server/v1/claim-dialects/local/claims/aHR0cDovL3dzbzIub3JnL2NsYWltcy91c2VyaWQ"

echo ""

# -----------------------------------------------------------
# Username claim -> sAMAccountName
# -----------------------------------------------------------
curl -sk -X PUT -u admin:admin \
  -H "Content-Type: application/json" \
  -d '{
    "claimURI": "http://wso2.org/claims/username",
    "description": "Username",
    "displayOrder": 0,
    "displayName": "Username",
    "readOnly": true,
    "required": true,
    "supportedByDefault": true,
    "attributeMapping": [
      {"mappedAttribute": "uid", "userstore": "PRIMARY"},
      {"mappedAttribute": "sAMAccountName", "userstore": "TSTF"}
    ],
    "properties": []
  }' \
  "https://localhost:9443/api/server/v1/claim-dialects/local/claims/aHR0cDovL3dzbzIub3JnL2NsYWltcy91c2VybmFtZQ"

echo ""

# -----------------------------------------------------------
# First Name claim -> givenName
# -----------------------------------------------------------
curl -sk -X PUT -u admin:admin \
  -H "Content-Type: application/json" \
  -d '{
    "claimURI": "http://wso2.org/claims/givenname",
    "description": "First Name",
    "displayOrder": 1,
    "displayName": "First Name",
    "readOnly": true,
    "required": false,
    "supportedByDefault": true,
    "attributeMapping": [
      {"mappedAttribute": "givenName", "userstore": "PRIMARY"},
      {"mappedAttribute": "givenName", "userstore": "TSTF"}
    ],
    "properties": []
  }' \
  "https://localhost:9443/api/server/v1/claim-dialects/local/claims/aHR0cDovL3dzbzIub3JnL2NsYWltcy9naXZlbm5hbWU"

echo ""

# -----------------------------------------------------------
# Last Name claim -> sn
# -----------------------------------------------------------
curl -sk -X PUT -u admin:admin \
  -H "Content-Type: application/json" \
  -d '{
    "claimURI": "http://wso2.org/claims/lastname",
    "description": "Last Name",
    "displayOrder": 2,
    "displayName": "Last Name",
    "readOnly": true,
    "required": false,
    "supportedByDefault": true,
    "attributeMapping": [
      {"mappedAttribute": "sn", "userstore": "PRIMARY"},
      {"mappedAttribute": "sn", "userstore": "TSTF"}
    ],
    "properties": []
  }' \
  "https://localhost:9443/api/server/v1/claim-dialects/local/claims/aHR0cDovL3dzbzIub3JnL2NsYWltcy9sYXN0bmFtZQ"

echo ""

# -----------------------------------------------------------
# Email claim -> mail
# -----------------------------------------------------------
curl -sk -X PUT -u admin:admin \
  -H "Content-Type: application/json" \
  -d '{
    "claimURI": "http://wso2.org/claims/emailaddress",
    "description": "Email Address",
    "displayOrder": 5,
    "displayName": "Email",
    "readOnly": true,
    "required": false,
    "supportedByDefault": true,
    "attributeMapping": [
      {"mappedAttribute": "mail", "userstore": "PRIMARY"},
      {"mappedAttribute": "mail", "userstore": "TSTF"}
    ],
    "properties": []
  }' \
  "https://localhost:9443/api/server/v1/claim-dialects/local/claims/aHR0cDovL3dzbzIub3JnL2NsYWltcy9lbWFpbGFkZHJlc3M"

echo ""

# -----------------------------------------------------------
# Groups claim -> memberOf
# -----------------------------------------------------------
curl -sk -X PUT -u admin:admin \
  -H "Content-Type: application/json" \
  -d '{
    "claimURI": "http://wso2.org/claims/groups",
    "description": "Groups",
    "displayOrder": 0,
    "displayName": "Groups",
    "readOnly": true,
    "required": false,
    "supportedByDefault": false,
    "attributeMapping": [
      {"mappedAttribute": "groups", "userstore": "PRIMARY"},
      {"mappedAttribute": "memberOf", "userstore": "TSTF"}
    ],
    "properties": []
  }' \
  "https://localhost:9443/api/server/v1/claim-dialects/local/claims/aHR0cDovL3dzbzIub3JnL2NsYWltcy9ncm91cHM"

echo ""

# -----------------------------------------------------------
# Created date claim -> whenCreated (AD timestamp)
# -----------------------------------------------------------
curl -sk -X PUT -u admin:admin \
  -H "Content-Type: application/json" \
  -d '{
    "claimURI": "http://wso2.org/claims/created",
    "description": "Created Time",
    "displayOrder": 0,
    "displayName": "Created",
    "readOnly": true,
    "required": false,
    "supportedByDefault": false,
    "attributeMapping": [
      {"mappedAttribute": "createdDate", "userstore": "PRIMARY"},
      {"mappedAttribute": "whenCreated", "userstore": "TSTF"}
    ],
    "properties": []
  }' \
  "https://localhost:9443/api/server/v1/claim-dialects/local/claims/aHR0cDovL3dzbzIub3JnL2NsYWltcy9jcmVhdGVk"

echo ""

# -----------------------------------------------------------
# Modified date claim -> whenChanged (AD timestamp)
# -----------------------------------------------------------
curl -sk -X PUT -u admin:admin \
  -H "Content-Type: application/json" \
  -d '{
    "claimURI": "http://wso2.org/claims/modified",
    "description": "Last Modified Time",
    "displayOrder": 0,
    "displayName": "Last Modified",
    "readOnly": true,
    "required": false,
    "supportedByDefault": false,
    "attributeMapping": [
      {"mappedAttribute": "lastModifiedDate", "userstore": "PRIMARY"},
      {"mappedAttribute": "whenChanged", "userstore": "TSTF"}
    ],
    "properties": []
  }' \
  "https://localhost:9443/api/server/v1/claim-dialects/local/claims/aHR0cDovL3dzbzIub3JnL2NsYWltcy9tb2RpZmllZA"

echo ""
echo "============================================="
echo " AD Claim mappings applied successfully!"
echo "============================================="
echo ""
echo " Mapped claims for userstore TSTF:"
echo "   User ID   -> objectGuid"
echo "   Username  -> sAMAccountName"
echo "   FirstName -> givenName"
echo "   LastName  -> sn"
echo "   Email     -> mail"
echo "   Groups    -> memberOf"
echo "   Created   -> whenCreated"
echo "   Modified  -> whenChanged"
echo "============================================="
