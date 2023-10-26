Param(
    [Parameter(Mandatory = $true)]
    $Server = "etsvps02",
    [Parameter(Mandatory)]
    [ValidateSet("Bedford", "Bentonville", "Bromptonville","Brassfield", "Calgary", "Corner Brook", "Crabtree", "Elizabethtown", "Joliette", "Kamloops", "Lasalle", "Laurier", "Laval", "Lennoxville", "Lions Falls", "Memphis", "Mississauga", "Monteregie" ,"New Westminster", "Oshawa", "Pedigree", "Port Alma", "Queensborough", "Richelieu", "Scarborough", "Shared Services", "Sherbrooke", "Sherbrooke-LDC", "Sungard", "Trenton", "Trois-Rivieres", "Turcal", "Wayagamack")]
    $location,
    [Parameter(Mandatory)]
    [ValidateSet("Corporate", "Energy", "Head Office", "Kruger Products", "Packaging", "Publication", "Recycling")]
    $BusinessUnit
)

import-module  ActiveDirectory, PrintManagement, ServerManager, GroupPolicy
# Variable à modifier
$Server = "etsvps02"
$location = "ElizabethTown"
$BusinessUnit = "Packaging"
$domainName = "Kruger.com"
$gpoBackupFolderFullPath = "C:\GPO-backup\"
$OU = "OU=Printers,OU=Groups,OU=$location,OU=$BusinessUnit,DC=kruger,DC=com"
$printers = import-csv C:\temp\etsvps02.csv -Delimiter ";"

switch ($location) {
    "Bedford" { $extension = "BD" }
    "BentonVille" { $extension = "BT" }
    "Brampton" { $extension = "BA" }
    "Brassfield" { $extension = "BF"}
    "Bromptonville" { $extension = "BR" }
    "Calgary" { $extension = "CA" }
    "Corner Brook" { $extension = "CB" }
    "Crabtree" { $extension = "CT" }
    "Elizabethtown" { $extension = "ET" }
    "Joliette" { $extension = "JO" }
    "Kamloops" { $extension = "KL" }
    "Lasalle" { $extension = "LS" }
    "Laurier" { $extension = "GL" } # Gatineau/Laurier
    "Laval" { $extension = "LV" }
    "Lennoxville" { $extension = "LX" }
    "Lions Falls" {$extension = "LF"}
    "Head Office" { $extension = "HO" }
    "Memphis" { $extension = "MP" }
    "Mississauga" { $extension = "MI" }
    "Monteregie" { $extension = "KL" }
    "New Westminster" { $extension = "NW" }
    "Oshawa" { $extension = "OW" }
    "Pedigree" { $extension = "PD" }
    "Port Alma" {$extension = "PM"}
    "Queensborough" { $extension = "QB" }
    "Richelieu" { $extension = "GR" } # Gatineau/Richelieu
    "Scarborough" { $extension = "SC" }
    "Shared Services" { $extension = "KK" }
    "Sherbrooke" { $extension = "SH" }
    "Sungard" { $extension = "SG" }
    "Trenton" { $extension = "TT" }
    "Trois-Rivieres" { $extension = "TR" }
    "Turcal" { $extension = "TU" }
    "Wayagamack" { $extension = "WA" }
}

# Copy Drivers to server
robocopy \\kruger.com\sccm$\Sources\Software_Library\KRUGER\SOFTWARES\Drivers \\$server\c$\drivers /s /mt:16
# A GPO name KR Server Print Spooler Disable is applied across Kruger infrastructure to restrict Print Spooler services.  Add Server to exception Group.
$reboot = $false
get-adgroup "KR Print Spooler Disable Exceptions"
$ADserver = get-adcomputer $Server 
# Move Server in proper OU
$targetPath = "OU=Servers,OU=$location,OU=$BusinessUnit,DC=kruger,DC=com"
# If the GPO "KR Print Spooler Disable Exceptions" is not linked to the Server's OU, link it.
[xml] $report = get-gpo -Name "KR Server Print Spooler Disable" | Get-GPOReport -ReportType xml
if (!($targetPath -in $report.gpo.linksto.sompath)) {
    Set-GPLink -Name "KR server Print Spooler Disable" -Target $targetPath -LinkEnabled Yes
}

if ($ADserver.DistinguishedName -notlike "*OU=Servers,OU=$location,OU=$BusinessUnit,DC=kruger,DC=com" ) { Move-ADObject -Identity $ADserver -TargetPath $targetPath; $reboot = $true }

if (!($Adserver.name -in (Get-ADGroupMember -Identity "KR Print Spooler Disable Exceptions" ).name)) { Add-ADGroupMember -Identity "KR Print Spooler Disable Exceptions" -Members $ADserver.DistinguishedName ; $reboot = $true }

