<#
.SYNOPSIS
This script will create printers on a server, create a GPO, printer port, DNS records, groups to assign printers through the GPO, etc.  The printer name will be in the format:
<ext>PS<name> example the HR printer in Richelieu will be named GRPSHR.
.DESCRIPTION
This script will move the server to its proper OU, copy Drivers to server
Add it to the "KR Print Spooler Disable Exceptions" group to allow the print spooler service to run and reboot if its not in the group.
Add Servers-Print Service Roles and Features.  Create AD Groups for printing permissions and GPP.
Add the groups for Printers and Default Printers and create the printers printer ports and DNS records.
.PARAMETER Server
Name of the new server
.PARAMETER OldServer
Name of the old server you want to copy the configuration from.
.PARAMETER location
List of location example: "Bedford", "Bentonville", "Bromptonville", "Brassfield", etc.
.PARAMETER BusinessUnit
list of busines units: "Corporate", "Energy", "Head Office", "Kruger Products", "Packaging", "Publication", "Recycling"
.PARAMETER Fichier 
CSV file somma separated.  If you are migrating printers from another server you can use the following script to export the printers from another printer server:
get-printer -ComputerName oldServer | where {$_.shared -eq $true} | select name,DriverName,PortName,location,@{name="OldName";e={$_.name}} | export-csv <path>\newserver.csv -Encoding unicode -Delimiter ","
You have to clean up the CSV file.  Correct the Printer name (No spaces or accents, Please!).  The prefix of the printer names will be generated by the script.  
The drivers will only be one of these 3 drivers:
    1- Xerox Global Print Driver PCL6
    2- HP Universal Printing PCL 5
    3- HP DesignJet HPGL2
The printer port should only be the IP address.  Example if the printer port is IP_192.168.0.15 change it to 192.168.0.15.
.PARAMETER gpoBackupFolderFullPath
Path where the domain controller will backup the GPO.  You should probably leave the default
.EXAMPLE
C:\Scripts\Printer-new.ps1 -Server grsvfp01 -location Richelieu -BusinessUnit 'Kruger Products' -Fichier c:\temp\grsvfp01.csv
.EXAMPLE
C:\Scripts\Printer-new.ps1 -Server TRSVPS01 -location Trois-Rivieres -BusinessUnit Publication -Fichier c:\temp\TRSVPS01.csv
#>
Param(
    [Parameter(Mandatory = $true)]
    [string] $Server = "GRSVPS01",
    [Parameter(Mandatory = $false)]    
    [string] $oldServer,
    [Parameter(Mandatory = $true)]
    [ValidateSet("Corporate", "Energy", "Head Office", "Kruger Products", "Packaging", "Publication", "Recycling")]
    [string] $BusinessUnit,
    [Parameter(Mandatory = $true)]
    [ValidateSet("Bedford", "Bentonville", "Bromptonville", "Brassfield", "Calgary", "Corner Brook", "Crabtree", "Elizabethtown", "Joliette", "Kamloops", "Lasalle", "Laurier", "Laval", "Lennoxville", "Lions Falls", "Memphis", "Mississauga", "Monteregie" , "New Westminster", "Oshawa", "Pedigree", "Port Alma", "Queensborough", "Richelieu", "Scarborough", "Shared Services", "Sherbrooke", "Sherbrooke-LDC", "Sungard", "Trenton", "Trois-Rivieres", "Turcal", "Wayagamack")]
    [string] $location,
    [Parameter(Mandatory = $true)]
    [string] $Fichier = "C:\temp\GRSVPS01.csv",
    [string] $gpoBackupFolderFullPath = "C:\GPO-backup\"
)
# Install the modules to execute the script:

if (!(get-module -name ActiveDirectory)) {
Add-WindowsCapability -online -name "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0"
}
if (!(get-module -name DnsServer )){
    Add-WindowsCapability -online -name "Rsat.Dns.Tools~~~~0.0.1.0"
}
if (!(get-module -name GroupPolicy)){
    Add-WindowsCapability -online -name "Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0"
}

# Import the modules
Import-Module ActiveDirectory, PrintManagement, ServerManager, GroupPolicy
# Variable à modifier

