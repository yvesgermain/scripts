Import-Module ActiveDirectory
$scriptBlock = {  
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters) 
    (Get-ADObject -SearchBase (Get-ADRootDSE).SchemaNamingContext -LDAPFilter '(SchemaIDGUID=*)' ).name | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object { "'$_'" } 
}
$Extendedscriptblock = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters) 
    (Get-ADObject -SearchBase "CN=Extended-Rights,$((Get-ADRootDSE).ConfigurationNamingContext)" -LDAPFilter '(ObjectClass=ControlAccessRight)' ).name | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object { "'$_'" } 
}

Register-ArgumentCompleter -CommandName get-MYacl -ParameterName objectName -ScriptBlock $scriptBlock
Register-ArgumentCompleter -CommandName get-MYacl -ParameterName inheritedObjectName -ScriptBlock $Extendedscriptblock
function Get-MYacl {
    param (
        # Create a new access control entry to allow access to the OU
        [Parameter(Mandatory = $true)]
        $group, 
        [Parameter(Mandatory = $true)]
        [System.DirectoryServices.ActiveDirectoryRights] [array] $adRights = [System.DirectoryServices.ActiveDirectoryRights] "CreateChild, DeleteChild",
        [Parameter(Mandatory = $False)]
        [System.Security.AccessControl.AccessControlType] $type = [System.Security.AccessControl.AccessControlType] "Allow",
        [Parameter(Mandatory = $False)]
        [System.DirectoryServices.ActiveDirectorySecurityInheritance] $inheritanceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance] "All",
        [Parameter(Mandatory = $False)]
        $objectName,
        [Parameter(Mandatory = $False)]
        $inheritedObjectName,
        [Parameter(Mandatory = $False)]
        [switch] $ExtendedRight

    )
    $group = Get-ADGroup -Filter { name -eq $group }
     if ( $null -eq $group) {write-warning "Group $group doesn't exist. Looser!" ; break}
    $identity = [System.Security.Principal.SecurityIdentifier] $group.SID

    # https://learn.microsoft.com/en-us/archive/blogs/joec/active-directory-delegation-via-powershell

    Import-Module ActiveDirectory
    #Bring up an Active Directory command prompt so we can use this later on in the script
    Set-Location ad:
    #Get a reference to the RootDSE of the current domain
    $rootdse = Get-ADRootDSE
    #Get a reference to the current domain
    $domain = Get-ADDomain

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

    $objectguid = $ObjectTypeGUID[[guid]$objectName].Guid
    $objectguid
    $ACE = New-Object [System.DirectoryServices.ActiveDirectoryAccessRule] $identity, $adRights, $type, $inheritanceType

    #Get a reference to the OU we want to delegate
$ou = Get-ADOrganizationalUnit -Identity ("OU=Contoso Users,"+$domain.DistinguishedName)
#Get the SID values of each group we wish to delegate access to
$p = New-Object System.Security.Principal.SecurityIdentifier (Get-ADGroup "Contoso Provisioning Admins").SID
$s = New-Object System.Security.Principal.SecurityIdentifier (Get-ADGroup "Contoso Service Desk").SID
#Get a copy of the current DACL on the OU
$acl = Get-ACL -Path ($ou.DistinguishedName)
#Create an Access Control Entry for new permission we wish to add
#Allow the group to write all properties of descendent user objects
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule `
$p,"WriteProperty","Allow","Descendents",$guidmap["user"]))
#Allow the group to create and delete user objects in the OU and all sub-OUs that may get created
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule `
$p,"CreateChild,DeleteChild","Allow",$guidmap["user"],"All"))
#Allow the group to reset user passwords on all descendent user objects
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule `
$p,"ExtendedRight","Allow",$extendedrightsmap["Reset Password"],"Descendents",$guidmap["user"]))
#Allow the Service Desk group to also reset passwords on all descendent user objects
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule `
$s,"ExtendedRight","Allow",$extendedrightsmap["Reset Password"],"Descendents",$guidmap["user"]))
#Re-apply the modified DACL to the OU
Set-ACL -ACLObject $acl -Path ("AD:\"+($ou.DistinguishedName))
}
