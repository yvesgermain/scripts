$GPOName = "Test - DriveMap - YG"
"If $GPOName exist, delete it"
if (Get-GPO -Name $GPOName -ErrorAction SilentlyContinue ) { Remove-GPO -Name $GPOName }
$newgpo = Copy-GPO -SourceName "Template - Drivemap - YG" -TargetName $GPOName
$guid = $newgpo.id.guid
$newgpo.description = "GPO to add Drive Maps using groups"
$GPP_Admin_XMLPath = "\\kruger.com\sccm$\Sources\scripts_Infra\data\Drives.xml"
$Admin = New-Object -TypeName XML
$Admin.load($GPP_Admin_XMLPath)
"Creating " + $newgpo.displayname + " GPO"

foreach ($drive in $drives) {
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
                    $NewEntry.filters.FilterGroup[$int].bool = "and"
                }`
                    else {
                    $NewEntry.filters.FilterGroup.name = ( Get-ADGroup -Filter { name -eq $group }).name
                    $NewEntry.filters.FilterGroup.sid = ( Get-ADGroup -Filter { name -eq $group } ).sid.value
                    $NewEntry.filters.FilterGroup.bool = "and"
                }
                $int++
                if ( $intou -ge 1) {
                    $clone = $Admin.drives.drive[2].filters.FilterOrgUnit.clone()
                    $newentry.filters.AppendChild($clone)
                    $NewEntry.filters.FilterOrgUnit[$intou].name = $OU
                    $NewEntry.filters.FilterOrgUnit[$intou].bool = "OR"
                }`
                    else {
                    $NewEntry.filters.FilterOrgUnit.name = $OU
                    $NewEntry.filters.FilterOrgUnit.bool = "OR"
                }
                $intou++
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
        $newentry.filters
        $Admin.DocumentElement.AppendChild($NewEntry)
    }
}


$item = $Admin.Drives.Drive[0]
$item | ForEach-Object { $Admin.DocumentElement.RemoveChild($item) }
$item = $Admin.Drives.Drive[0]
$item | ForEach-Object { $Admin.DocumentElement.RemoveChild($item) }
$item = $Admin.Drives.Drive[0]
$item | ForEach-Object { $Admin.DocumentElement.RemoveChild($item) }

$Admin.Save("\\kruger.com\sysvol\kruger.com\Policies\{$guid}\user\Preferences\Drives\Drives.xml")