$domainName = "Kruger.com"

if ($BusinessUnit -in "head Office", "Energy", "Corporate") {
    $OU = "OU=Printers,OU=Groups,OU=$BusinessUnit,DC=kruger,DC=com"
    $loc = "OU=$BusinessUnit,DC=kruger,DC=com"
    $LinkGPOTargetpath = "OU=Servers,OU=$BusinessUnit,DC=kruger,DC=com"
} `
else {
    $OU = "OU=Printers,OU=Groups,OU=$location,OU=$BusinessUnit,DC=kruger,DC=com"
    $loc = "OU=$location,OU=$BusinessUnit,DC=kruger,DC=com"
    $LinkGPOTargetpath = "OU=Servers,OU=$location,OU=$BusinessUnit,DC=kruger,DC=com"
}
$printers = Import-Csv $fichier
$Drivers = @(@{"name" = "Xerox Global Print Driver PCL6" ; "DriverPath" = "C:\Drivers\Xerox\UNIV_5.919.5.0_PCL6_x64\UNIV_5.919.5.0_PCL6_x64_Driver.inf\x3UNIVX.inf" },
    @{"name" = "HP Universal Printing PCL 5"; "DriverPath" = "C:\Drivers\HP\pcl5-x64-6.1.0.20062\hpcu180t.inf" },
    @{"name" = "HP DesignJet HPGL2"; "DriverPath" = "C:\Drivers\HP\HP designJet T2500\win-x64-hpgl2-drv\hpi11gex.inf" })

$ADserver = Get-ADComputer $Server
# $cred = New-Object System.Management.Automation.PSCredential -ArgumentList $admin, $password
$session = New-PSSession -ComputerName $Server # -Authentication Credssp -Credential $cred

switch ($loc) {
    "OU=Bedford,OU=Kruger Products,DC=kruger,DC=com" { $extension = "BD" }
    "OU=Bentonville,OU=Kruger Products,DC=kruger,DC=com" { $extension = "BT" }
    "OU=Bromptonville,OU=Publication,DC=kruger,DC=com" { $extension = "BR" }
    "OU=Calgary,OU=Kruger Products,DC=kruger,DC=com" { $extension = "CA" }
    "OU=Corner Brook,OU=Publication,DC=kruger,DC=com" { $extension = "CB" }
    "OU=corporate,DC=kruger,DC=com" {$extension = "KR" }
    "OU=Crabtree,OU=Kruger Products,DC=kruger,DC=com" { $extension = "CT" }
    "OU=Elizabethtown,OU=Packaging,DC=kruger,DC=com" { $extension = "ET" }
    "OU=Energy,DC=kruger,DC=com" { $extension = "NR" }
    "OU=Joliette,OU=Kruger Products,DC=kruger,DC=com" { $extension = "JO" }
    "OU=Kamloops,OU=Publication,DC=kruger,DC=com" { $extension = "KL" }
    "OU=Lasalle,OU=Packaging,DC=kruger,DC=com" { $extension = "LS" }
    "OU=Laurier,OU=Kruger Products,DC=kruger,DC=com" { $extension = "GL" } # Gatineau/Laurier
    "OU=Laval,OU=Kruger Products,DC=kruger,DC=com" { $extension = "LV" }
    "OU=Lennoxville,OU=Kruger Products,DC=kruger,DC=com" { $extension = "LX" }
    "OU=Head Office,DC=kruger,DC=com" { $extension = "HO" }
    "OU=Memphis,OU=Kruger Products,DC=kruger,DC=com" { $extension = "MP" }
    "OU=Mississauga,OU=Kruger Products,DC=kruger,DC=com" { $extension = "MI" }
    "OU=New Westminster,OU=Kruger Products,DC=kruger,DC=com" { $extension = "NW" }
    "OU=Oshawa,OU=Kruger Products,DC=kruger,DC=com" { $extension = "OH" }
    "OU=Pedigree,OU=Packaging,DC=kruger,DC=com" { $extension = "PD" }
    "OU=Paperboard,OU=Packaging,DC=kruger,DC=com" { $extension = "PB" } 
    "OU=Queensborough,OU=Kruger Products,DC=kruger,DC=com" { $extension = "QB" }
    "OU=Richelieu,OU=Kruger Products,DC=kruger,DC=com" { $extension = "GR" } # Gatineau/Richelieu
    "OU=Shared Services,OU=Recycling,DC=kruger,DC=com" { $extension = "RC" } 
    "OU=Scarborough,OU=Kruger Products,DC=kruger,DC=com" { $extension = "SC" }
    "OU=Shared Services,OU=Kruger products,DC=kruger,DC=com" { $extension = "KP" }
    "OU=Shared Services,OU=Publication,DC=kruger,DC=com" { $extension = "PP" }
    "OU=Shared Services,OU=Packaging,DC=kruger,DC=com" { $extension = "KK" }
    "OU=Sherbrooke,OU=Kruger Products,DC=kruger,DC=com" { $extension = "SH" }
    "OU=Sherbrooke-LDC,OU=Kruger Products,DC=kruger,DC=com" { $extension = "SB" } # Phoenix
    "OU=Sungard,OU=Kruger Products,DC=kruger,DC=com" { $extension = "SG" }
    "OU=Trenton,OU=Kruger Products,DC=kruger,DC=com" { $extension = "TT" }
    "OU=Trois-Rivieres,OU=Publication,DC=kruger,DC=com" { $extension = "TR" }
    "OU=Turcal,OU=Recycling,DC=kruger,DC=com" { $extension = "TU" }
    "OU=Wayagamack,OU=Publication,DC=kruger,DC=com" { $extension = "WA" }
}

"Copy Drivers to server"
# Enable-WSManCredSSP -Role Client -DelegateComputer $Server -Force
# invoke-command -ComputerName $server -ScriptBlock {Enable-WSManCredSSP -Role Server –Force}
robocopy \\kruger.com\sccm$\Sources\Software_Library\KRUGER\SOFTWARES\Drivers \\$server\c$\drivers /s /mt:16
"A GPO name KR Server Print Spooler Disable is applied across Kruger infrastructure to restrict Print Spooler services.  Add Server to exception Group."
$reboot = $false
Get-ADGroup "KR Print Spooler Disable Exceptions"

"If the GPO `"KR Print Spooler Disable`" is not linked to the Server's OU, link it."
[xml] $report = Get-GPO -Name "KR Server Print Spooler Disable" | Get-GPOReport -ReportType xml
if (!($LinkGPOTargetpath -in $report.gpo.linksto.sompath)) {
    Set-GPLink -Name "KR server Print Spooler Disable" -Target $LinkGPOTargetpath -LinkEnabled Yes
}

