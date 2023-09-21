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
        [System.DirectoryServices.ActiveDirectoryRights] $adRights = [System.DirectoryServices.ActiveDirectoryRights] "CreateChild, DeleteChild",
        [Parameter(Mandatory = $False)]
        [System.Security.AccessControl.AccessControlType] $type = [System.Security.AccessControl.AccessControlType] "Allow",
        [Parameter(Mandatory = $False)]
        [System.DirectoryServices.ActiveDirectorySecurityInheritance] $inheritanceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance] "All",
        [Parameter(Mandatory = $False)]
        $objectName,
        [Parameter(Mandatory = $False)]
        $inheritedObjectName

    )
    $Group = Get-ADGroup -Filter { name -eq $group }
    $identity = [System.Security.Principal.SecurityIdentifier] $group.SID

    $ObjectTypeGUID = @{}
    $GetADObjectParameter = @{
        SearchBase = (Get-ADRootDSE).SchemaNamingContext
        LDAPFilter = '(SchemaIDGUID=*)'
        Properties = @("Name", "SchemaIDGUID")
    }
    $SchGUID = Get-ADObject @GetADObjectParameter
    Foreach ($SchemaItem in $SchGUID) {
        $ObjectTypeGUID.Add($SchemaItem.Name, [GUID]$SchemaItem.SchemaIDGUID)
    }
    $ADObjExtPar = @{
        SearchBase = "CN=Extended-Rights,$((Get-ADRootDSE).ConfigurationNamingContext)"
        LDAPFilter = '(ObjectClass=ControlAccessRight)'
        Properties = @("Name", "RightsGUID")
    }
    $SchExtGUID = Get-ADObject @ADObjExtPar
    ForEach ($SchExtItem in $SchExtGUID) {
        $ObjectTypeGUID.Add($SchExtItem.Name, [GUID]$SchExtItem.RightsGUID)
    }

    $objectguid = $ObjectTypeGUID[[guid]$objectName].Guid
    $objectguid
    $ACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $identity, $adRights, $type, $inheritanceType
}
