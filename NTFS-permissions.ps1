Import-Module activedirectory 
$servers = (Get-ADComputer -Filter { OperatingSystem -like "Windows server*" -and  OperatingSystem -notlike "Windows server 2003*" } -Properties OperatingSystem ).name
foreach ( $server in $servers) {
    if (Test-WSMan $server -ErrorAction SilentlyContinue) {
        New-Variable -Name ("PPS" + $server) -Value (New-PSSession -ComputerName $server)
        Invoke-Command -Session $(Get-Variable "PPS$server").Value -ScriptBlock {
            $server = HOSTNAME.EXE
            if (!( Test-Path C:\temp\NTFS )) { mkdir C:\temp\NTFS }
            $drives = gwmi Win32_LogicalDisk | Where-Object { $_.drivetype -like "3" } | ForEach-Object { $_.DeviceID }
            foreach ( $drive in $drives ) {
                Start-Job -Name ($server + "-" + $drive.replace(":", "")) -ArgumentList $drive, $server -ScriptBlock {
                    param($Drive, $server)
                    function ACLFunction {
                        param($folder, $server)
                        # $server = HOSTNAME.EXE
                        Get-Acl $folder | ForEach-Object {
                            $access = $_.Access
                            $result = $access | Where-Object { 
                            $_.isinherited -like $false } | Select-Object  @{name = "Server"; e = { $Server }},
                            @{name = "Folder"; e = { $folder } },
                            IdentityReference,
                            filesystemrights,
                            AccessControlType,
                            PropagationFlags,
                            IsInherited,
                            InheritanceFlags
                            return $result
                        }
                    }
                    # $server = HOSTNAME.EXE
                    $drv = $drive.replace(":", "")
                    $drive = ($drive + "\")
                    "Doing drive $drive"
                    $res = (Get-Acl $drive).access | Select-Object  @{name = "Server"; e = { $Server } }, @{name = "Folder"; e = { $Drive }},*
                    $p = "C:\temp\ntfs\" + $server + "-" + $drv + ".csv"
                    $res | Export-Csv -Path $p -NoTypeInformation -Force
                    # if (Test-Path $p) { Remove-Item $p }
                    Get-ChildItem $drive -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.PSIsContainer -eq $true } | ForEach-Object {
                        $folder = $_.fullname
                        ACLFunction -Folder $folder -server $server | Export-Csv -Path $p -NoTypeInformation -Append
                    }
                    # $res + $acl | Export-Csv -Path $p -NoTypeInformation
                }
            }
        }
    }
}