"ADD server to proper OU"
if ($ADserver.DistinguishedName -notlike "CN=$server,$LinkGPOTargetpath") { Move-ADObject -Identity $ADserver -TargetPath $LinkGPOTargetpath; $reboot = $true }

if (!($Adserver.name -in (Get-ADGroupMember -Identity "KR Print Spooler Disable Exceptions" ).name)) { Add-ADGroupMember -Identity "KR Print Spooler Disable Exceptions" -Members $ADserver.DistinguishedName ; $reboot = $true }

# reboot if not in group
if ($reboot) { Restart-Computer -ComputerName $server }

# Adding the DNS records
# Create Reverse Pointer zone if needed.

$printers | ForEach-Object { 
    $ip = $_.PortName 
    $name = ($extension.Toupper() + "PS" + $_.name)
    if (!(Resolve-DnsName -Server 10.1.22.221 -Name "$name.$domainName" -ErrorAction SilentlyContinue)) { 
        Add-DnsServerResourceRecordA -ComputerName 10.1.22.221 -Name $name -ZoneName $domainName -IPv4Address $ip -Verbose
    }
}

# ADD Servers-Print Service Roles and Features.

$reboot = Invoke-Command -Session $Session -ScriptBlock {
    $code = Add-WindowsFeature RSAT-Print-Services
    if ($code.ExitCode -eq "SuccessRestartRequired" ) { $reboot = $true }
    $code = Add-WindowsFeature Print-LPD-Service
    if ($code.ExitCode -eq "SuccessRestartRequired" ) { $reboot = $true }
    if ($reboot -ne $true) { $reboot = $false }
    Set-Service -Name spooler -StartupType Automatic
    Start-Service spooler
    return $reboot
}
if ($reboot -eq "True") { Restart-Computer -ComputerName $server }


