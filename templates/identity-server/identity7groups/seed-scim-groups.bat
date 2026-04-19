@echo off
REM =============================================================
REM Seed SCIM metadata for LDAP groups in WSO2 IS H2 database
REM
REM DYNAMIC: Discovers all groups in ou=groups from OpenLDAP
REM via ldapsearch, then seeds SCIM metadata for each one.
REM Can be re-run after adding/removing groups in LDAP.
REM
REM WSO2 IS 7.x does NOT auto-provision SCIM metadata for groups
REM from external LDAP/AD userstores. Without this, SCIM2 /Groups
REM returns totalResults ^> 0 but empty Resources array.
REM
REM Strategy: H2 2.x embedded mode - stop WSO2 IS, run
REM DELETE+INSERT via temp container, then restart.
REM =============================================================

setlocal enabledelayedexpansion

set WSO2_URL=https://localhost:9443
set WSO2_USER=admin
set WSO2_PASS=admin
set TENANT_ID=-1234
set DB_VOLUME=identity7groups_wso2is_db
set WSO2_IMAGE=wso2/wso2is:7.2.0
set DB_PATH=/home/wso2carbon/wso2is-7.2.0/repository/database
set H2_JAR=/home/wso2carbon/wso2is-7.2.0/repository/components/plugins/h2-engine_2.2.224.wso2v2.jar

REM OpenLDAP connection
set LDAP_CONTAINER=openldap
set DOMAIN=LDAPSecondary
set ID_BASE=5001

echo =============================================
echo  Seeding SCIM metadata for LDAP groups
echo  (dynamic discovery from OpenLDAP)
echo =============================================
echo.

REM Wait for WSO2 IS to be ready (ensures DB schema exists and groups discovered from LDAP)
echo ^>^> Waiting for WSO2 Identity Server...
:wait_loop
curl -sk -o NUL -w "%%{http_code}" %WSO2_URL%/carbon/admin/login.jsp 2>NUL | findstr "200" >NUL
if errorlevel 1 (
    timeout /t 5 /nobreak >NUL
    goto wait_loop
)
echo    WSO2 IS is ready.

REM Wait for userstore to initialize
echo ^>^> Waiting for %DOMAIN% userstore to initialize...
timeout /t 15 /nobreak >NUL

REM Discover groups from OpenLDAP
echo.
echo ^>^> Discovering groups in ou=groups...

REM Query OpenLDAP and extract group names via PowerShell
docker exec %LDAP_CONTAINER% ldapsearch -LLL -x -H ldap://localhost:389 -D "cn=admin,dc=tsf,dc=axacolpatria,dc=co" -w "admin" -b "ou=groups,dc=tsf,dc=axacolpatria,dc=co" -s one "(objectClass=groupOfNames)" cn > "%TEMP%\ldap-groups-raw.txt" 2>NUL

powershell -Command "Get-Content '%TEMP%\ldap-groups-raw.txt' | Where-Object { $_ -match '^cn: ' } | ForEach-Object { ($_ -replace '^cn: ','').Trim() }" > "%TEMP%\ldap-groups.txt"

REM Count groups
set GROUP_COUNT=0
for /f "usebackq tokens=*" %%g in ("%TEMP%\ldap-groups.txt") do (
    set /a GROUP_COUNT+=1
)

if !GROUP_COUNT! EQU 0 (
    echo    ERROR: No groups found in ou=groups.
    echo    Verify OpenLDAP is running and groups exist.
    del "%TEMP%\ldap-groups-raw.txt" >NUL 2>&1
    del "%TEMP%\ldap-groups.txt" >NUL 2>&1
    exit /b 1
)

echo    Found !GROUP_COUNT! group(s):
for /f "usebackq tokens=*" %%g in ("%TEMP%\ldap-groups.txt") do (
    echo      - %%g
)

REM Check current SCIM state
echo.
echo ^>^> Current SCIM2 state for %DOMAIN% domain:
curl -sk -u %WSO2_USER%:%WSO2_PASS% "%WSO2_URL%/scim2/Groups?domain=%DOMAIN%" 2>NUL
echo.

REM Stop WSO2 IS to release H2 lock
echo.
echo ^>^> Stopping WSO2 IS to access H2 database...
docker stop wso2is >NUL 2>&1
echo    WSO2 IS stopped.

set H2_URL=jdbc:h2:%DB_PATH%/WSO2IDENTITY_DB;DB_CLOSE_ON_EXIT=FALSE;LOCK_TIMEOUT=60000;IFEXISTS=TRUE
set H2_USER=wso2carbon
set H2_PASS_DB=wso2carbon

