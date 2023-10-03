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
$BaseOU = "OU=Test",
"OU=Servers",
"OU=Groups",
"OU=Contacts",
"OU=Computers",
"OU=TS Users,OU=Users",
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

if (!(Get-ADOrganizationalUnit -Identity $OU)) {
    New-ADOrganizationalUnit -DisplayName $location -Name $location -Description $OuDescription
}

$BaseOU | ForEach-Object {
    if (!(Get-ADOrganizationalUnit -Identity "$_,$OU")) {
        $NewOu = $_.split(",")[0].split("=")[1]
        $OUPath = "$_,$OU".split("," ).split("=")[1]
        New-ADOrganizationalUnit -DisplayName $NewOu -Name $NewOu -Path $OUPath
    }
}

Import-Module ActiveDirectory
# Bring up an Active Directory command prompt so we can use this later on in the script
Set-Location ad:
$ACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $identity, $adRights, $type, $inheritanceType

# define Function
function convertto-sid param($NtAccount) (New-Object system.security.principal.NtAccount($NTaccount)).translate([system.security.principal.securityidentifier])

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

# Add computer's Self right to ms-Mcs-AdmPwd and ms-Mcs-AdmPwdExpirationTime on the computer object
# SID for AUTORITE NT\SELF
$self = convertto-sid 'AUTORITE NT\SELF'

$Paths2OU = "ad:OU=Servers,$OU", "ad:OU=Computers,$OU"

foreach ($Path2OU in $Paths2OU) {
    $acl = Get-Acl -Path "ad:OU=Servers,$OU"
    $acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $Self, "ExtendedRight", "Allow", $guidmap["ms-Mcs-AdmPwd"], "Descendents", $guidmap["Computer"]  ))
    $acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $Self, "ExtendedRight", "Allow", $guidmap["ms-Mcs-AdmPwdExpirationTime"], "Descendents", $guidmap["Computer"]  ))
}

# Add Account admins full control on the Users, Contacts and Groups OUs.

$AccountAdmins = $extension + " Account admins"
$SID = (Get-ADGroup -Filter { name -eq  $AccountAdmins }).sid

$parameters = @(@{OUs="Contacts"; Object= "Contact"},@{OUs="Users"; Object="User"}, @{OUs="Groups"; Object="Group"})

$parameters | ForEach-Object {
    $acl = Get-Acl -Path ("ad:ou=" + $_.OUs + "," + $ou)
    $acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $SID, "GenericAll", "Allow", "Descendents", $guidmap[$_.object]  ))
    Set-Acl -Path ("ad:ou=" + $_.OUs + "," + $ou) -AclObject $acl
}

# Add Production tech control on the Computer\Production OUs.

$ProductionTech = $extension + " Production Techs"
$SID = (Get-ADGroup -Filter { name -eq  $ProductionTech }).sid

$parameters = @(@{OUs="Production,ou=Computers"; Object= "Computer"})

$parameters | ForEach-Object {
    $acl = Get-Acl -Path ("ad:ou=" + $_.OUs + "," + $ou)
    $acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $SID, "GenericAll", "Allow", "Descendents", $guidmap[$_.object]  ))
    Set-Acl -Path ("ad:ou=" + $_.OUs + "," + $ou) -AclObject $acl
}

# Add Site techs control on the Computers OUs.

$SiteTech = $extension + " Site Techs"
$SID = (Get-ADGroup -Filter { name -eq  $SiteTech }).sid

$parameters = @(@{OUs="Computers"; Object= "Computer"}, @{OUs="Computers"; object = "msFVE-RecoveryInformation"})

$parameters | ForEach-Object {
    $acl = Get-Acl -Path ("ad:ou=" + $_.OUs + "," + $ou)
    $acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $SID, "GenericAll", "Allow", "Descendents", $guidmap[$_.object]  ))
    Set-Acl -Path ("ad:ou=" + $_.OUs + "," + $ou) -AclObject $acl
}

# Add Server admins control on the Computers OUs.

$Serveradmins = $extension + " Server admins"
$SID = (Get-ADGroup -Filter { name -eq  $Serveradmins }).sid

$parameters = @(@{OUs="Contacts"; Object= "Contact"},@{OUs="Users"; Object="User"}, @{OUs="Groups"; Object="Group"},@{OUs="Computers"; Object= "Computer"}, @{OUs="Computers"; object = "msFVE-RecoveryInformation"},@{OUs="Servers"; Object= "Computer"}, @{OUs="Servers"; object = "msFVE-RecoveryInformation"})

$parameters | ForEach-Object {
    $acl = Get-Acl -Path ("ad:ou=" + $_.OUs + "," + $ou)
    $acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $SID, "GenericAll", "Allow", "Descendents", $guidmap[$_.object]  ))
    Set-Acl -Path ("ad:ou=" + $_.OUs + "," + $ou) -AclObject $acl
}
# Add Full control on the Test OU on everything 
$acl = Get-Acl -Path "ad:ou=test,$ou"
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $SID, "GenericAll", "Allow" ))
Set-Acl -Path  "ad:ou=test,$ou" -AclObject $acl

# Add Site admins control on the Computers OUs.

$SiteAdmins = $extension + " Site admins"
$SID = (Get-ADGroup -Filter { name -eq  $SiteAdmins }).sid

$parameters = @(@{OUs="Contacts"; Object= "Contact"},@{OUs="Users"; Object="User"}, @{OUs="Groups"; Object="Group"},@{OUs="Computers"; Object= "Computer"}, @{OUs="Computers"; object = "msFVE-RecoveryInformation"},@{OUs="Servers"; Object= "Computer"}, @{OUs="Servers"; object = "msFVE-RecoveryInformation"},@{OUs="Production,ou=Computers"; Object= "Computer"})

$parameters | ForEach-Object {
    $acl = Get-Acl -Path ("ad:ou=" + $_.OUs + "," + $ou)
    $acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $SID, "GenericAll", "Allow", "Descendents", $guidmap[$_.object]  ))
    Set-Acl -Path ("ad:ou=" + $_.OUs + "," + $ou) -AclObject $acl
}                                                                                                                             

# Add Full control on the Test OU on everything 
$acl = Get-Acl -Path "ad:ou=test,$ou"
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $SID, "GenericAll", "Allow" ))
Set-Acl -Path  "ad:ou=test,$ou" -AclObject $acl


# Add BU admins control on the Computers OUs.

$SiteAdmins = "KPLP BU Admins"
$SID = (Get-ADGroup -Filter { name -eq  $SiteAdmins }).sid

$parameters = @(@{OUs="Contacts"; Object= "Contact"},@{OUs="Users"; Object="User"}, @{OUs="Groups"; Object="Group"},@{OUs="Computers"; Object= "Computer"}, @{OUs="Computers"; object = "msFVE-RecoveryInformation"},@{OUs="Servers"; Object= "Computer"}, @{OUs="Servers"; object = "msFVE-RecoveryInformation"},@{OUs="Production,ou=Computers"; Object= "Computer"})

$parameters | ForEach-Object {
    $acl = Get-Acl -Path ("ad:ou=" + $_.OUs + "," + $ou)
    $acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $SID, "GenericAll", "Allow", "Descendents", $guidmap[$_.object]  ))
    Set-Acl -Path ("ad:ou=" + $_.OUs + "," + $ou) -AclObject $acl
}                                                                                                                             

# Add Full control on the Test OU on everything 
$acl = Get-Acl -Path "ad:ou=test,$ou"
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $SID, "GenericAll", "Allow" ))
Set-Acl -Path  "ad:ou=test,$ou" -AclObject $acl
