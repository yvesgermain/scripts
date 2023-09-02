Add-Type -AssemblyName System.DirectoryServices.AccountManagement
$ctype = [System.DirectoryServices.AccountManagement.ContextType]::Machine
$idtype = [System.DirectoryServices.AccountManagement.IdentityType]::SamAccountName

$servers = (Get-ADComputer -Filter { OperatingSystem -like "Windows server*" -and  OperatingSystem -notlike "Windows server 2003*" } -Properties OperatingSystem ).name
$servers | ForEach-Object -Parallel { 
    $server = $_
    if (Test-Connection -TargetName $server -Ping -Count 1 -Quiet) {
        $ctype = [System.DirectoryServices.AccountManagement.ContextType]::Machine
        $idtype = [System.DirectoryServices.AccountManagement.IdentityType]::SamAccountName
        $context = New-Object -TypeName System.DirectoryServices.AccountManagement.PrincipalContext -ArgumentList $ctype, $server
        $group = [System.DirectoryServices.AccountManagement.GroupPrincipal]::FindByIdentity($context, $idtype, 'Administrators')
        # $group.Members | Select-Object @{ Name= "Server" ;e = {$server}}, @{N = "Domain"; E = { $_.Context.Name + "\" + $_.samaccountname } }, name, samaccountname, UserPrincipalName, IsSecurityGroup
        Try { $group.Members | Select-Object @{ Name = "Server" ; e = { $server } }, @{N = "IdentityReference"; E = { $_.Context.Name + "\" + $_.samaccountname } }, @{name = "FileSystemRights" ; e = { "Administrators" } } } catch [System.DirectoryServices.AccountManagement.PrincipalOperationException] { $server }
    } 
}| Format-Table

$adsi = [adsi]"WinNT://$env:COMPUTERNAME"
$adminGroup = $adsi.Children.Find("Administrators", "Group")
foreach ($mem in $adminGroup.psbase.Invoke("members"))
{
    $type = $mem.GetType()
    $name = $type.InvokeMember("Name", "GetProperty", $null, $mem, $null) # Not sure what this equals if there's no account
    [byte[]]$sidBytes = $type.InvokeMember("ObjectSid", "GetProperty", $null, $mem, $null)
    $sid = New-Object System.Security.Principal.SecurityIdentifier($sidBytes, 0)
    
    # Maybe try translating it?
    try
    {
        $ntAcct = $sid.Translate([System.Security.Principal.NTAccount])
    }
    catch [System.Management.Automation.MethodInvocationException]
    {
        # Couldn't translate, could be a candidate for removal
        Write-Warning "I would remove $($sid.Value)..."
        # $adminGroup.Remove(("WinNT://$sid")) # Actual Removal
        # remove-localgroup -name administrators -member  $sid.value
    }
}