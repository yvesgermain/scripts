# $FilePath = "c:\temp\gporeport-" + (Get-Date -f yyyy-MM-dd) + ".xml"
# Get-GPOReport -all -ReportType Xml -Path $FilePath
$GPO = New-Object -TypeName XML
$GPO.load("c:\temp\gporeport-2023-12-06.xml")
$GPOdrives = $gpo.report.GPO | Where-Object { 
    $_.name -notlike "Test - DriveMap - YG" -and $_.name -notlike "SH Drives Mapping - TEST" -and 
    $_.name -notlike "Template - DriveMap - YG" } |  ForEach-Object {
    $name = $_.name
    $_.User.ExtensionData.extension.DriveMapSettings.drive | Where-Object { $_.properties.action -notlike "C" } |  Select-Object @{ name = "GPO" ; e = { $name } },
    @{ name = "Letter" ; e = { $_.properties.Letter } },
    @{ name = "Path" ; e = { $_.properties.path } },
    @{ name = "Action" ; e = { $_.properties.action } },
    @{ name = "ThisDrive"; e = { $_.properties.ThisDrive } },
    @{ name = "Filtergroup" ; e = { $_.filters.filtergroup.bool } },
    @{ name = "Label" ; e = { $_.properties.label } },
    @{ name = "Group"; e = { $_.filters.filtergroup.name.replace("KRUGERINC\", "") } },
    @{ name = "OrgUnit" ; e = { $_.filters.FilterOrgUnit.bool } },
    @{ name = "OU"; e = { $_.filters.FilterOrgUnit.name } }
}

# $drives | Export-Csv -Path C:\temp\drives2gpo.csv -Encoding utf8 -Delimiter "," -Append
#  
# $drives = Import-Csv -Path C:\temp\drives2gpo.csv -Delimiter "," -Encoding utf8
# $drives | Where-Object { $_.group -like "*,*" } | ForEach-Object { $_.group = $_.group.split(",") }
# $drives | Where-Object { $_.OU -like "*,*" } | ForEach-Object { $_.OU = $_.OU.split(",") }

$drives = $gpodrives + $xx | Where-Object { $_.Path -notlike "" -and $_.path -notlike '*%username%' -and $_.path -notlike '*& UserName & $' } 

"New GPO Drive Maps"

$GPOName = "Test - DriveMap - YG"
"If $GPOName exist, delete it"
Write-Output "Restore GPO Template - Drivemap - YG"
if (!( Get-GPO -Name "Template - Drivemap - YG")) {
    Restore-GPO -Id 99f1e4b3-2f8a-45b4-9288-12ee81de65fc -Path '\\kruger.com\sccm$\Sources\scripts_Infra\gpo'
}

if (Get-GPO -Name $GPOName -ErrorAction SilentlyContinue ) { Remove-GPO -Name $GPOName }
$newgpo = Copy-GPO -SourceName "Template - Drivemap - YG" -TargetName $GPOName
$guid = $newgpo.id.guid
$newgpo.description = "GPO to add Drive Maps using groups"
$GPP_Admin_XMLPath = "\\kruger.com\sccm$\Sources\scripts_Infra\data\Drives.xml"
$Admin = New-Object -TypeName XML
$Admin.load($GPP_Admin_XMLPath)
"Creating " + $newgpo.displayname + " GPO"

foreach ( $Drive in $Drives ) {
    if ($Drive.group -notlike "" -and $Drive.OU -like "") {
        #        if ($Drive.group -notlike "" -and $Drive.OU -notlike "" ) {
        #            $NewEntry = $Admin.Drives.Drive[2].Clone()
        #        }
        #        else {
        #if ($Drive.group -notlike "" ) {
        #                $NewEntry = $Admin.Drives.Drive[0].Clone()
        #            } 
        #        }

        # $clone = $NewEntry.Properties.Members.member.clone()
        # $NewEntry.Properties.Members.AppendChild($clone)
        $NewEntry = $Admin.Drives.Drive[0].Clone()        
        $CurrentDateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $newguid = [System.Guid]::NewGuid().toString()
        $NewEntry.Changed = "$CurrentDateTime"
        $NewEntry.uid = "{ " + "$newguid" + " }"
        $NewEntry.SetAttribute("disabled", 1)
        $int = 0
        foreach ( $group in $drive.group) {
            if ($int -lt 1) {
                $NewEntry.filters.FilterGroup.name = ( Get-ADGroup -Identity $group).name
                $NewEntry.filters.FilterGroup.sid = ( Get-ADGroup -Identity $group ).sid.value
                $int++
            }
            else {
                $clone = $Admin.drives.drive.filters.filtergroup[0].clone()
                $newentry.filters.AppendChild($clone)
                $NewEntry.filters.FilterGroup[$int].name = ( Get-ADGroup -Identity $group).name
                $NewEntry.filters.FilterGroup[$int].sid = ( Get-ADGroup -Identity $group ).sid.value
                $NewEntry.filters.FilterGroup[$int].bool = "OR"
            }
        }
    }
    if ($Drive.OU -notlike "" -and $drive.group -like "") {
        if ($Drive.group -like "") {
            $NewEntry = $Admin.Drives.Drive[1].Clone()
        }
        $CurrentDateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $newguid = [System.Guid]::NewGuid().toString()
        $NewEntry.Changed = "$CurrentDateTime"
        $NewEntry.uid = "{ " + "$newguid" + " }"
        $NewEntry.SetAttribute("disabled", 1)
        $int = 0
        foreach ( $OU in $drive.OU) {
            # $Org = $OU.replace("OU=", "")
            $drive
            if ($int -lt 1) {
                $NewEntry.filters.FilterOrgUnit.name = $OU
                $int++
            }
            else {
                if ($int -lt $drive.OU.count) {
                    $clone = $Admin.drives.drive[1].filters.FilterOrgUnit.clone()
                    $newentry.filters.AppendChild($clone)
                    $NewEntry.filters.FilterOrgUnit[$int].name = $OU
                    $NewEntry.filters.FilterOrgUnit[$int].bool = "OR"
                    $int++
                }
            }
        }
    }

    if ($Drive.group -notlike "" -and $Drive.ou -notlike "" ) {
        $NewEntry = $Admin.Drives.Drive[2].Clone()
        $CurrentDateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $newguid = [System.Guid]::NewGuid().toString()
        $NewEntry.Changed = "$CurrentDateTime"
        $NewEntry.uid = "{ " + "$newguid" + " }"
        $NewEntry.SetAttribute("disabled", 1)
        $int = 0
        $intou = 0
        foreach ( $group in $drive.group) {
            foreach ( $OU in $drive.OU) {
                if ($int -ge 1) {
                    $clone = $Admin.drives.drive[2].filters.filtergroup.clone()
                    $newentry.filters.AppendChild($clone)
                    $NewEntry.filters.FilterGroup[$int].name = ( Get-ADGroup -Filter { name -eq $group }).name
                    $NewEntry.filters.FilterGroup[$int].sid = ( Get-ADGroup -Filter { name -eq $group } ).sid.value
                    $NewEntry.filters.FilterGroup[$int].bool = "OR"
                }`
                    else {
                    $NewEntry.filters.FilterGroup.name = ( Get-ADGroup -Filter { name -eq $group }).name
                    $NewEntry.filters.FilterGroup.sid = ( Get-ADGroup -Filter { name -eq $group } ).sid.value
                    $NewEntry.filters.FilterGroup.bool = "OR"
                }
                $int++
                if ( $intou -ge 1) {
                    $clone = $Admin.drives.drive[2].filters.FilterOrgUnit.clone()
                    $newentry.filters.AppendChild($clone)
                    $NewEntry.filters.FilterOrgUnit[$intou].name = $OU
                    $NewEntry.filters.FilterOrgUnit[$intou].bool = "AND"
                }`
                    else {
                    $NewEntry.filters.FilterOrgUnit.name = $OU
                    $NewEntry.filters.FilterOrgUnit.bool = "AND"
                }
                $intou++
            }
        }
    }        
    if ($drive.action -like "") { $action = "U" } else { $action = $drive.action }
    $newentry.properties.action = $action
    $newentry.name = ($drive.letter + ":")
    $newentry.status = ($drive.letter + ":")
    $newentry.properties.letter = $drive.letter
    $newentry.properties.path = $drive.Path
    $newentry.properties.persistent = "1"
    $newentry.properties.useletter = "1"
    $newentry.properties.label = $Drive.label
    $Admin.DocumentElement.AppendChild($NewEntry)
}


$item = $Admin.Drives.Drive[0]
$item | ForEach-Object { $Admin.DocumentElement.RemoveChild($item) }
$item = $Admin.Drives.Drive[0]
$item | ForEach-Object { $Admin.DocumentElement.RemoveChild($item) }
$item = $Admin.Drives.Drive[0]
$item | ForEach-Object { $Admin.DocumentElement.RemoveChild($item) }

$Admin.Save("\\kruger.com\sysvol\kruger.com\Policies\{$guid}\user\Preferences\Drives\Drives.xml")