# Create AD Groups for printing permissions and GPP
$result = Try { Get-ADOrganizationalUnit -Identity $OU }  catch {}
if ($null -eq $result) {
    New-ADOrganizationalUnit -Name "Printers" -Path "OU=Groups,OU=$location,OU=$BusinessUnit,DC=kruger,DC=com" 
}

# Adding the groups for Printers and Default Printers

#Create AD group 
$printers | ForEach-Object {
    foreach ($suffix  in @("", "_DF", "_Print", "_Manage")) {
        $groupName = $extension + "p_" + $_.name + $suffix 
        switch ($suffix) {
            "" { $Description = "GPO Map printer for $groupname " + $_.description; }
            "_DF" { $Description = "GPO Map as a default printer for $groupname" ; }
            "_Print" { $Description = "Permissions to print for $groupname"; }
            "_Manage" { $Description = "Permissions to manage printer Queue document for $groupname"; }
        }
        if (!(Get-ADGroup -SearchBase $ou -Filter { name -eq $groupName }) ) {
            Try { New-ADGroup -Name $groupname -GroupScope Global -GroupCategory Security -Description $Description -Path $ou }  catch {
                Write-Host $_.Exception.Message -ForegroundColor Red
                break
            }
        }
        else {
            Write-Warning "Group $Groupname exists!" 
        }
    }
    "Add $($extension + 'p_' + $_.name) in the group $($extension + 'p_' + $_.name + '_Print')"
    Add-ADGroupMember -Members $($extension + 'p_' + $_.name), $($extension + 'p_' + $_.name + '_DF') -Identity $($extension + 'p_' + $_.name + '_Print')

}

