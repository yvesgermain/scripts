$Server = "HOLT008238"
#$server = "GRSVFP01"
#$folder = 'groups\Serveur Richelieu (R)\Aim Project'
#$folder = 'groups\Serveur Richelieu (R)\Qualité'
#$folder = 'groups\Serveur Richelieu (R)\Commun'
$folder = 'c$\test\Serveur Richelieu (R)\Commun'
#$folder = 'groups\Serveur Richelieu (R)\Logistique'
#$folder = 'groups\Serveur Richelieu (R)\Management'
#$folder = 'groups\Serveur Richelieu (R)\Ingénierie'
function ConvertTo-NtAccount ($sid) { (New-Object system.security.principal.securityidentifier($sid)).translate([system.security.principal.ntaccount]) }

# $sams = @("GRSVFP01_AimProject-RW", "GRSVFP01_AimProject-RO")
# $sams = @(@{"Group" = "GRSVFP01_AimProject-RW"; "Perms" =  @("Modify", "Synchronize")} , @{"Group" = "GRSVFP01_AimProject-RO"; "Perms" = @("ReadAndExecute", "Synchronize")})
# $sams = @("GRSVFP01_Qualite-RW", "GRSVFP01_Qualite-RO")
# $sams = @(@{"Group" = "GRSVFP01_Qualite-RW"; "Perms" =  @("Modify", "Synchronize")} , @{"Group" = "GRSVFP01_Qualite-RO"; "Perms" = @("ReadAndExecute", "Synchronize")})
$sams = @(@{"Group" = "GRSVFP01_Commun-RW"; "Perms" =  @("Modify", "Synchronize")} , @{"Group" = "GRSVFP01_Commun-RO"; "Perms" = @("ReadAndExecute", "Synchronize")})
# $sams = @(@{"Group" = "GRSVFP01_ingenierie-RW"; "Perms" =  @("Modify", "Synchronize")} , @{"Group" = "GRSVFP01_Ingenierie-RO"; "Perms" = @("ReadAndExecute", "Synchronize")})
# $sams = @(@{"Group" = "GRSVFP01_Management-RW"; "Perms" =  @("Modify", "Synchronize")} , @{"Group" = "GRSVFP01_Management-RO"; "Perms" = @("ReadAndExecute", "Synchronize")})
# $sams = @(@{"Group" = "GRSVFP01_Logistique-RW"; "Perms" =  @("Modify", "Synchronize")} , @{"Group" = "GRSVFP01_Logistique-RO"; "Perms" = @("ReadAndExecute", "Synchronize")})

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
# $ACL.SetAccessRuleProtection($true, $true)
$MOD = $ACL
foreach ( $sam in $sams) {
    $identity = ("KRUGERINC\" + $sam['group'])
    $identity =  [System.Security.Principal.NTAccount]::new( $identity)
    # if ($sam -like "*RW") { $filesystemrights = @("Modify", "Synchronize") } else { $filesystemrights = @("ReadAndExecute", "Synchronize") }
    $filesystemrights = $sam["perms"]
    $InheritanceFlags = @("ContainerInherit", "ObjectInherit")
    $PropagationFlags = "None"
    $type = "Allow"
    $fileSystemAccessRuleArgumentList = $identity, $filesystemrights, $InheritanceFlags, $PropagationFlags, $type   
    $fileSystemAccessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $fileSystemAccessRuleArgumentList
    $mod.SetAccessRule($fileSystemAccessRule)
    $mod.SetAccessRuleProtection($false, $false)
    $mod.access | Format-Table
}

Get-ChildItem \\$server\$folder -Directory -Recurse| ForEach-Object { Set-Acl $_.fullname -AclObject $mod -whatif}

