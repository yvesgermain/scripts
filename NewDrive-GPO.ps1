$data = @(
    @{grp = "LX Drive map G to GRP" ; "Path" = "\\kruger.com\groups\Kpi\LX"; Drive = "G:"; OU = "OU=GPO,OU=Groups,OU=Lennoxville,OU=Kruger Products,DC=kruger,DC=com" },
    @{grp = "LX Drive map P to PUB" ; "Path" = "\\kruger.com\Public\Kpi\LX"; Drive = "P:"; OU = "OU=GPO,OU=Groups,OU=Lennoxville,OU=Kruger Products,DC=kruger,DC=com" },
    @{grp = "LX Drive map X to APP" ; "Path" = "\\kruger.com\Apps\Kpi\LX"; Drive = "X:"; OU = "OU=GPO,OU=Groups,OU=Lennoxville,OU=Kruger Products,DC=kruger,DC=com" }
)
"New GPO GPP Drive Mapping"

$GPOName = "Drive Mapping"
"If $GPOName exist, delete it"
if (Get-GPO -Name $GPOName -ErrorAction SilentlyContinue ) { Remove-GPO -Name $GPOName }
$newgpo = Copy-GPO -SourceName "LX GPP Drive mapping" -TargetName $gponame
$newgpo.description = "GPO to map drives using groups"
$guid = $newgpo.id.guid
$GPP_PRT_XMLPath = "\\hospdc01\D$\Windows\SYSVOL\sysvol\kruger.com\Policies\{$guid}\User\Preferences\drives\drives.xml"
[XML]$PRNT = (Get-Content -Path $GPP_PRT_XMLPath) 

"Creating " + $newgpo.displayname + " from LX GPP Drive mapping"


foreach ($line in $data) {
    $result = try {Get-ADGroup $line['grp'] -ErrorAction SilentlyContinue} catch {} ; 
    if ($null -eq $result){ 
        New-ADGroup -Name $line['grp'] -SamAccountName $line['grp'] -DisplayName $line['grp'] -Description "To map $line['drive'] to $line['Path']" -Path $line['ou'] -GroupCategory Security -GroupScope Global 
    }
    "Adding drive " + $line['Drive'] + " to $GPOName"
    $CurrentDateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $newguid = [System.Guid]::NewGuid().toString()
    $NewEntry = @()
    $Grp = $line['grp'] ;
    $NewEntry = $PRNT.drives.Drive[0].clone()
    $NewEntry[0].Name = $line["Drive"]
    $NewEntry[0].Status = $line["Drive"]
    $NewEntry[0].Changed = "$CurrentDateTime"
    $NewEntry[0].uid = "{" + "$newguid" + "}"
    $NewEntry[0].properties.path = $line["Path"]
    $NewEntry[0].bypassErrors = 1
    $NewEntry[0].properties.action = "R"
    $NewEntry[0].filters.Filtergroup.Name = "KRUGERINC\$Grp"
    $NewEntry[0].filters.Filtergroup.userContext = "1"
    $sid = (Get-ADGroup -Filter { name -eq $Grp }).sid.value
    $NewEntry[0].filters.Filtergroup.SID = $sid
    $PRNT.DocumentElement.AppendChild($NewEntry[0]) 
}
$PRNT.Save($GPP_PRT_XMLPath)
$PRNT.DocumentElement.RemoveChild($PRNT.DocumentElement.drive[0])
$PRNT.Save($GPP_PRT_XMLPath)
$GPP_PRT_XMLPath = "\\hospdc01\D$\Windows\SYSVOL\sysvol\kruger.com\Policies\{$guid}\User\Preferences\Drives\drives.xml"
[XML]$PRNT = (Get-Content -Path $GPP_PRT_XMLPath) 
$PRNT.DocumentElement.RemoveChild($PRNT.DocumentElement.drive[0])
$PRNT.Save($GPP_PRT_XMLPath)

# New-GPLink -Name $gponame -Target "ou=Standard Users,ou=Users,OU=$location,OU=$BusinessUnit,DC=kruger,DC=com" -LinkEnabled Yes