foreach ($Driver in $Drivers) {
    if ($null -eq (Get-PrinterDriver -ComputerName $Server -Name $driver.name -ErrorAction SilentlyContinue)) {
        "Add the driver to the Windows Driver Store"
        Invoke-Command -Session $Session -ArgumentList $Driver.driverPath -ScriptBlock { 
            pnputil.exe /a $args 
            c:\drivers\sap\xSPrint770_6-80005213.exe /silent 
        }
        "Add printer Driver"
        Add-PrinterDriver -ComputerName $Server -Name $driver.name
    } `
        else {
        Write-Warning ("Printer driver " + $driver.name + " already installed")
    }
}

# Create the printers
$printers | ForEach-Object {
    $printerName = ($extension.Toupper() + "ps" + $_.name)
    $driverName = $_.DriverName
    $printerPortName = $printerName
    $printerPort = ($extension.Toupper() + "ps" + $_.name) 
    if ($null -eq (Get-Printer -ComputerName $Server -Name $printerName -ErrorAction SilentlyContinue)) {
        "Check if printerport doesn't exist"
        if ($null -eq (Get-PrinterPort -ComputerName $Server -Name $printerPortName -ErrorAction SilentlyContinue)) {
            "Add printerPort $printerPortName"
            Add-PrinterPort -ComputerName $Server -Name $printerPortName -PrinterHostAddress $printerPort -Verbose
        }
        else {
            Write-Warning "Printer port with name $($printerPortName) already exists"
        }
        try {
            "Add the printer"
            Add-Printer -ComputerName $Server -Name $printerName -DriverName $driverName -PortName $printerPortName -Published -ShareName $printerName -Shared -Location $location -ErrorAction stop
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
    if ($oldServer) {
        Write-Host ("Copying the configuration from the $oldServer to " + $_.oldName + " to the new $printerName")
        $config = Get-PrintConfiguration -ComputerName $oldServer -PrinterName $_.oldName
        Set-PrintConfiguration -ComputerName $Server -PrinterName $printerName -PrintTicketXml $config.PrintTicketXml
    }
}


"Restore GPO GPP Print Server Template from Backup.  Give it time to replicate to all domain controllers."

"Using COM objects. Restore-GPO won't restore a GPO if the GPO is deleted!"

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

"Create new printers groups"

$printers | ForEach-Object {
    $printerName = ($extension.Toupper() + "PS" + $_.name)
    $PrintGroup = ($extension.Toupper() + "p_" + $_.name + "_Print" )
    "Get GroupSID for $PrintGroup"
    $PrintSid = (Get-ADGroup -Filter { name -eq $PrintGroup }).sid.value

    $ManageGroup = ($extension.Toupper() + "p_" + $_.name + "_Manage") 
    "Get GroupSID for $ManageGroup"
    $ManageSid = (Get-ADGroup -Filter { name -eq $ManageGroup }).sid.value
    "Set Permissions"
    Set-Printer -ComputerName $server -Name $printerName -PermissionSDDL "G:SYD:(A;;SWRC;;;AC)(A;;SWRC;;;$PrintSid)(A;;SWRC;;;$ManageSid)(A;CIIO;RC;;;$ManageSid)(A;OIIO;RPWPSDRCWDWO;;;$ManageSid)(A;;LCSWSDRCWDWO;;;BA)" -Verbose
}

"New GPO $Extension GPP Print Server $server"

$GPOName = "$Extension GPP Print Server $server"
"If $GPOName exist, delete it"
if (Get-GPO -Name $GPOName -ErrorAction SilentlyContinue ) { Remove-GPO -Name $GPOName }
$newgpo = Copy-GPO -SourceName "GPP Print Server Template" -TargetName $gponame
$newgpo.description = "GPO to map printers to users for $server"
$guid = $newgpo.id.guid
$GPP_PRT_XMLPath = "\\hospdc01\D$\Windows\SYSVOL\sysvol\$domainName\Policies\{$guid}\User\Preferences\Printers\Printers.xml"
[XML]$PRNT = (Get-Content -Path $GPP_PRT_XMLPath) 

"Creating $newgpo from GPP Print Server Template"
$NewEntry = @()

foreach ($suffix in @( "", "_DF")) {
    foreach ($list in $Printers) {
        $name = ( $extension + "ps" + $list.name )
        if ($suffix -eq "_DF") {
            $GroupName = ( $extension + "p_" + $list.name + "_DF") ; $default = "1" 
        } `
            else {
            $GroupName = ( $extension + "p_" + $list.name ); $default = "0"
        }
        "Adding $GroupName printer to $GPOName"
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
        $sid = (Get-ADGroup -SearchBase $ou -Filter { name -eq $GroupName }).sid.value
        $NewEntry.filters.Filtergroup.SID = $sid
        $PRNT.DocumentElement.AppendChild($NewEntry) 
    } 
}

$PRNT.Save($GPP_PRT_XMLPath)

$PRNT.DocumentElement.RemoveChild($PRNT.DocumentElement.SharedPrinter[0])
$PRNT.Save($GPP_PRT_XMLPath)
$GPP_PRT_XMLPath = "\\hospdc01\D$\Windows\SYSVOL\sysvol\$domainName\Policies\{$guid}\User\Preferences\Printers\Printers.xml"
[XML]$PRNT = (Get-Content -Path $GPP_PRT_XMLPath) 
$PRNT.DocumentElement.RemoveChild($PRNT.DocumentElement.SharedPrinter[0])
$PRNT.Save($GPP_PRT_XMLPath)

New-GPLink -Name $gponame -Target "ou=Standard Users,ou=Users,OU=$location,OU=$BusinessUnit,DC=kruger,DC=com" -LinkEnabled Yes

<# Clean environment

$Fichier = "C:\temp\GRSVfP01.csv"
$server = "GRSVfP01"

$printers | ForEach-Object { 
    $name = ($extension.Toupper() + "PS" + $_.name)
    if (Resolve-DnsName -Server 10.1.22.221 -Name "$name.kruger.com" -ErrorAction SilentlyContinue) { 
        Remove-DnsServerResourceRecord -ComputerName 10.1.22.221 -RRType A -RecordData $name -ZoneName kruger.com -Verbose
    }
}

