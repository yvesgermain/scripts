# $FilePath = "c:\temp\gporeport-" + (Get-Date -f yyyy-MM-dd) + ".xml"
# Get-GPOReport -all -ReportType Xml -Path $FilePath
$GPO = New-Object -TypeName XML
$GPO.load("c:\temp\gporeport-2023-10-25.xml")
$drives = $gpo.report.GPO | ForEach-Object {
    $name = $_.name
    $_.User.ExtensionData.extension.DriveMapSettings.drive | Select-Object @{ name = "GPO" ; e = { $name } },
    @{ name = "Letter" ; e = { $_.properties.Letter } },
    @{ name = "Path" ; e = { $_.properties.path } },
    @{ name = "Action" ; e = { $_.properties.action } },
    @{ name = "ThisDrive"; e = { $_.properties.ThisDrive } },
    @{name = "Filtergroup" ; e = { $_.filters.filtergroup.bool } },
    @{name = "Label" ; e = { $_.properties.label } },
    @{ name = "Group"; e = { $_.filters.filtergroup.name } }
}

"New GPO removal of Local Admins Rights"

$GPOName = "Test - DriveMap - YG"
"If $GPOName exist, delete it"
if (Get-GPO -Name $GPOName -ErrorAction SilentlyContinue ) { Remove-GPO -Name $GPOName }
$newgpo = Copy-GPO -SourceName "LX GPP Drive mapping" -TargetName $GPOName
$guid = $newgpo.id.guid
$newgpo.description = "GPO to add Drive Maps using groups"
$GPP_Admin_XMLPath = "\\kruger.com\sccm$\Sources\scripts_Infra\data\Drives.xml"
$Admin = New-Object -TypeName XML
$Admin.load($GPP_Admin_XMLPath)
"Creating " + $newgpo.displayname + " GPO"

foreach ( $Drive in ($Drives | Where-Object {$_.group -ne $null} )) {
    $NewEntry = $Admin.Drives.Drive[0].Clone()
    # $clone = $NewEntry.Properties.Members.member[1].clone()
    # $NewEntry.Properties.Members.AppendChild($clone)
    $CurrentDateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $newguid = [System.Guid]::NewGuid().toString()
    $NewEntry.Changed = "$CurrentDateTime"
    $NewEntry.uid = "{ " + "$newguid" + " }"
    $NewEntry.SetAttribute("disabled", 1)
    $int = 0
    foreach ( $group in $drive.group) {
        $FilterName = $Group.replace("KRUGERINC\", "")
        if ($int -lt 1) {
            $NewEntry.filters.FilterGroup.name =  $group
            $NewEntry.filters.FilterGroup.sid = ( Get-ADGroup -Filter { name -like $FilterName } ).sid.value
            $int++
        }
        else {
            $clone = $Admin.drives.drive.filters.filtergroup[0].clone()
            $newentry.filters.AppendChild($clone)
            $NewEntry.filters.FilterGroup[$int].name = $group
            $NewEntry.filters.FilterGroup[$int].sid = ( Get-ADGroup -Filter { name -like $FilterName } ).sid.value
            $NewEntry.filters.FilterGroup[$int].bool = "OR"
        }
        $newentry.properties.action = $drive.action
        $newentry.properties.letter = $drive.letter
        $newentry.properties.path = $drive.Path
        $newentry.properties.persistent = "1"
        $newentry.properties.useLetter = "1"
        $newentry.properties.label = $Drive.label
    }
    $Admin.DocumentElement.AppendChild($NewEntry)
}


$item = $Admin.Drives.Drive[0]
$item | ForEach-Object { $Admin.DocumentElement.RemoveChild($item) }
$item = $Admin.Drives.Drive[0]
$item | ForEach-Object { $Admin.DocumentElement.RemoveChild($item) }

$Admin.Save("\\kruger.com\sysvol\kruger.com\Policies\{$guid}\user\Preferences\Drives\Drives.xml")
