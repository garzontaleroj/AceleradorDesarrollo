@echo off
REM =============================================================
REM Claim Mapping for LDAPSecondary User Store
REM Maps WSO2 IS claims to OpenLDAP attributes
REM =============================================================

echo Waiting for WSO2 Identity Server to start...

:wait_loop
curl -sk -o NUL -w "%%{http_code}" https://localhost:9443/carbon/admin/login.jsp 2>NUL | findstr "200" >NUL
if errorlevel 1 (
    timeout /t 5 /nobreak >NUL
    goto wait_loop
)

echo WSO2 IS is ready. Applying LDAP claim mappings...

REM User ID claim -> employeeNumber for LDAPSecondary
curl -sk -X PUT -u admin:admin ^
  -H "Content-Type: application/json" ^
  -d "{\"claimURI\":\"http://wso2.org/claims/userid\",\"description\":\"Unique ID of the user\",\"displayOrder\":0,\"displayName\":\"User ID\",\"readOnly\":true,\"required\":false,\"supportedByDefault\":false,\"attributeMapping\":[{\"mappedAttribute\":\"scimId\",\"userstore\":\"PRIMARY\"},{\"mappedAttribute\":\"employeeNumber\",\"userstore\":\"LDAPSecondary\"}],\"properties\":[{\"key\":\"isSystemClaim\",\"value\":\"true\"}]}" ^
  "https://localhost:9443/api/server/v1/claim-dialects/local/claims/aHR0cDovL3dzbzIub3JnL2NsYWltcy91c2VyaWQ"

echo.

REM Username claim -> uid
curl -sk -X PUT -u admin:admin ^
  -H "Content-Type: application/json" ^
  -d "{\"claimURI\":\"http://wso2.org/claims/username\",\"description\":\"Username\",\"displayOrder\":0,\"displayName\":\"Username\",\"readOnly\":true,\"required\":true,\"supportedByDefault\":true,\"attributeMapping\":[{\"mappedAttribute\":\"uid\",\"userstore\":\"PRIMARY\"},{\"mappedAttribute\":\"uid\",\"userstore\":\"LDAPSecondary\"}],\"properties\":[]}" ^
  "https://localhost:9443/api/server/v1/claim-dialects/local/claims/aHR0cDovL3dzbzIub3JnL2NsYWltcy91c2VybmFtZQ"

echo.

REM First Name claim -> givenName
curl -sk -X PUT -u admin:admin ^
  -H "Content-Type: application/json" ^
  -d "{\"claimURI\":\"http://wso2.org/claims/givenname\",\"description\":\"First Name\",\"displayOrder\":1,\"displayName\":\"First Name\",\"readOnly\":true,\"required\":false,\"supportedByDefault\":true,\"attributeMapping\":[{\"mappedAttribute\":\"givenName\",\"userstore\":\"PRIMARY\"},{\"mappedAttribute\":\"givenName\",\"userstore\":\"LDAPSecondary\"}],\"properties\":[]}" ^
  "https://localhost:9443/api/server/v1/claim-dialects/local/claims/aHR0cDovL3dzbzIub3JnL2NsYWltcy9naXZlbm5hbWU"

echo.

REM Last Name claim -> sn
curl -sk -X PUT -u admin:admin ^
  -H "Content-Type: application/json" ^
  -d "{\"claimURI\":\"http://wso2.org/claims/lastname\",\"description\":\"Last Name\",\"displayOrder\":2,\"displayName\":\"Last Name\",\"readOnly\":true,\"required\":false,\"supportedByDefault\":true,\"attributeMapping\":[{\"mappedAttribute\":\"sn\",\"userstore\":\"PRIMARY\"},{\"mappedAttribute\":\"sn\",\"userstore\":\"LDAPSecondary\"}],\"properties\":[]}" ^
  "https://localhost:9443/api/server/v1/claim-dialects/local/claims/aHR0cDovL3dzbzIub3JnL2NsYWltcy9sYXN0bmFtZQ"

echo.

REM Email claim -> mail
curl -sk -X PUT -u admin:admin ^
  -H "Content-Type: application/json" ^
  -d "{\"claimURI\":\"http://wso2.org/claims/emailaddress\",\"description\":\"Email Address\",\"displayOrder\":5,\"displayName\":\"Email\",\"readOnly\":true,\"required\":false,\"supportedByDefault\":true,\"attributeMapping\":[{\"mappedAttribute\":\"mail\",\"userstore\":\"PRIMARY\"},{\"mappedAttribute\":\"mail\",\"userstore\":\"LDAPSecondary\"}],\"properties\":[]}" ^
  "https://localhost:9443/api/server/v1/claim-dialects/local/claims/aHR0cDovL3dzbzIub3JnL2NsYWltcy9lbWFpbGFkZHJlc3M"

echo.

REM Groups claim -> member (reverse lookup via memberOf)
curl -sk -X PUT -u admin:admin ^
  -H "Content-Type: application/json" ^
  -d "{\"claimURI\":\"http://wso2.org/claims/groups\",\"description\":\"Groups\",\"displayOrder\":0,\"displayName\":\"Groups\",\"readOnly\":true,\"required\":false,\"supportedByDefault\":false,\"attributeMapping\":[{\"mappedAttribute\":\"groups\",\"userstore\":\"PRIMARY\"},{\"mappedAttribute\":\"member\",\"userstore\":\"LDAPSecondary\"}],\"properties\":[]}" ^
  "https://localhost:9443/api/server/v1/claim-dialects/local/claims/aHR0cDovL3dzbzIub3JnL2NsYWltcy9ncm91cHM"

echo.
echo =============================================
echo  LDAP Claim mappings applied successfully!
echo =============================================