#Remove AD group 
$printers | ForEach-Object {
    foreach ($suffix  in @("", "_DF", "_Print", "_Manage")) {
        $groupName = $extension + "p_" + $_.name + $suffix 
        if (Get-ADGroup -SearchBase $ou -Filter { name -eq $groupName }) {
            Try { Remove-ADGroup -Identity $groupname -path $ou -WhatIf }  catch {
                Write-Host $_.Exception.Message -ForegroundColor Red
                break
            }
        }
        else {
            Write-Warning "Group $Groupname exists!" 
        }
    }
}


# Remove the printers
$printers | ForEach-Object {
    $printerName = ($extension.Toupper() + "ps" + $_.name)
    $printerPortName = $printerName
    if ($null -ne (Get-printer -Name $printerName -ComputerName $Server -ErrorAction SilentlyContinue)) {
        "Check if printerport doesn't exist"
        if ($null -ne (Get-PrinterPort -ComputerName $Server -Name $printerPortName -ErrorAction SilentlyContinue)) {
            "Remove printerPort $printerPortName"
            Remove-PrinterPort -ComputerName $Server -Name $printerPortName -Verbose
        }
        try {
            "Remove the printer"
            Remove-Printer -ComputerName $Server -Name $printerName -ErrorAction stop
        }
        catch {
            Write-Host $_.Exception.Message -ForegroundColor Red
            break
        }
        Write-Host "Printer $printerName successfully removed" -ForegroundColor Green
    }
}


$reboot = Invoke-Command -Session $Session -ScriptBlock {
    $code = Remove-WindowsFeature RSAT-Print-Services
    if ($code.ExitCode -eq "SuccessRestartRequired" ) { $reboot = $true }
    $code = Remove-WindowsFeature Print-LPD-Service
    if ($code.ExitCode -eq "SuccessRestartRequired" ) { $reboot = $true }
    if ($reboot -ne $true) { $reboot = $false }
    return $reboot
}
if ($reboot -eq "True") { Restart-Computer -ComputerName $server }

$GPOName = "$Extension GPP Print Server $server"
"If $GPOName exist, delete it"
if (Get-GPO -Name $GPOName -ErrorAction SilentlyContinue ) { Remove-GPO -Name $GPOName }

# Removing the groups for Printers and Default Printers

#Removing AD group 
$printers | ForEach-Object {
    foreach ($suffix  in @("", "_DF", "_Print", "_Manage")) {
        $groupName = $extension + "p_" + $_.name + $suffix 
        if (Get-ADGroup -SearchBase $ou -Filter { name -eq $groupName }) {
            Try { Remove-ADGroup -Name $groupname }  catch {
                Write-Host $_.Exception.Message -ForegroundColor Red
                break
            }
        }
    }
}


$reboot = Invoke-Command -Session $Session -ScriptBlock {
    $code = Remove-WindowsFeature RSAT-Print-Services
    if ($code.ExitCode -eq "SuccessRestartRequired" ) { $reboot = $true }
    $code = Remove-WindowsFeature Print-LPD-Service
    if ($code.ExitCode -eq "SuccessRestartRequired" ) { $reboot = $true }
    if ($reboot -ne $true) { $reboot = $false }
    return $reboot
}
if ($reboot -eq "True") { Restart-Computer -ComputerName $server }

$GPOName = "$Extension GPP Print Server $server"
"If $GPOName exist, delete it"
if (Get-GPO -Name $GPOName -ErrorAction SilentlyContinue ) { Remove-GPO -Name $GPOName }

# Removing the groups for Printers and Default Printers

#Removing AD group 
$printers | ForEach-Object {
    foreach ($suffix  in @("", "_DF", "_Print", "_Manage")) {
        $groupName = $extension + "p_" + $_.name + $suffix 
        if (Get-ADGroup -SearchBase $ou -Filter { name -eq $groupName }) {
            Try { Remove-ADGroup -Name $groupname }  catch {
                Write-Host $_.Exception.Message -ForegroundColor Red
                break
            }
        }
    }
}
#>