# reboot if not in group
if ($reboot) { Restart-Computer -ComputerName $server }

# Adding the DNS records
# Create Reverse Pointer zone if needed.

$printers | ForEach-Object { 
    $ip = $_.PortName; 
    $name = $_.name.replace("kruger.com", "");  
    if (!(Resolve-DnsName -Server 10.1.22.221 -Name $name)) { 
        Add-DnsServerResourceRecordA -ComputerName 10.1.22.221 -name $name -ZoneName kruger.com -IPv4Address $ip
    }
}

# ADD Servers-Print Service Roles and Features.

$Session = new-pssession -ComputerName $Server
$reboot = invoke-command -Session $Session -ScriptBlock {
    $code = Add-WindowsFeature RSAT-Print-Services
    if ($code.ExitCode -eq "SuccessRestartRequired" ) { $reboot = $true }
    $code = Add-WindowsFeature Print-LPD-Service
    if ($code.ExitCode -eq "SuccessRestartRequired" ) { $reboot = $true }
    if ($reboot -ne $true) { $reboot = $false };
    set-service -Name spooler -StartupType Automatic
    start-service spooler
    return $reboot
}
if ($reboot -eq "True") { Restart-Computer -ComputerName $server }

# Adding the groups for Printers and Default Printers

$Printers[0..4] | ForEach-Object { 
    $name = $_.name; 
    $Description = "Printer - " + $name 
    if ( !( get-adgroup -SearchBase $OU -Filter { name -like $name })) { New-ADGroup -DisplayName $name -Name $name -Path $ou -GroupScope Global -GroupCategory Security -Description $Description } 
    # Adding the groups for Default Printers
    $name = $_.name + "_DF"; 
    $Description = "Default Printer - " + $name 
    if ( !( get-adgroup -SearchBase $OU -Filter { name -like $name })) { New-ADGroup -DisplayName $name -Name $name -Path $ou -GroupScope Global -GroupCategory Security -Description $Description } 
}

$printers[0..4] | ForEach-Object {
    $printerName = $_.Name
    $driverName = $_.DriverName
    $printerPortName = $_.name
    $printerPort = $_.name
    $driverPath = $_.driverpath
    if ($null -eq (Get-Printer -ComputerName $Server -name $printerName -ErrorAction SilentlyContinue)) {
        # Check if driver is not already installed
        if ($null -eq (Get-PrinterDriver -ComputerName $Server -name $driverName -ErrorAction SilentlyContinue)) {
            # Add the driver to the Windows Driver Store
            invoke-command -Session $Session -ArgumentList $driverPath -ScriptBlock { pnputil.exe /a $args }
            Add-PrinterDriver -ComputerName $Server -Name $driverName
        }
        else {
            Write-Warning "Printer driver $driverName already installed"
        }
        # Check if printerport doesn't exist
        if ($null -eq (Get-PrinterPort -ComputerName $Server -name $printerPortName -ErrorAction SilentlyContinue)) {
            # Add printerPort
            Add-PrinterPort -ComputerName $Server -Name $printerPortName -PrinterHostAddress $printerPort
        }
        else {
            Write-Warning "Printer port with name $($printerPortName) already exists"
        }
        try {
            # Add the printer
            Add-Printer -ComputerName $Server -Name $printerName -DriverName $driverName -PortName $printerPortName -Published -shareName $printerName -Shared -Location $location -ErrorAction stop
        }
        catch {
            Write-Host $_.Exception.Message -ForegroundColor Red
            break
        }
        Write-Host "Printer $printerName successfully installed" -ForegroundColor Green
    }
    else {
        Write-Warning "Printer $printerName already installed"
    }
}

# Create AD Groups for printing permissions and GPP

$result = Try { Get-ADOrganizationalUnit -Identity $OU }  catch {}
if ($null -eq $result) {
    New-ADOrganizationalUnit -Name "Printers" -Path "OU=Groups,OU=$location,OU=$BusinessUnit,DC=kruger,DC=com" 
}
#Create AD group 
$printers[0..4] | ForEach-Object {
    foreach ($suffix  in @("", "_DF", "_Print", "_Manage")) {
        $groupName = $_.name + $suffix; 
        switch ($suffix) {
            "" { $Description = "GPO Map printer for $groupname"; }
            "_DF" { $Description = "GPO Map as a default printer for $groupname" ; }
            "_Print" { $Description = "Permissions to print for $groupname"; }
            "_Manage" { $Description = "Permissions to manage printer Queue document for $groupname"; }
        }
        if (!(Get-ADGroup -SearchBase $ou -Filter { name -eq $groupName }) ) {
            Try { New-ADGroup -Name $groupname -GroupScope Global -GroupCategory Security -Description $Description -path $ou }  catch {
                Write-Host $_.Exception.Message -ForegroundColor Red
                break
            }
        }
        else {
            Write-Warning "Group $Groupname exists!" 
        }
    }
}

