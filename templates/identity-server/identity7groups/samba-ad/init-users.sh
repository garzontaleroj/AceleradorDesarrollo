#!/bin/bash
# =============================================================
# Seed Active Directory with OUs, service account, users & groups
# Matches the production AD structure from AXA Colpatria (TSTF)
# =============================================================
set -e

echo "====================================="
echo " Initializing AD Users and Groups"
echo "====================================="

# ---------------------------
# Create Organizational Units
# ---------------------------
echo ""
echo ">> Creating Organizational Units..."

samba-tool ou create "OU=Service_accounts,DC=tstf,DC=axacolpatria,DC=co" 2>/dev/null \
    && echo "   Created OU=Service_accounts" \
    || echo "   OU=Service_accounts already exists"

samba-tool ou create "OU=Usuarios,DC=tstf,DC=axacolpatria,DC=co" 2>/dev/null \
    && echo "   Created OU=Usuarios" \
    || echo "   OU=Usuarios already exists"

samba-tool ou create "OU=Grupos,DC=tstf,DC=axacolpatria,DC=co" 2>/dev/null \
    && echo "   Created OU=Grupos" \
    || echo "   OU=Grupos already exists"

# ---------------------------
# Create WSO2 Service Account
# ---------------------------
echo ""
echo ">> Creating WSO2 service account..."

samba-tool user create Axaservicewso2Tip 'S3rv1c3@WSO2tip' \
    --given-name="WSO2" \
    --surname="ServiceAccount" \
    --company="AXA Colpatria" \
    --description="Service account for WSO2 Identity Server" \
    --userou="OU=Service_accounts" 2>/dev/null \
    && echo "   Created CN=Axaservicewso2Tip,OU=Service_accounts" \
    || echo "   Axaservicewso2Tip already exists"

# Ensure the service account password never expires
samba-tool user setexpiry Axaservicewso2Tip --noexpiry 2>/dev/null || true

# ---------------------------
# Create Test Users
# ---------------------------
echo ""
echo ">> Creating test users in OU=Usuarios..."

samba-tool user create jperez 'P@ssw0rd123!' \
    --given-name="Juan" \
    --surname="Perez" \
    --mail-address="jperez@tstf.axacolpatria.co" \
    --company="AXA Colpatria" \
    --department="Tecnologia" \
    --userou="OU=Usuarios" 2>/dev/null \
    && echo "   Created user jperez" \
    || echo "   User jperez already exists"

samba-tool user create mgarcia 'P@ssw0rd123!' \
    --given-name="Maria" \
    --surname="Garcia" \
    --mail-address="mgarcia@tstf.axacolpatria.co" \
    --company="AXA Colpatria" \
    --department="Operaciones" \
    --userou="OU=Usuarios" 2>/dev/null \
    && echo "   Created user mgarcia" \
    || echo "   User mgarcia already exists"

samba-tool user create clopez 'P@ssw0rd123!' \
    --given-name="Carlos" \
    --surname="Lopez" \
    --mail-address="clopez@tstf.axacolpatria.co" \
    --company="AXA Colpatria" \
    --department="Desarrollo" \
    --userou="OU=Usuarios" 2>/dev/null \
    && echo "   Created user clopez" \
    || echo "   User clopez already exists"

samba-tool user create arivera 'P@ssw0rd123!' \
    --given-name="Ana" \
    --surname="Rivera" \
    --mail-address="arivera@tstf.axacolpatria.co" \
    --company="AXA Colpatria" \
    --department="Soporte" \
    --userou="OU=Usuarios" 2>/dev/null \
    && echo "   Created user arivera" \
    || echo "   User arivera already exists"

# ---------------------------
# Create Security Groups
# ---------------------------
echo ""
echo ">> Creating security groups..."

samba-tool group add developers \
    --description="Grupo de desarrolladores" \
    --groupou="OU=Grupos" 2>/dev/null \
    && echo "   Created group developers" \
    || echo "   Group developers already exists"

samba-tool group add admins \
    --description="Grupo de administradores" \
    --groupou="OU=Grupos" 2>/dev/null \
    && echo "   Created group admins" \
    || echo "   Group admins already exists"

samba-tool group add operaciones \
    --description="Grupo de operaciones" \
    --groupou="OU=Grupos" 2>/dev/null \
    && echo "   Created group operaciones" \
    || echo "   Group operaciones already exists"

samba-tool group add soporte \
    --description="Grupo de soporte" \
    --groupou="OU=Grupos" 2>/dev/null \
    && echo "   Created group soporte" \
    || echo "   Group soporte already exists"

# ---------------------------
# Add Users to Groups
# ---------------------------
echo ""
echo ">> Adding users to groups..."

samba-tool group addmembers developers jperez,clopez 2>/dev/null \
    && echo "   developers <- jperez, clopez" \
    || echo "   developers members already set"

samba-tool group addmembers admins jperez 2>/dev/null \
    && echo "   admins <- jperez" \
    || echo "   admins members already set"

samba-tool group addmembers operaciones mgarcia,arivera 2>/dev/null \
    && echo "   operaciones <- mgarcia, arivera" \
    || echo "   operaciones members already set"

samba-tool group addmembers soporte arivera,clopez 2>/dev/null \
    && echo "   soporte <- arivera, clopez" \
    || echo "   soporte members already set"

# ---------------------------
# Summary
# ---------------------------
echo ""
echo "=============================================="
echo " AD Initialization Complete!"
echo "=============================================="
echo ""
echo " Domain:  TSTF.AXACOLPATRIA.CO"
echo " Base DN: DC=tstf,DC=axacolpatria,DC=co"
echo ""
echo " Service Account (WSO2):"
echo "   DN:       CN=Axaservicewso2Tip,OU=Service_accounts,DC=tstf,DC=axacolpatria,DC=co"
echo "   Password: S3rv1c3@WSO2tip"
echo ""
echo " Test Users (OU=Usuarios):"
echo "   jperez  / P@ssw0rd123!  -> developers, admins"
echo "   mgarcia / P@ssw0rd123!  -> operaciones"
echo "   clopez  / P@ssw0rd123!  -> developers, soporte"
echo "   arivera / P@ssw0rd123!  -> operaciones, soporte"
echo ""
echo " Groups (OU=Grupos):"
echo "   developers, admins, operaciones, soporte"
echo ""
echo " Admin Account:"
echo "   Administrator / P@ssw0rd2024"
echo "=============================================="