Set-Location "C:\Program Files\MongoDB\Tools\100\bin"
$servers |ForEach-Object -Parallel { Get-ChildItem ("\\" + $_ + "\c$\temp\ntfs\") |ForEach-Object {$full = $_.fullname; .\mongoimport.exe mongodb://localhost:27017 /db:ACL /collection:Servers /file:$full /type:csv /headerline}}

#  Scan AD

Start-Job -Name AD -ScriptBlock {
    Import-Module ActiveDirectory
    Set-Location AD:\"dc=kruger,dc=com"
    Get-ChildItem -Recurse | ForEach-Object {
        $DN = $_.DistinguishedName 
        $access = (Get-Acl $_.pspath ).access | Where-Object { $_.IsInherited -like $false } 
        if ($access -notlike "") {
            $access | Select-Object  @{name = "Server" ; e = { "AD" } }, @{name = "Folder" ; e = { $DN } }, IdentityReference, ActiveDirectoryRights, AccessControlType, PropagationFlags, IsInherited, InheritanceFlags
        }
    } | Export-Csv -Path c:\users\hoygermainadm\Documents\ad\ad.txt -NoTypeInformation
} 

C:\Program Files\MongoDB\Tools\100\bin\mongoimport.exe mongodb://localhost:27017 /db:ACL /collection:Servers /file:c:\users\hoygermainadm\Documents\ad\ad.txt /type:csv /headerline

[xml] $gpo = get-gporeport -all -ReportType xml

$all = $gpo.gpos.gpo | ForEach-Object {$name = $_.name; $_.securitydescriptor.Permissions.TrusteePermissions | Select-Object @{name = "Server" ; e= {"GPO"}}, @{name = "Folder" ;e = {$Name}}, @{ name = "IdentityReference";e = {$_.trustee.name."#text"}}, @{Name = "FileSystemRights";e = { $_.standard.GPOGroupedAccessEnum}}}
add-mdbcdata -InputObject $all
$all =  $gpo.gpos.gpo |foreach-object {$name = $_.name; $_.User.ExtensionData.extension.ShortcutSettings.Shortcut | ForEach-Object {$object = $_.name; $_.filters.filtergroup | Select-Object @{name = "Server" ;e = {"GPO"}}, @{name = "Folder" ;e ={$name + "\" + $object}}, @{name = "IdentityReference" ;e = {$x = $_.name.split('\'); $x[0].toUpper() + '\' + $x[1]}}}}
$all += $gpo.gpos.gpo |foreach-object {$name = $_.name; $_.User.ExtensionData.extension.Printers.sharedPrinter | ForEach-Object {$object = $_.name; $_.filters.filtergroup | Select-Object @{name = "Server" ;e = {"GPO"}}, @{name = "Folder" ;e ={$name + "\" + $object}}, @{name = "IdentityReference" ;e = {$x = $_.name.split('\'); $x[0].toUpper() + '\' + $x[1]}}}}
$all += $gpo.gpos.gpo |foreach-object {$name = $_.name; $_.User.ExtensionData.extension.registrySettings.Registry | ForEach-Object {$object = $_.name; $_.filters.filtergroup | Select-Object @{name = "Server" ;e = {"GPO"}}, @{name = "Folder" ;e ={$name + "\" + $object}}, @{name = "IdentityReference" ;e = {$x = $_.name.split('\'); $x[0].toUpper() + '\' + $x[1]}}}}
$all += $gpo.gpos.gpo |foreach-object {$name = $_.name; $_.computer.ExtensionData.extension.LocalUsersAndGroups.group.properties} | ForEach-Object { $object = $_.groupname; $_.members.member | Select-Object @{name = "Server" ;e = {"GPO"}}, @{name = "Folder" ;e ={$name + "\" + $object}}, @{name = "IdentityReference" ;e = {$_.name}}}
$all += $gpo.gpos.gpo |foreach-object {$name = $_.name; $_.User.ExtensionData.extension.DriveMapSettings.drive | ForEach-Object {$object = $_.name; $_.filters.filtergroup | Select-Object @{name = "Server" ;e = {"GPO"}}, @{name = "Folder" ;e ={$name + "\" + $object}}, @{name = "IdentityReference" ;e = {$x = $_.name.split('\'); $x[0].toUpper() + '\' + $x[1]}}}}
$all += $gpo.gpos.gpo |foreach-object {$name = $_.name; $_.Computer.ExtensionData.extension.ShortcutSettings.Shortcut | ForEach-Object {$object = $_.name; $_.filters.filtergroup | Select-Object @{name = "Server" ;e = {"GPO"}}, @{name = "Folder" ;e ={$name + "\" + $object}}, @{name = "IdentityReference" ;e = {$x = $_.name.split('\'); $x[0].toUpper() + '\' + $x[1]}}}}
$all += $gpo.gpos.gpo |foreach-object {$name = $_.name; $_.User.ExtensionData.extension.FilesSettings.file| ForEach-Object {$object = $_.name; $_.filters.filtergroup | Select-Object @{name = "Server" ;e = {"GPO"}}, @{name = "Folder" ;e ={$name + "\" + $object}}, @{name = "IdentityReference" ;e = {$x = $_.name.split('\'); $x[0].toUpper() + '\' + $x[1]}}}}
add-mdbcdata -InputObject $all


$localsession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://hosvexch01/PowerShell/ -Authentication Kerberos
import-pssession $localsession
$all = get-mailbox -ResultSize unlimited | ForEach-Object { $user= $_.SamAccountName; Get-MailboxPermission -Identity $user  | Select-Object @{name = "Server" ;e = {"Exchange\" + $_.PSComputerName}}, @{ name = "FileSystemRights" ;e = {$_.AccessRights}}, IsInherited, @{name = "Folder" ;e = {"mailbox\" + $user}}, @{name = "IdentityReference" ;e = {$_.User}}, @{ name = "AccessControlType" ;e ={if ($_.Deny -eq $true) {'Deny'} else {"Allow"}}}, @{name = "InheritanceFlags" ;e = {$_.InheritanceType}}}
add-mdbcdata -InputObject $all
remove-pssession $localsession

connect-exchangeOnline -UserPrincipalName yves.germainadm@kruger.com
$all =  get-mailbox -ResultSize unlimited | % { $server = $_.ServerName; $user= $_.alias; Get-MailboxPermission -Identity $user | Select-Object @{name = "Server" ;e = {"Exchange\" + $Server}}, @{ name = "FileSystemRights" ;e = {$_.AccessRights}}, IsInherited, @{name = "Folder" ;e = {"mailbox\" + $user}}, @{name = "IdentityReference" ;e = {$_.User}}, @{ name = "AccessControlType" ;e ={if ($_.Deny -eq $true) {'Deny'} else {"Allow"}}}, @{name = "InheritanceFlags" ;e = {$_.InheritanceType}}}
add-mdbcdata -InputObject $all

Connect-VIServer hosvvcsa.kruger.com
$all = Get-VIPermission | ForEach-Object { $IdentityReference = $_.principal; $propagate= $_.propagate; Get-virole -Name $_.Role| Select-Object @{ name = "IdentityReference";e = {$IdentityReference}}, @{ name = "Server";e = {"Vcenter\" + $_.server}}, @{ name = "Folder";e = {"Role\" + $_.Name }}, @{ name = "FileSystemRights";e = { $_.ExtensionData.Privilege}}, @{name = "InheritanceFlags" ;e = {$propagate}}}
add-mdbcdata -InputObject $all

get-mdbcdata -Filter @{"Server" ="GPO" ; "IdentityReference" =@{ '$regex' = '^KRUGERINC\\Domain Users' }} -as PS -project @{"_id" = 0}
get-mdbcdata -Filter @{"Server" ="GPO" ; "IdentityReference" =@{ '$not' = @{ '$regex' = '^KRUGERINC\\' }}} -as PS -project @{"_id" = 0}
Get-MdbcData -Filter @{"Server" ="GPO" ; '$nor' = @(@{ "IdentityReference" = @{'$regex' = '^KRUGERINC\\'}}, @{"IdentityReference" = @{'$regex' = '^AUTORITE NT\\'}})} -As PS -First 100 | Select-Object Server, Folder, IdentityReference
function ConvertTo-NtAccount ($sid) { (New-Object system.security.principal.securityidentifier($sid)).translate([system.security.principal.ntaccount]) }
$gpo = Get-GPOReport -All -ReportType xml
$gpo.gpos.gpo | ForEach-Object {
    $name = $_.name 
    $_.SecurityDescriptor | ForEach-Object {
        $_.permissions.TrusteePermissions | ForEach-Object {
            if ($_.standard.GPOGroupedAccessEnum -eq "Apply Group Policy" -and $_.trustee.sid."#text" -like "S-1-5-21-*") {
                $_ | Select-Object @{name = "Gpo"; e = { $name } },
                @{name = "Sid"; e = { ConvertTo-NtAccount ($_.trustee.sid."#text") } },
                @{name = "Allow" ; e = { $_.type.PermissionType } }
            }
        }
    }
}

robocopy '\\grsvfp01\groups' 'C:\test' /create /COPY:atsou /lev:3 /e
Get-ChildItem '\\grsvfp01\groups\Serveur Richelieu (R)' -Directory | ForEach-Object { 
    Start-Job -Name $_.name -ArgumentList $_.name, $_.fullname -ScriptBlock {
        param ($name, $fullName) 
        robocopy $fullname "C:\test\Serveur Richelieu (R)\$name" /e /xf * /create /COPY:atsou
    }
}
Get-Job | Where-Object { $_.state -like "completed" } | Remove-Job

Enter-PSSession grsvfp01
Get-ChildItem "d:\groups\Serveur Richelieu (R)" -Directory | ForEach-Object { 
    Start-Job -Name $_.name -ArgumentList  $_.fullname -ScriptBlock {
        param($fullname) 
        $objFSO = New-Object -ComObject "Scripting.FileSystemObject" 
        $objFSO.GetFolder($fullname) | Select-Object name, path , size
    }
}