REM Get current timestamp
for /f "tokens=*" %%i in ('powershell -Command "Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ' -AsUTC"') do set NOW=%%i

REM Build SQL file dynamically
set SQL_FILE=%TEMP%\seed-scim-groups-ldap.sql
echo.
echo ^>^> Building SCIM metadata SQL for !GROUP_COUNT! group(s)...

REM Start with DELETE all domain metadata
echo DELETE FROM IDN_SCIM_GROUP WHERE ROLE_NAME LIKE '%DOMAIN%/%%' AND TENANT_ID=%TENANT_ID%; > "%SQL_FILE%"

set ID=%ID_BASE%
for /f "usebackq tokens=*" %%g in ("%TEMP%\ldap-groups.txt") do (
    REM Generate UUID for this group
    for /f "tokens=*" %%u in ('powershell -Command "[guid]::NewGuid().ToString()"') do set UUID=%%u

    echo    %DOMAIN%/%%g -^> UUID: !UUID!

    echo INSERT INTO IDN_SCIM_GROUP ^(ID,TENANT_ID,ROLE_NAME,ATTR_NAME,ATTR_VALUE,AUDIENCE_REF_ID^) VALUES ^(!ID!,%TENANT_ID%,'%DOMAIN%/%%g','urn:ietf:params:scim:schemas:core:2.0:id','!UUID!',-1^); >> "%SQL_FILE%"
    set /a ID+=1
    echo INSERT INTO IDN_SCIM_GROUP ^(ID,TENANT_ID,ROLE_NAME,ATTR_NAME,ATTR_VALUE,AUDIENCE_REF_ID^) VALUES ^(!ID!,%TENANT_ID%,'%DOMAIN%/%%g','urn:ietf:params:scim:schemas:core:2.0:meta.created','!NOW!',-1^); >> "%SQL_FILE%"
    set /a ID+=1
    echo INSERT INTO IDN_SCIM_GROUP ^(ID,TENANT_ID,ROLE_NAME,ATTR_NAME,ATTR_VALUE,AUDIENCE_REF_ID^) VALUES ^(!ID!,%TENANT_ID%,'%DOMAIN%/%%g','urn:ietf:params:scim:schemas:core:2.0:meta.lastModified','!NOW!',-1^); >> "%SQL_FILE%"
    set /a ID+=1
    echo INSERT INTO IDN_SCIM_GROUP ^(ID,TENANT_ID,ROLE_NAME,ATTR_NAME,ATTR_VALUE,AUDIENCE_REF_ID^) VALUES ^(!ID!,%TENANT_ID%,'%DOMAIN%/%%g','urn:ietf:params:scim:schemas:core:2.0:meta.location','%WSO2_URL%/scim2/Groups/!UUID!',-1^); >> "%SQL_FILE%"
    set /a ID+=1
)

REM Execute SQL via temp container with mounted SQL file
echo.
echo ^>^> Executing SQL...
docker run --rm -v %DB_VOLUME%:%DB_PATH% -v "%SQL_FILE%:/tmp/seed.sql:ro" --entrypoint="" %WSO2_IMAGE% java -cp "%H2_JAR%" org.h2.tools.Shell -url "%H2_URL%" -user %H2_USER% -password %H2_PASS_DB% -sql "RUNSCRIPT FROM '/tmp/seed.sql'"

if errorlevel 1 (
    echo    ERROR: SQL execution failed.
    docker start wso2is >NUL 2>&1
    del "%TEMP%\ldap-groups-raw.txt" >NUL 2>&1
    del "%TEMP%\ldap-groups.txt" >NUL 2>&1
    del "%SQL_FILE%" >NUL 2>&1
    exit /b 1
)
echo    SQL executed successfully.

REM Clean up temp files
del "%TEMP%\ldap-groups-raw.txt" >NUL 2>&1
del "%TEMP%\ldap-groups.txt" >NUL 2>&1
del "%SQL_FILE%" >NUL 2>&1

REM Restart WSO2 IS
echo.
echo ^>^> Restarting WSO2 IS...
docker start wso2is >NUL 2>&1
echo    WSO2 IS restarting...

REM Wait for WSO2 IS to come back
echo ^>^> Waiting for WSO2 IS to start again...
:wait_restart
curl -sk -o NUL -w "%%{http_code}" %WSO2_URL%/carbon/admin/login.jsp 2>NUL | findstr "200" >NUL
if errorlevel 1 (
    timeout /t 5 /nobreak >NUL
    goto wait_restart
)
echo    WSO2 IS is ready.
timeout /t 5 /nobreak >NUL

REM Verify
echo.
echo ^>^> Verification - SCIM2 Groups (%DOMAIN% domain):
curl -sk -u %WSO2_USER%:%WSO2_PASS% "%WSO2_URL%/scim2/Groups?domain=%DOMAIN%" 2>NUL | python -m json.tool 2>NUL

echo.
echo =============================================
echo  SCIM Group seeding complete!
echo  !GROUP_COUNT! group(s) seeded for %DOMAIN% domain.
echo =============================================
