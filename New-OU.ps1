<#
.SYNOPSIS
This script will create the OU structure for a new site, add the security settings to these new OUs and create associated groups.
.DESCRIPTION
This script will create the OU structure for a new site, add the security settings to these new OUs and create associated groups.
.PARAMETER location
List of location example: "Bedford", "Bentonville", "Bromptonville", "Brassfield", etc.
.PARAMETER BusinessUnit
list of busines units: "Corporate", "Energy", "Head Office", "Kruger Products", "Packaging", "Publication", "Recycling"
.PARAMETER OuDescription
Description for this new OU
.EXAMPLE
C:\Scripts\new-OU.ps1 -location Richelieu -Extension GR -BusinessUnit 'Kruger Products' -OuDescription "OU pour Gatineau Richelieu"
#>
param(
    [Parameter(Mandatory = $true)]
    $location,
    [Parameter(Mandatory = $true)]
    $Extension,
    [Parameter(Mandatory = $true)]
    [ValidateSet("Corporate", "Energy", "Head Office", "Kruger Products", "Packaging", "Publication", "Recycling")]
    [string] $BusinessUnit,
    [Parameter(Mandatory = $False)]
    $OuDescription
)

# Import the modules
Import-Module ActiveDirectory
# Define the Base OU
$BaseOUs = "OU=Test",
"OU=Users",
"OU=Servers",
"OU=Groups",
"OU=Contacts",
"OU=Computers",
"OU=Account Admins,OU=Users",
"OU=Privileged,OU=Users",
"OU=Production Techs,OU=Users",
"OU=Resources,OU=Users",
"OU=Server Admins,OU=Users",
"OU=Service Accounts,OU=Users",
"OU=Site Admins,OU=Users",
"OU=Site Techs,OU=Users",
"OU=Standard Users,OU=Users",
"OU=LockDown Users,OU=Standard Users,OU=Users",
"OU=Management,OU=Servers",
"OU=Terminal Servers,OU=Servers",
"OU=Distribution,OU=Groups",
"OU=GPO,OU=Groups",
"OU=Printers,OU=Groups",
"OU=Desktops,OU=Computers",
"OU=Mobile,OU=Computers",
"OU=Production,OU=Computers"

# Create all the OUs 

