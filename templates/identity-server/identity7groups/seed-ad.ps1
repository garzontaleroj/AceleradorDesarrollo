# ============================================================================================
# seed-ad.ps1 — Seed Windows Server Active Directory via ADSI (sin RSAT)
# Dominio: tst.axacolpatria.co  |  Base DN: DC=tst,DC=axacolpatria,DC=co
#
# NO requiere RSAT ni módulo ActiveDirectory. Usa System.DirectoryServices (ADSI).
# Puede ejecutarse desde cualquier máquina Windows con acceso al DC.
#
# USO:
#   .\seed-ad.ps1
#   .\seed-ad.ps1 -Server "127.0.0.1" -AdminUser "Administrator" -AdminPass "Medjugorje4Ever*"
#   .\seed-ad.ps1 -DomainDN "DC=tst,DC=axacolpatria,DC=co" -DomainFQDN "tst.axacolpatria.co"
#
# NOTA CONTRASEÑAS: SetPassword usa RPC/SMB (puerto 445). Si falla, los usuarios
#   quedan creados pero deshabilitados. Ver instrucciones al final del script.
# ============================================================================================

param(
    [string]$Server     = "127.0.0.1",
    [string]$DomainDN   = "DC=tst,DC=axacolpatria,DC=co",
    [string]$DomainFQDN = "tst.axacolpatria.co",
    [string]$AdminUser  = "Administrator",
    [string]$AdminPass  = "Medjugorje4Ever*"
)

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "=============================================="
Write-Host " Seed Active Directory — TST.AXACOLPATRIA.CO"
Write-Host "=============================================="
Write-Host " Server  : $Server"
Write-Host " Base DN : $DomainDN"
Write-Host " FQDN    : $DomainFQDN"
Write-Host ""

# ── Helper: DirectoryEntry con credenciales ────────────────────────────────────────────────
function Get-DE([string]$DN) {
    return New-Object System.DirectoryServices.DirectoryEntry(
        "LDAP://$Server/$DN",
        "$AdminUser@$DomainFQDN",
        $AdminPass
    )
}

# ── Helper: buscar objeto por distinguishedName ────────────────────────────────────────────
function Find-ByDN([string]$DN) {
    $s = New-Object System.DirectoryServices.DirectorySearcher((Get-DE $DomainDN))
    $s.Filter = "(distinguishedName=$DN)"
    $s.SearchScope = "Subtree"
    return $s.FindOne()
}

# ── Helper: buscar objeto por sAMAccountName ──────────────────────────────────────────────
function Find-BySam([string]$Sam) {
    $s = New-Object System.DirectoryServices.DirectorySearcher((Get-DE $DomainDN))
    $s.Filter = "(sAMAccountName=$Sam)"
    $s.SearchScope = "Subtree"
    return $s.FindOne()
}

# ── Helper: crear OU si no existe ─────────────────────────────────────────────────────────
function New-OUIfNotExists {
    param([string]$Name, [string]$ParentDN, [string]$Description)
    $dn = "OU=$Name,$ParentDN"
    if (-not (Find-ByDN $dn)) {
        $parent = Get-DE $ParentDN
        $ou = $parent.Children.Add("OU=$Name", "organizationalUnit")
        $ou.Properties["description"].Value = $Description
        $ou.CommitChanges()
        Write-Host "   [+] OU creada : $dn"
    } else {
        Write-Host "   [=] OU existe : $dn"
    }
}

