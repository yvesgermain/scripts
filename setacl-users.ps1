$Server = "grsvfp01"
$UserShare = 'Users$'
function ConvertTo-NtAccount ($sid) { (New-Object system.security.principal.securityidentifier($sid)).translate([system.security.principal.ntaccount]) }

$sams = Get-ChildItem \\$server\$userShare -Directory | ForEach-Object { try { (Get-ADUser $_.name ).samaccountname } catch {} }

foreach ( $sam in $sams[2]) {
    $Sids = @("S-1-5-18", "S-1-3-0", "S-1-5-32-544")
    $filesystemrights = "FullControl"
    $InheritanceFlags = @("ContainerInherit", "ObjectInherit")
    $type = "Allow"
    $ACL = New-Object "System.Security.AccessControl.DirectorySecurity"
    $ACL.SetOwner((ConvertTo-NtAccount "S-1-5-32-544"))
    foreach ( $identity in $Sids) {
        switch ($identity) {
            "S-1-3-0" { $name = ConvertTo-NtAccount "S-1-3-0"           ; $PropagationFlags = "InheritOnly"; $filesystemrights = "FullControl" }
            "S-1-5-18" { $name = ConvertTo-NtAccount "S-1-5-18"         ; $PropagationFlags = "None" ; $filesystemrights = "FullControl" }
            "S-1-5-32-544" { $name = ConvertTo-NtAccount "S-1-5-32-544" ; $PropagationFlags = "None" ; $filesystemrights = "FullControl" }
        }
        $fileSystemAccessRuleArgumentList = $Name, $filesystemrights, $InheritanceFlags, $PropagationFlags, $type   
        $fileSystemAccessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $fileSystemAccessRuleArgumentList
        $ACL.AddAccessRule($fileSystemAccessRule )
    }
    $ACL.SetAccessRuleProtection($true, $true)
    $MOD = $ACL
    $identity = "krugerinc\$sam"
    $identity
    $filesystemrights = @("Modify", "Synchronize")
    $InheritanceFlags = @("ContainerInherit", "ObjectInherit")
    $PropagationFlags = "None"
    $type = "Allow"
    $fileSystemAccessRuleArgumentList = $identity, $filesystemrights, $InheritanceFlags, $PropagationFlags, $type   
    $fileSystemAccessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $fileSystemAccessRuleArgumentList
    $mod.SetAccessRule($fileSystemAccessRule)
    $mod.SetAccessRuleProtection($true, $true)
    $mod.access | Format-Table
    Set-Acl \\$server\$UserShare\$sam -AclObject $mod -WhatIf
}

