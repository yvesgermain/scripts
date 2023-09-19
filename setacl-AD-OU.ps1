# https://social.technet.microsoft.com/Forums/Lync/en-US/df3bfd33-c070-4a9c-be98-c4da6e591a0a/forum-faq-using-powershell-to-assign-permissions-on-active-directory-objects?forum=winserverpowershell
# You can use the script below to get and assign Full Control permission to a computer object on an OU:
import-module ActiveDirectory

$ObjectTypeGUID = @{}

$GetADObjectParameter=@{
    SearchBase=(Get-ADRootDSE).SchemaNamingContext
    LDAPFilter='(SchemaIDGUID=*)'
    Properties=@("Name", "SchemaIDGUID")
}

$SchGUID=Get-ADObject @GetADObjectParameter
    Foreach ($SchemaItem in $SchGUID){
    $ObjectTypeGUID.Add([GUID]$SchemaItem.SchemaIDGUID,$SchemaItem.Name)
}

$ADObjExtPar=@{
    SearchBase="CN=Extended-Rights,$((Get-ADRootDSE).ConfigurationNamingContext)"
    LDAPFilter='(ObjectClass=ControlAccessRight)'
    Properties=@("Name", "RightsGUID")
}

 
$SchExtGUID=Get-ADObject @ADObjExtPar
    ForEach($SchExtItem in $SchExtGUID){
    $ObjectTypeGUID.Add([GUID]$SchExtItem.RightsGUID,$SchExtItem.Name)
}


$acl = Get-Acl AD:\'ou=tu,ou=disabledUsers,DC=kruger,DC=com'

$acl.access #to get access right of the OU

$group = Get-ADGroup "TU site admins"

$sid = [System.Security.Principal.SecurityIdentifier] $group.SID

# Create a new access control entry to allow access to the OU

$identity = [System.Security.Principal.IdentityReference] $SID

$adRights = [System.DirectoryServices.ActiveDirectoryRights] "CreateChild, DeleteChild"

$type = [System.Security.AccessControl.AccessControlType] "Allow"

$inheritanceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance] "All"

$ACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $identity, $adRights, $type, $inheritanceType

# Add the ACE to the ACL, then set the ACL to save the changes

$acl.AddAccessRule($ace)

Set-Acl -AclObject $acl "ad:OU=xxx,DC=com"
############################################
$root = "DC=kruger,dc=com"
$sites = "SG"
$ObjectType = "Computer"
switch ( $objectType) {
    "OU"	    { $objectClass = "bf967aa5-0de6-11d0-a285-00aa003049e2" }
    "Computer"	{ $objectClass = "bf967a86-0de6-11d0-a285-00aa003049e2" ; $root = "ou=DisabledComputers,DC=kruger,DC=com"}
    "User"	    { $objectClass = "bf967aba-0de6-11d0-a285-00aa003049e2" ; $root = "ou=DisabledUsers,DC=kruger,DC=com" }
    "Groups"	{ $objectClass = "bf967a9c-0de6-11d0-a285-00aa003049e2" }
    "Contacts"	{ $objectClass = "5cb41ed0-0e4c-11d0-a286-00aa003049e2" }
}

$type = [System.Security.AccessControl.AccessControlType] "Allow"
$objectguid = New-Object Guid $objectClass # is the rightsGuid for the Object
$inheritedobjectguid = New-Object Guid 00000000-0000-0000-0000-000000000000
$adRights = [System.DirectoryServices.ActiveDirectoryRights] @("CreateChild", "DeleteChild")
$inheritanceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance] "All"

Foreach ($site in $sites) {   

    $ou = "AD:\ou=$site,$root"
    $group = Get-ADGroup "$site site admins"

    $acl = Get-Acl -Path $ou

    $sid = New-Object System.Security.Principal.SecurityIdentifier $group.SID
    $identity = [System.Security.Principal.IdentityReference] $SID

    $ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $identity, $adRights, $type, $objectGuid, $inheritanceType, $inheritedobjectguid
    $acl.AddAccessRule($ace)
    # Let's not reapply the security if $ACE = $ACL.  Have to convert IdentityReference from SID to Text and compare each properties in the Members variable
    # $members = $acl.access | Where-Object { $_.identityreference -eq "krugerinc\sg site admins" } | Get-Member -MemberType Properties | ForEach-Object { $_.name }
    # $results = $acl.access | Where-Object { $_.identityreference -eq ("KRUGERINC\" + $group.name) } | ForEach-Object { 
    #     $output = $_; 
    #     $members | ForEach-Object { if ($_ -eq "Identityreference") { $ace.IdentityReference.Translate([system.security.principal.ntaccount]).value -eq $Output.$_ } else { $ace.$_ -eq $output.$_ } } 
    # }
    # if ($false -in $results) {
    #     Set-Acl -AclObject $acl -Path $ou -Verbose
    # }
    Set-Acl -AclObject $acl -Path $ou -Verbose
}