# ── Helper: crear usuario si no existe ────────────────────────────────────────────────────
function New-UserIfNotExists {
    param(
        [string]$SamAccount,
        [string]$GivenName,
        [string]$Surname,
        [string]$DisplayName,
        [string]$Mail,
        [string]$Department,
        [string]$EmployeeID,
        [string]$OUPath,
        [string]$Password,
        [bool]$NeverExpires = $false
    )
    if (-not (Find-BySam $SamAccount)) {
        $parent = Get-DE $OUPath
        $user = $parent.Children.Add("CN=$DisplayName", "user")
        $user.Properties["sAMAccountName"].Value    = $SamAccount
        $user.Properties["userPrincipalName"].Value = "$SamAccount@$DomainFQDN"
        $user.Properties["givenName"].Value         = $GivenName
        $user.Properties["sn"].Value                = $Surname
        $user.Properties["displayName"].Value       = $DisplayName
        $user.Properties["mail"].Value              = $Mail
        $user.Properties["department"].Value        = $Department
        $user.Properties["company"].Value           = "AXA Colpatria"
        # 514 = NORMAL_ACCOUNT + DISABLED (se habilita tras set password)
        $user.Properties["userAccountControl"].Value = 514
        $user.CommitChanges()

        # Establecer contraseña y habilitar cuenta
        try {
            $user.Invoke("SetPassword", $Password)
            # 512 = NORMAL_ACCOUNT enabled | 66048 = NORMAL_ACCOUNT + DONT_EXPIRE_PASSWORD
            $uac = if ($NeverExpires) { 66048 } else { 512 }
            $user.Properties["userAccountControl"].Value = $uac
            $user.CommitChanges()
            $tag = if ($NeverExpires) { " [pwd no expira]" } else { "" }
            Write-Host "   [+] Usuario creado y habilitado : $SamAccount$tag"
        } catch {
            Write-Host "   [!] Usuario creado DESHABILITADO (SetPassword falló) : $SamAccount"
            Write-Host "       -> Establece la contraseña manualmente en ADUC o ejecuta en el DC:"
            Write-Host "          net user $SamAccount `"$Password`" /domain"
        }
    } else {
        Write-Host "   [=] Usuario existe : $SamAccount"
    }
}

# ── Helper: crear grupo si no existe ──────────────────────────────────────────────────────
function New-GroupIfNotExists {
    param([string]$Name, [string]$Description, [string]$OUPath)
    if (-not (Find-BySam $Name)) {
        $parent = Get-DE $OUPath
        $grp = $parent.Children.Add("CN=$Name", "group")
        $grp.Properties["sAMAccountName"].Value = $Name
        $grp.Properties["description"].Value    = $Description
        $grp.Properties["groupType"].Value      = -2147483646  # Global Security Group
        $grp.CommitChanges()
        Write-Host "   [+] Grupo creado : $Name"
    } else {
        Write-Host "   [=] Grupo existe : $Name"
    }
}

# ── Helper: agregar miembro a grupo si no está ────────────────────────────────────────────
function Add-MemberIfNotIn {
    param([string]$GroupSam, [string]$MemberSam)
    $gResult = Find-BySam $GroupSam
    if (-not $gResult) { Write-Host "   [!] Grupo no encontrado : $GroupSam"; return }
    $uResult = Find-BySam $MemberSam
    if (-not $uResult) { Write-Host "   [!] Usuario no encontrado : $MemberSam"; return }

    $memberDN  = $uResult.Properties["distinguishedname"][0]
    $grpDE     = $gResult.GetDirectoryEntry()
    $current   = @($grpDE.Properties["member"] | ForEach-Object { "$_" })

    if ($current -notcontains $memberDN) {
        $grpDE.Properties["member"].Add($memberDN) | Out-Null
        $grpDE.CommitChanges()
        Write-Host "   [+] $GroupSam  <- $MemberSam"
    } else {
        Write-Host "   [=] $GroupSam ya contiene : $MemberSam"
    }
}

# ══════════════════════════════════════════════════════════════════════════════════════════════
# 1. ORGANIZATIONAL UNITS
# ══════════════════════════════════════════════════════════════════════════════════════════════
Write-Host ">> Creando Organizational Units..."
New-OUIfNotExists -Name "Service_accounts" -ParentDN $DomainDN -Description "Cuentas de servicio para integraciones"
New-OUIfNotExists -Name "Usuarios"         -ParentDN $DomainDN -Description "Usuarios del dominio TST"
New-OUIfNotExists -Name "Grupos"           -ParentDN $DomainDN -Description "Grupos de seguridad del dominio TST"

$ouUsuarios = "OU=Usuarios,$DomainDN"
$ouGrupos   = "OU=Grupos,$DomainDN"
$ouSvc      = "OU=Service_accounts,$DomainDN"

# ══════════════════════════════════════════════════════════════════════════════════════════════
# 2. SERVICE ACCOUNT — WSO2 Identity Server
# ══════════════════════════════════════════════════════════════════════════════════════════════
Write-Host ""
Write-Host ">> Creando cuenta de servicio WSO2..."
New-UserIfNotExists `
    -SamAccount   "Axaservicewso2Tip" `
    -GivenName    "WSO2" `
    -Surname      "ServiceAccount" `
    -DisplayName  "WSO2 ServiceAccount" `
    -Mail         "axaservicewso2tip@axacolpatria.co" `
    -Department   "Tecnologia" `
    -EmployeeID   "svc-wso2-001" `
    -OUPath       $ouSvc `
    -Password     "S3rv1c3@WSO2tip" `
    -NeverExpires $true

# ══════════════════════════════════════════════════════════════════════════════════════════════
# 3. USUARIOS DE PRUEBA
# ══════════════════════════════════════════════════════════════════════════════════════════════
Write-Host ""
Write-Host ">> Creando usuarios en OU=Usuarios..."

New-UserIfNotExists `
    -SamAccount  "jperez" `
    -GivenName   "Juan" `
    -Surname     "Perez" `
    -DisplayName "Juan Perez" `
    -Mail        "jperez@axacolpatria.co" `
    -Department  "Tecnologia" `
    -EmployeeID  "89d7666b-9e43-49fb-99a2-9580bed45ddb" `
    -OUPath      $ouUsuarios `
    -Password    "P@ssw0rd123!"

New-UserIfNotExists `
    -SamAccount  "mgarcia" `
    -GivenName   "Maria" `
    -Surname     "Garcia" `
    -DisplayName "Maria Garcia" `
    -Mail        "mgarcia@axacolpatria.co" `
    -Department  "Operaciones" `
    -EmployeeID  "522f3448-32a8-4db3-943c-ebd2b64d637b" `
    -OUPath      $ouUsuarios `
    -Password    "P@ssw0rd123!"

New-UserIfNotExists `
    -SamAccount  "clopez" `
    -GivenName   "Carlos" `
    -Surname     "Lopez" `
    -DisplayName "Carlos Lopez" `
    -Mail        "clopez@axacolpatria.co" `
    -Department  "Desarrollo" `
    -EmployeeID  "a1b2c3d4-e5f6-7890-abcd-ef1234567890" `
    -OUPath      $ouUsuarios `
    -Password    "P@ssw0rd123!"

New-UserIfNotExists `
    -SamAccount  "arivera" `
    -GivenName   "Ana" `
    -Surname     "Rivera" `
    -DisplayName "Ana Rivera" `
    -Mail        "arivera@axacolpatria.co" `
    -Department  "Soporte" `
    -EmployeeID  "b2c3d4e5-f6a7-8901-bcde-f12345678901" `
    -OUPath      $ouUsuarios `
    -Password    "P@ssw0rd123!"

# ══════════════════════════════════════════════════════════════════════════════════════════════
# 4. GRUPOS DE SEGURIDAD
# ══════════════════════════════════════════════════════════════════════════════════════════════
Write-Host ""
Write-Host ">> Creando grupos en OU=Grupos..."
New-GroupIfNotExists -Name "developers"  -Description "Grupo de desarrolladores"  -OUPath $ouGrupos
New-GroupIfNotExists -Name "admins"      -Description "Grupo de administradores"  -OUPath $ouGrupos
New-GroupIfNotExists -Name "operaciones" -Description "Grupo de operaciones"      -OUPath $ouGrupos
New-GroupIfNotExists -Name "soporte"     -Description "Grupo de soporte tecnico"  -OUPath $ouGrupos

# ══════════════════════════════════════════════════════════════════════════════════════════════
# 5. MEMBRESÍAS
# ══════════════════════════════════════════════════════════════════════════════════════════════
Write-Host ""
Write-Host ">> Asignando usuarios a grupos..."
Add-MemberIfNotIn -GroupSam "developers"  -MemberSam "jperez"
Add-MemberIfNotIn -GroupSam "developers"  -MemberSam "clopez"
Add-MemberIfNotIn -GroupSam "admins"      -MemberSam "jperez"
Add-MemberIfNotIn -GroupSam "operaciones" -MemberSam "mgarcia"
Add-MemberIfNotIn -GroupSam "operaciones" -MemberSam "arivera"
Add-MemberIfNotIn -GroupSam "soporte"     -MemberSam "arivera"
Add-MemberIfNotIn -GroupSam "soporte"     -MemberSam "clopez"

# ══════════════════════════════════════════════════════════════════════════════════════════════
# 6. RESUMEN
# ══════════════════════════════════════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "=============================================="
Write-Host " AD Seed completado!"
Write-Host "=============================================="
Write-Host ""
Write-Host " Servidor : ldap://$Server"
Write-Host " Dominio  : $DomainFQDN"
Write-Host " Base DN  : $DomainDN"
Write-Host ""
Write-Host " Cuenta de servicio (WSO2 IS):"
Write-Host "   DN       : CN=WSO2 ServiceAccount,OU=Service_accounts,$DomainDN"
Write-Host "   SAM      : Axaservicewso2Tip"
Write-Host "   Password : S3rv1c3@WSO2tip"
Write-Host ""
Write-Host " Usuarios de prueba (Password: P@ssw0rd123!):"
Write-Host "   jperez   -> developers, admins"
Write-Host "   mgarcia  -> operaciones"
Write-Host "   clopez   -> developers, soporte"
Write-Host "   arivera  -> operaciones, soporte"
Write-Host ""
Write-Host " Si algún usuario quedó DESHABILITADO, ejecutar en el DC:"
Write-Host "   net user jperez   `"P@ssw0rd123!`" /domain"
Write-Host "   net user mgarcia  `"P@ssw0rd123!`" /domain"
Write-Host "   net user clopez   `"P@ssw0rd123!`" /domain"
Write-Host "   net user arivera  `"P@ssw0rd123!`" /domain"
Write-Host ""
