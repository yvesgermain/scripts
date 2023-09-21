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
        "(schemaidguid=*)" -Properties lDAPDisplayName, schemaIDGUID  -ResultSetSize $null | `
        ForEach-Object { $guidmap.add([System.GUID]$_.schemaIDGUID, $_.lDAPDisplayName ) }

    #Create a hashtable to store the GUID value of each extended right in the forest
    $extendedrightsmap = @{}
    Get-ADObject -SearchBase ($rootdse.ConfigurationNamingContext) -LDAPFilter `
        "(&(objectclass=controlAccessRight)(rightsguid=*))" -Properties displayName, rightsGuid -ResultSetSize $null | `
        ForEach-Object { try { $extendedrightsmap.add( [System.GUID]$_.rightsGuid , $_.displayName) } catch {} }

    Get-ChildItem $OuPath -Recurse:$Recurse | Where-Object {
        $_.ObjectClass -eq "organizationalUnit" } | ForEach-Object { 
        $ou = $_.name
            (Get-Acl ( "ad:" + $_.DistinguishedName)).access | Where-Object {
            $_.isinherited -eq $false } `
        | Select-Object @{name = "OU" ; e = { $ou } }, 
        identityReference, 
        ActiveDirectoryRights,
        objectType, 
        @{ name = "object Type" ; e = { if ( $_.objecttype -eq '00000000-0000-0000-0000-000000000000' ) { '00000000-0000-0000-0000-000000000000' } else { if ($_.activeDirectoryRights -eq "ExtendedRight") { $extendedrightsmap[[guid]$_.objecttype] } else { $guidmap[$_.objecttype] } } } },
        InheritedObjectType,
        @{ name = "Inherited Object Type" ; e = { if ( $_.InheritedObjectType -eq '00000000-0000-0000-0000-000000000000' ) { '00000000-0000-0000-0000-000000000000' } else { $guidmap[$_.InheritedObjectType] } } }, 
        isinherited, 
        InheritanceType, 
        AccessControlType, 
        ObjectFlags, 
        InheritanceFlags, 
        PropagationFlags 
    }
}

function inbed_group {
    $groups = $args 
    foreach ($group in $groups) {
        $space + $group
        $members = (Get-ADGroup -Identity $group -Properties members -ErrorAction SilentlyContinue).members 
        if ($members) {
            $space = $space + "  "
            foreach ($member in $members) {
                $gMembers = Get-ADObject $member -Properties sAMAccountName 
                foreach ($gmember in $gMembers) { 
                    if ($gmember.objectclass -notlike "group") { 
                        $space + $gmember.name + "`t" + $gmember.SamAccountName
                    }
                    else { inbed_group $gmember.name } 
                }
            }
        }
    }
}

Function ConvertTo-Sid ($NtAccount) { (New-Object system.security.principal.NtAccount($NTaccount)).translate([system.security.principal.securityidentifier]) }
function ConvertTo-NtAccount ($sid) { (New-Object system.security.principal.securityidentifier($sid)).translate([system.security.principal.ntaccount]) }
function Convert-BinarySid ($value) { (New-Object System.Security.Principal.SecurityIdentifier($value.objectsid.value, 0)).Value }

function Remove-Diacritics {
    param ([String]$src = [String]::Empty)
    $normalized = $src.Normalize( [Text.NormalizationForm]::FormD )
    $sb = New-Object Text.StringBuilder
    $normalized.ToCharArray() | % {
        if ( [Globalization.CharUnicodeInfo]::GetUnicodeCategory($_) -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$sb.Append($_)
        }
    }
    $sb.ToString()
}
    