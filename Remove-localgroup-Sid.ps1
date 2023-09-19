Add-Type -AssemblyName System.DirectoryServices.AccountManagement
$date = (Get-Date).addmonths(-3) 
$servers = (Get-ADComputer -Filter { enabled -eq $true -and lastlogondate -gt $date -and OperatingSystem -like "Windows server*" -and  OperatingSystem -notlike "Windows server 2003*" } -Properties OperatingSystem, lastlogondate ).name
#$localGroup = "Administrators"
$localGroup = "Remote desktop Users"
$ctype = [System.DirectoryServices.AccountManagement.ContextType]::Machine
$idtype = [System.DirectoryServices.AccountManagement.IdentityType]::SamAccountName
if ($localGroup -eq "Administrators") { $servers = $servers | Where-Object { $_ -notin (Get-ADDomainController -Filter * ).name } }
$servers | ForEach-Object -Parallel { 
    $server = $_
    if (Test-Connection -TargetName $server -Ping -Count 1 -Quiet) {
        $context = New-Object -TypeName System.DirectoryServices.AccountManagement.PrincipalContext -ArgumentList $Using:ctype, $server
        $group = [System.DirectoryServices.AccountManagement.GroupPrincipal]::FindByIdentity($context, $Using:idtype, $Using:localGroup)
        # $group.Members | Select-Object @{ Name= "Server" ;e = {$server}}, @{N = "Domain"; E = { $_.Context.Name + "\" + $_.samaccountname } }, name, samaccountname, UserPrincipalName, IsSecurityGroup
        Try { $group.Members | Select-Object @{ Name = "Server" ; e = { $server } }, @{N = "IdentityReference"; E = { $_.Context.Name + "\" + $_.samaccountname } }, @{name = "FileSystemRights" ; e = { "Groupe\$Using:localGroup" } } } catch [System.DirectoryServices.AccountManagement.PrincipalOperationException] { $server }
    } 
}

$groupName = "Administrators"
foreach ( $Server in $servers ) {
    Invoke-Command -ComputerName $server -ArgumentList $server, $groupName -ScriptBlock {
        param( $server, $groupName)
        $server
        $adsi = [adsi]"WinNT://$server"
        $adminGroup = $adsi.Children.Find($groupName, "Group")
        foreach ($mem in $adminGroup.psbase.Invoke("members")) {
            $type = $mem.GetType()
            $name = $type.InvokeMember("Name", "GetProperty", $null, $mem, $null) # Not sure what this equals if there's no account
            [byte[]]$sidBytes = $type.InvokeMember("ObjectSid", "GetProperty", $null, $mem, $null)
            $sid = New-Object System.Security.Principal.SecurityIdentifier($sidBytes, 0)
            "This is the name : " + $name
            "This is the SID : " + $Sid.Value 
            # Maybe try translating it?
            try {
                $ntAcct = $sid.Translate([System.Security.Principal.NTAccount])
            }
            catch [System.Management.Automation.MethodInvocationException] {
                # Couldn't translate, could be a candidate for removal
                Write-Warning "I would remove $($sid.Value)..."
                # $adminGroup.Remove(("WinNT://$sid")) # Actual Removal
                # remove-localgroup -name administrators -member  $sid.value
            }
        }
    }
}