# Restore GPO GPP Print Server Template from Backup.  Give it time to replicate to all domain controllers.

# Using COM objects. Restore-GPO won't restore a GPO if the GPO is deleted!

$gpm = New-Object -ComObject GPMgmt.GPM
$gpmConstants = $gpm.GetConstants()
$gpmDomain = $gpm.GetDomain($domainName, "", $gpmConstants.UseAnyDC)
$gpmBackupDir = $gpm.GetBackupDir($gpoBackupFolderFullPath)
$searcher = $gpm.CreateSearchCriteria()
$Searcher.Add( $gpmConstants.SearchPropertyBackupMostRecent, $gpmConstants.SearchOPEquals, $True)

$gpmBackup = $gpmBackupDir.SearchBackups($Searcher)
$ID = $($gpmBackup).ID
$gpmRestoreGPO = $gpmBackupDir.GetBackup($id)
$result = $gpmdomain.RestoreGPO($gpmRestoreGPO , 0)
$result.result

# Create new printers groups

$printers | ForEach-Object {
    $printerName = $_.name;
    $PrintGroup = $_.name + "_Print"; 
    #Get GroupSID
    $PrintSid = (Get-adgroup -filter { name -eq $PrintGroup }).sid.value

    $ManageGroup = $_.name + "_Manage"; 
    #Get GroupSID
    $ManageSid = (Get-adgroup -filter { name -eq $ManageGroup }).sid.value
    #Set Permissions
    Set-Printer -ComputerName $server -name $printerName -PermissionSDDL "G:SYD:(A;;SWRC;;;AC)(A;;SWRC;;;$PrintSid)(A;;SWRC;;;$ManageSid)(A;CIIO;RC;;;$ManageSid)(A;OIIO;RPWPSDRCWDWO;;;$ManageSid)(A;;LCSWSDRCWDWO;;;BA)" -verbose
}

# New GPO

$GPOName = "$Extension GPP Print Server $server"
"If $GPOName exist, delete it"
if (Get-GPO -Name $GPOName -ErrorAction SilentlyContinue ) { Remove-GPO -Name $GPOName }
$newgpo = copy-gpo -SourceName "GPP Print Server Template" -TargetName $gponame
$guid = $newgpo.id.guid
$GPP_PRT_XMLPath = "\\hospdc01\D$\Windows\SYSVOL\sysvol\kruger.com\Policies\{$guid}\User\Preferences\Printers\Printers.xml"
[XML]$PRNT = (Get-Content -Path $GPP_PRT_XMLPath) 

$NewEntry = @()

foreach ($suffix in @( "", "_DF")) {
    foreach ($list in $Printers[0..4]) {
        $name = $list.name
        $default = "0"
        if ($suffix -eq "_DF") { $GroupName = ($name + "_DF") ; $default = "1" }
        $CurrentDateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $newguid = [System.Guid]::NewGuid().toString()
        $NewEntry = $PRNT.printers.SharedPrinter[0].clone()
        $NewEntry.Name = $name
        $NewEntry.Status = $name
        $NewEntry.Changed = "$CurrentDateTime"
        $NewEntry.uid = "{" + "$newguid" + "}"
        $NewEntry.properties.path = "\\$server\$Name"
        $NewEntry.properties.location = $location
        $NewEntry.bypassErrors = 1
        $NewEntry.properties.action = "R"
        $NewEntry.properties.default = $default
        $NewEntry.filters.Filtergroup.Name = "KRUGERINC\$GroupName"
        $NewEntry.filters.Filtergroup.userContext = "1"
        $sid = (get-adgroup -SearchBase $ou -filter { name -eq $name }).sid.value
        $NewEntry.filters.Filtergroup.SID = $sid
        $PRNT.DocumentElement.AppendChild($NewEntry) 
    } 
}

$PRNT.Save($GPP_PRT_XMLPath)

$PRNT.DocumentElement.RemoveChild($PRNT.DocumentElement.SharedPrinter[0])
$PRNT.Save($GPP_PRT_XMLPath)
$GPP_PRT_XMLPath = "\\hospdc01\D$\Windows\SYSVOL\sysvol\kruger.com\Policies\{$guid}\User\Preferences\Printers\Printers.xml"
[XML]$PRNT = (Get-Content -Path $GPP_PRT_XMLPath) 
$PRNT.DocumentElement.RemoveChild($PRNT.DocumentElement.SharedPrinter[0])
$PRNT.Save($GPP_PRT_XMLPath)

New-GPLink -Name $gponame -Target "ou=Standard Users,ou=Users,OU=$location,OU=$BusinessUnit,DC=kruger,DC=com" -LinkEnabled Yes