if ($BusinessUnit -in "head Office", "Energy", "Corporate") {
    $OU = "OU=$BusinessUnit,DC=kruger,DC=com"

} `
    else {
    $OU = "OU=$location,OU=$BusinessUnit,DC=kruger,DC=com"
}

Try { Get-ADOrganizationalUnit -Identity $OU } catch { New-ADOrganizationalUnit -DisplayName $location -Name $location -Description $OuDescription -Path "OU=$BusinessUnit,DC=kruger,DC=com" }


foreach ($BaseOU in $BaseOUs) {
    Try { Get-ADOrganizationalUnit -Identity "$BaseOU,$OU" } catch {
        $NewOu = $BaseOU.split(",")[0].split("=")[1]
        $OUPath = "$BaseOU,$OU".substring("$BaseOU,$OU".indexof(",") + 1)
        New-ADOrganizationalUnit -DisplayName $NewOu -Name $NewOu -Path $OUPath -Verbose
    }
}

# Create Groups

$name = "$extension Production Techs"; if (!(Get-ADGroup -Filter { name -eq $name })) {
    New-ADGroup -Path "OU=Production Techs,OU=Users,$ou" -Name $name -GroupCategory Security -GroupScope Universal -SamAccountName "$ExtensionProductionTechs" -DisplayName $name -Verbose
}
$name = "$extension Site Techs"; if (!( Get-ADGroup -Filter { name -eq $name })) {
    New-ADGroup -Path "OU=Site Techs,OU=Users,$ou" -Name $name -GroupCategory Security -GroupScope Universal -SamAccountName "$ExtensionSiteTechs" -DisplayName $name -Verbose
}
$name = "$extension Account admins"; if (!( Get-ADGroup -Filter { name -eq $name })) {
    New-ADGroup -Path "OU=Account Admins,OU=Users,$ou" -Name $name -GroupCategory Security -GroupScope Universal -Description ("Members of this group can manage users in " + $ou.split(",")[0].split("=")[1]) -SamAccountName "$ExtensionAccountAdmins" -DisplayName $name -Verbose
}
$name = "$extension Server admins"; if (!( Get-ADGroup -Filter { name -eq $name })) {
    New-ADGroup -Path "OU=Server Admins,OU=Users,$ou" -Name $name -GroupCategory Security -GroupScope Universal -SamAccountName "$ExtensionAccountAdmins" -DisplayName $name -Verbose
}
$name = "$extension Site admins"; if (!( Get-ADGroup -Filter { name -eq $name })) {
    New-ADGroup -Path "OU=Site Admins,OU=Users,$ou" -Name $name -GroupCategory Security -GroupScope Universal -SamAccountName "$ExtensionSiteAdmins" -DisplayName $name -Verbose
}
$name = "$extension PRV Accounts"; if (!( Get-ADGroup -Filter { name -eq $name })) {
    New-ADGroup -Path "OU=GPO,OU=Groups,$ou" -Name $name -GroupCategory Security -GroupScope Universal -SamAccountName $name -DisplayName $name -Description "Computer OBJ only Exception GPO Removal Admin rights" -Verbose 
}

# Prend comme exemple OU Sherbrooke.  Crée les groupes SCCM

Get-ADGroup -SearchBase "OU=Groups,OU=Sherbrooke,OU=Kruger Products,DC=kruger,DC=com" -Filter { name -like "SH servers:*" -or name -like "SH workstation*" } | ForEach-Object {
    $name = $_.name -replace ("^SH", $Extension) 
    New-ADGroup -Path "OU=Groups,$ou" -Name $name -DisplayName $name -SamAccountName $name.replace(":", "").replace(" ", "") -Description $_.description -GroupScope Global -GroupCategory Security -Verbose 
}

Write-Host "Ajoute les groupes créé dans les groupes SCCMM"

Get-ADGroup -SearchBase "OU=Groups,OU=Sherbrooke,OU=Kruger Products,DC=kruger,DC=com" -Filter { name -like "SH WORKSTATION*" -OR name -like "SH server*" } -Properties memberof | ForEach-Object { 
    $name = $_.name -replace ("^SH", $extension) 
    $_.memberof | ForEach-Object {
        Add-ADGroupMember -Identity $_ -Members "cn=$name,OU=Groups,$ou" -Verbose 
    }
}

# Create $extension Service Accounts Server and $extension Service Accounts Computer groups 
$Name = "$extension Service Accounts Server"
if (!( Get-ADGroup -Filter { name -like $name })) {
    New-ADGroup -Path "OU=Service Accounts,OU=Users,$ou" -Name $name -DisplayName $name -SamAccountName $name -Description "GPO will add this group to local adminstrators group on servers" -GroupScope Global -GroupCategory Security -Verbose 
}
Add-ADGroupMember -Identity $name -Members "CN=HO SA SCCM Client Push srv,OU=Accounts,OU=SCCM_Admins,OU=SCCM_Management,DC=kruger,DC=com"

$Name = "$extension Service Accounts Computer"
if (!( Get-ADGroup -Filter { name -like $name })) {
    New-ADGroup -Path "OU=Service Accounts,OU=Users,$ou" -Name $name -DisplayName $name -SamAccountName $name -Description "GPO will add this group to local adminstrators group on Computers" -GroupScope Global -GroupCategory Security -Verbose 
}
Add-ADGroupMember -Identity $name -Members "CN=hosacmmKLPush,OU=Accounts,OU=SCCM_Admins,OU=SCCM_Management,DC=kruger,DC=com", "CN=HO SA SCCM Client Push wks,OU=Accounts,OU=SCCM_Admins,OU=SCCM_Management,DC=kruger,DC=com"

# Set-Location ad:
# $ACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $identity, $adRights, $type, $inheritanceType

# define Function
function convertto-sid { param($NtAccount) (New-Object system.security.principal.NtAccount($NTaccount)).translate([system.security.principal.securityidentifier]) }

# Add the ACE to the ACL, then set the ACL to save the changes
$rootdse = Get-ADRootDSE

#Create a hashtable to store the GUID value of each schema class and attribute
$guidmap = [ordered] @{}
Get-ADObject -SearchBase ($rootdse.SchemaNamingContext) -LDAPFilter `
    "(schemaidguid=*)" -Properties lDAPDisplayName, schemaIDGUID | Sort-Object -Property lDAPDisplayName |  `
    ForEach-Object { $guidmap[$_.lDAPDisplayName] = [System.GUID]$_.schemaIDGUID }

#Create a hashtable to store the GUID value of each extended right in the forest
$extendedrightsmap = [ordered] @{}
Get-ADObject -SearchBase ($rootdse.ConfigurationNamingContext) -LDAPFilter `
    "(&(objectclass=controlAccessRight)(rightsguid=*))" -Properties displayName, rightsGuid | Sort-Object -Property displayName | `
    ForEach-Object { $extendedrightsmap[$_.displayName] = [System.GUID]$_.rightsGuid }

####################################################################
# Add computer's Self right to ms-Mcs-AdmPwd and ms-Mcs-AdmPwdExpirationTime on the computer object
# SID for AUTORITE NT\SELF
$self = convertto-sid 'AUTORITE NT\SELF'

$Paths2OU = "ad:OU=Servers,$OU", "ad:OU=Computers,$OU"

foreach ($Path2OU in $Paths2OU) {
    $acl = Get-Acl -Path $Path2OU
    $acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $Self, "ExtendedRight", "Allow", $guidmap["ms-Mcs-AdmPwd"], "Descendents", $guidmap["Computer"]  ))
    $acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $Self, "ExtendedRight", "Allow", $guidmap["ms-Mcs-AdmPwdExpirationTime"], "Descendents", $guidmap["Computer"]  ))
}

####################################################################
# Add Account admins full control on the Users, Contacts and Groups OUs.

$AccountAdmins = $extension + " Account admins"
$SID = (Get-ADGroup -Filter { name -eq  $AccountAdmins }).sid

$parameters = @(@{OUs = "Contacts"; Object = "Contact" }, @{OUs = "Users"; Object = "User" }, @{OUs = "Groups"; Object = "Group" })

$parameters | ForEach-Object {
    $acl = Get-Acl -Path ("ad:ou=" + $_.OUs + "," + $ou)
    $acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $SID, "GenericAll", "Allow", "Descendents", $guidmap[$_.object]  ))
    Set-Acl -Path ("ad:ou=" + $_.OUs + "," + $ou) -AclObject $acl
}

# Modify security in Groups OU
$acl = Get-Acl -Path ("ad:ou=groups," + $ou)
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $SID, "WriteProperty", "Allow", $guidmap["Member"] , "Descendents", $guidmap["Group"]  ))
Set-Acl -Path ("ad:ou=groups," + $ou) -AclObject $acl
####################################################################
# Add Production tech control on the Computer\Production OUs.

$ProductionTech = $extension + " Production Techs"
$SID = (Get-ADGroup -Filter { name -eq  $ProductionTech }).sid

$parameters = @(@{OUs = "Production,ou=Computers"; Object = "Computer" })

$parameters | ForEach-Object {
    $acl = Get-Acl -Path ("ad:ou=" + $_.OUs + "," + $ou)
    $acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $SID, "GenericAll", "Allow", "Descendents", $guidmap[$_.object]  ))
    Set-Acl -Path ("ad:ou=" + $_.OUs + "," + $ou) -AclObject $acl
}

$acl = Get-Acl "ad:ou=GPO,ou=groups,$ou"
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $SID, "WriteProperty", "Allow", "Descendents", $guidmap["group"]  ))
Set-Acl -Path "ad:ou=GPO,ou=groups,$ou" -AclObject $acl

####################################################################
# Add Site techs control on the Computers OUs.

$SiteTech = $extension + " Site Techs"
$SID = (Get-ADGroup -Filter { name -eq  $SiteTech }).sid

$parameters = @(@{OUs = "Computers"; Object = "Computer" }, @{OUs = "Computers"; object = "msFVE-RecoveryInformation" })

$parameters | ForEach-Object {
    $acl = Get-Acl -Path ("ad:ou=" + $_.OUs + "," + $ou)
    $acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $SID, "GenericAll", "Allow", "Descendents", $guidmap[$_.object]  ))
    Set-Acl -Path ("ad:ou=" + $_.OUs + "," + $ou) -AclObject $acl
}

$parameters = @(@{OUs = "Computers"; Object = "Computer" })

$parameters | ForEach-Object {
    $acl = Get-Acl -Path ("ad:ou=" + $_.OUs + "," + $ou)
    $acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $SID, @("CreateChild","DeleteChild"), "Allow", $guidmap[$_.object],"Descendents"  ))
    Set-Acl -Path ("ad:ou=" + $_.OUs + "," + $ou) -AclObject $acl
}


# Modify members in Groups OU
foreach ($GroupOu in "Distribution", "GPO" , "Printers") {
    $acl = Get-Acl -Path ("ad:ou=$GroupOU,ou=groups," + $ou)
    $acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $SID, "ReadProperty, WriteProperty", "Allow", $guidmap["Member"] , "Descendents", $guidmap["Group"]  ))
    Set-Acl -Path ("ad:ou=$GroupOU,ou=groups," + $ou) -AclObject $acl
}

#Reset Passwords, unlock, enable/disable accounts for Standard Users. Modify the Description and Expiry Date.
$acl = Get-Acl -Path "ad:ou=standard Users,OU=Users,$ou"
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $SID, "ExtendedRight", "Allow", $extendedrightsmap['Reset Password']   , "Descendents", $guidmap["user"] ))
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $SID, "ReadProperty, WriteProperty", "Allow", $guidmap['lockoutTime']  , "Descendents", $guidmap["user"] ))
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $SID, "ReadProperty, WriteProperty", "Allow", $guidmap['description']  , "Descendents", $guidmap["user"] ))
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $SID, "ReadProperty, WriteProperty", "Allow", $guidmap['pwdLastSet']   , "Descendents", $guidmap["user"] ))
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $SID, "ReadProperty, WriteProperty", "Allow", $guidmap['accountExpires'], "Descendents", $guidmap["user"] ))
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $SID, "ReadProperty, WriteProperty", "Allow", $guidmap['userAccountControl'] , "Descendents", $guidmap["user"] ))
Set-Acl -Path "ad:ou=standard Users,OU=Users,$ou" -AclObject $acl

####################################################################
# Add Server admins control on the Computers OUs.

$Serveradmins = $extension + " Server admins"
$SID = (Get-ADGroup -Filter { name -eq  $Serveradmins }).sid

$parameters = @(@{OUs = "Contacts"; Object = "Contact" }, @{OUs = "Users"; Object = "User" }, @{OUs = "Resources,ou=users"; Object = "User" }, @{OUs = "Groups"; Object = "Group" }, @{OUs = "Computers"; Object = "Computer" }, @{OUs = "Computers"; object = "msFVE-RecoveryInformation" }, @{OUs = "Servers"; Object = "Computer" }, @{OUs = "Servers"; object = "msFVE-RecoveryInformation" })

$parameters | ForEach-Object {
    $acl = Get-Acl -Path ("ad:ou=" + $_.OUs + "," + $ou)
    $acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $SID, "GenericAll", "Allow", "Descendents", $guidmap[$_.object]  ))
    Set-Acl -Path ("ad:ou=" + $_.OUs + "," + $ou) -AclObject $acl
}

# Add Full control on the Test OU on everything 
$acl = Get-Acl -Path "ad:ou=test,$ou"
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $SID, "GenericAll", "Allow" ))
Set-Acl -Path  "ad:ou=test,$ou" -AclObject $acl

####################################################################
# Add Site admins control on the Computers OUs.

$SiteAdmins = $extension + " Site admins"
$SID = (Get-ADGroup -Filter { name -eq  $SiteAdmins }).sid

$parameters = @(@{OUs = "Contacts"; Object = "Contact" }, @{OUs = "Users"; Object = "User" }, @{OUs = "Groups"; Object = "Group" }, @{OUs = "Computers"; Object = "Computer" }, @{OUs = "Computers"; object = "msFVE-RecoveryInformation" }, @{OUs = "Servers"; Object = "Computer" }, @{OUs = "Servers"; object = "msFVE-RecoveryInformation" }, @{OUs = "Production,ou=Computers"; Object = "Computer" })

$parameters | ForEach-Object {
    $acl = Get-Acl -Path ("ad:ou=" + $_.OUs + "," + $ou)
    $acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $SID, "GenericAll", "Allow", "Descendents", $guidmap[$_.object]  ))
    Set-Acl -Path ("ad:ou=" + $_.OUs + "," + $ou) -AclObject $acl
}                                                                                                                             

# Add Full control on the Test OU on everything 
$acl = Get-Acl -Path "ad:ou=test,$ou"
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $SID, "GenericAll", "Allow" ))
Set-Acl -Path  "ad:ou=test,$ou" -AclObject $acl

# Create and maintains GPO objects and links to OU.  Cannot block GPO inheritance
$acl = Get-Acl -Path "ad:$ou"
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $SID, "ExtendedRight", "Allow", $extendedrightsmap['Generate Resultant Set of Policy (Logging)'] , "Descendents" ))
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $SID, "ExtendedRight", "Allow", $extendedrightsmap['Generate Resultant Set of Policy (Planning)'] , "Descendents" ))
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $SID, "ReadProperty, WriteProperty", "Allow", $guidmap['gplink'] , "Descendents" ))
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $SID, "ReadProperty, WriteProperty", "Allow", $guidmap['gPOptions'] , "Descendents" ))
Set-Acl -Path "ad:$ou" -AclObject $acl

####################################################################
# Add BU admins control on the Computers OUs.

$SiteAdmins = "KPLP BU Admins"
$SID = (Get-ADGroup -Filter { name -eq  $SiteAdmins }).sid

$parameters = @(@{OUs = "Contacts"; Object = "Contact" }, @{OUs = "Users"; Object = "User" }, @{OUs = "Groups"; Object = "Group" }, @{OUs = "Computers"; Object = "Computer" }, @{OUs = "Computers"; object = "msFVE-RecoveryInformation" }, @{OUs = "Servers"; Object = "Computer" }, @{OUs = "Servers"; object = "msFVE-RecoveryInformation" }, @{OUs = "Production,ou=Computers"; Object = "Computer" })

$parameters | ForEach-Object {
    $acl = Get-Acl -Path ("ad:ou=" + $_.OUs + "," + $ou)
    $acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $SID, "GenericAll", "Allow", "Descendents", $guidmap[$_.object]  ))
    Set-Acl -Path ("ad:ou=" + $_.OUs + "," + $ou) -AclObject $acl
}                                                                                                                             

# Add Full control on the Test OU on everything 
$acl = Get-Acl -Path "ad:ou=test,$ou"
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $SID, "GenericAll", "Allow" ))
Set-Acl -Path  "ad:ou=test,$ou" -AclObject $acl

# Create and maintains GPO objects and links to OU.  Cannot block GPO inheritance
$acl = Get-Acl -Path "ad:$ou"
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $SID, "ExtendedRight", "Allow", $extendedrightsmap['Generate Resultant Set of Policy (Logging)'] , "Descendents" ))
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $SID, "ExtendedRight", "Allow", $extendedrightsmap['Generate Resultant Set of Policy (Planning)'] , "Descendents" ))
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $SID, "ReadProperty, WriteProperty", "Allow", $guidmap['gplink'] , "Descendents" ))
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $SID, "ReadProperty, WriteProperty", "Allow", $guidmap['gPOptions'] , "Descendents" ))
Set-Acl -Path "ad:$ou" -AclObject $acl

#######################################################

# donner au groupe AD_computer_Full full control sur tous l'OU Computers et Full Volume Encryption
$SID = (Get-ADGroup AD_computer_Full).sid
$acl = Get-Acl "AD:ou=Computers,$ou" 
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $SID, "GenericAll", "Allow", "Descendents", $guidmap["computer"] ))
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $SID, "GenericAll", "Allow", "Descendents", $guidmap["msFVE-RecoveryInformation"] ))
Set-Acl -Path "AD:ou=Computers,$ou" -AclObject $acl