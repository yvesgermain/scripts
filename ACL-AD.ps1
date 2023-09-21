# https://learn.microsoft.com/en-us/archive/blogs/joec/active-directory-delegation-via-powershell

Import-Module ActiveDirectory
#Bring up an Active Directory command prompt so we can use this later on in the script
Set-Location ad:
#Get a reference to the RootDSE of the current domain
$rootdse = Get-ADRootDSE
#Get a reference to the current domain
$domain = Get-ADDomain

#Create a hashtable to store the GUID value of each schema class and attribute
$guidmap = @{}
Get-ADObject -SearchBase ($rootdse.SchemaNamingContext) -LDAPFilter `
    "(schemaidguid=*)" -Properties lDAPDisplayName, schemaIDGUID | `
    ForEach-Object { $guidmap[$_.lDAPDisplayName] = [System.GUID]$_.schemaIDGUID }

#Create a hashtable to store the GUID value of each extended right in the forest
$extendedrightsmap = @{}
Get-ADObject -SearchBase ($rootdse.ConfigurationNamingContext) -LDAPFilter `
    "(&(objectclass=controlAccessRight)(rightsguid=*))" -Properties displayName, rightsGuid | `
    ForEach-Object { $extendedrightsmap[$_.displayName] = [System.GUID]$_.rightsGuid }

#Get a reference to the OU we want to delegate
$ou = Get-ADOrganizationalUnit -Identity ("OU=Contoso Users," + $domain.DistinguishedName)
#Get the SID values of each group we wish to delegate access to
$p = New-Object System.Security.Principal.SecurityIdentifier (Get-ADGroup "Contoso Provisioning Admins").SID
$s = New-Object System.Security.Principal.SecurityIdentifier (Get-ADGroup "Contoso Service Desk").SID
#Get a copy of the current DACL on the OU
$acl = Get-Acl -Path ($ou.DistinguishedName)
#Create an Access Control Entry for new permission we wish to add
#Allow the group to write all properties of descendent user objects
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule `
            $p, "WriteProperty", "Allow", "Descendents", $guidmap["user"]))
#Allow the group to create and delete user objects in the OU and all sub-OUs that may get created
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule `
            $p, "CreateChild,DeleteChild", "Allow", $guidmap["user"], "All"))
#Allow the group to reset user passwords on all descendent user objects
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule `
            $p, "ExtendedRight", "Allow", $extendedrightsmap["Reset Password"], "Descendents", $guidmap["user"]))
#Allow the Service Desk group to also reset passwords on all descendent user objects
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule `
            $s, "ExtendedRight", "Allow", $extendedrightsmap["Reset Password"], "Descendents", $guidmap["user"]))
#Re-apply the modified DACL to the OU
Set-Acl -AclObject $acl -Path ("AD:\" + ($ou.DistinguishedName))

Get-ChildItem "ad:OU=Sherbrooke,OU=Kruger Products,DC=kruger,DC=com" -Recurse | Where-Object {
    $_.ObjectClass -eq "organizationalUnit" } | ForEach-Object { 
    $ou = $_.name
        (Get-Acl ( "ad:" + $_.DistinguishedName)).access | Where-Object {
        $_.isinherited -eq $false } `
    | Select-Object @{name = "OU" ; e = { $ou } }, 
    identityReference, 
    ActiveDirectoryRights, 
    @{ name = "object Type" ; e = { if ( $_.objecttype -eq '00000000-0000-0000-0000-000000000000' ) { '00000000-0000-0000-0000-000000000000' } else { $extendedrightsmap[$_.objecttype] } } },
    @{ name = "Inherited Object Type" ; e = { $guidmap[$_.InheritedObjectType] } }, 
    isinherited, 
    InheritanceType, 
    AccessControlType, 
    ObjectFlags, 
    InheritanceFlags, 
    PropagationFlags 
}

function Get-AdAcl {
    param( $OuPath, [switch] $Recurse )
    Import-Module ActiveDirectory
    #Bring up an Active Directory command prompt so we can use this later on in the script
    # Set-Location ad:
    #Get a reference to the RootDSE of the current domain
    $rootdse = Get-ADRootDSE
    #Create a hashtable to store the GUID value of each schema class and attribute
    $guidmap = @{}
    Get-ADObject -SearchBase ($rootdse.SchemaNamingContext) -LDAPFilter `
        "(schemaidguid=*)" -Properties lDAPDisplayName, schemaIDGUID  -ResultSetSize $null| `
        ForEach-Object { $guidmap.add([System.GUID]$_.schemaIDGUID, $_.lDAPDisplayName ) }

    #Create a hashtable to store the GUID value of each extended right in the forest
    $extendedrightsmap = @{}
    Get-ADObject -SearchBase ($rootdse.ConfigurationNamingContext) -LDAPFilter `
        "(&(objectclass=controlAccessRight)(rightsguid=*))" -Properties displayName, rightsGuid -ResultSetSize $null | `
        ForEach-Object { try{$extendedrightsmap.add( [System.GUID]$_.rightsGuid , $_.displayName)} catch {} }

    Get-ChildItem $OuPath -Recurse:$Recurse | Where-Object {
        $_.ObjectClass -eq "organizationalUnit" } | ForEach-Object { 
        $ou = $_.name
            (Get-Acl ( "ad:" + $_.DistinguishedName)).access | Where-Object {
            $_.isinherited -eq $false } `
        | Select-Object @{name = "OU" ; e = { $ou } }, 
        identityReference, 
        ActiveDirectoryRights,
        objectType, 
        @{ name = "object Type" ; e = { if ( $_.objecttype -eq '00000000-0000-0000-0000-000000000000' ) { '00000000-0000-0000-0000-000000000000' } else {if ($_.activeDirectoryRights -eq "ExtendedRight") {$extendedrightsmap[[guid]$_.objecttype]} else { $guidmap[$_.objecttype]}}}},
        InheritedObjectType,
        @{ name = "Inherited Object Type" ; e = { if ( $_.InheritedObjectType -eq '00000000-0000-0000-0000-000000000000' ) { '00000000-0000-0000-0000-000000000000' } else { $guidmap[$_.InheritedObjectType]}}}, 
        isinherited, 
        InheritanceType, 
        AccessControlType, 
        ObjectFlags, 
        InheritanceFlags, 
        PropagationFlags 
    }
}
