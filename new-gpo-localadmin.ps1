$groups = @(
    "Server Admins",
    "Service Accounts Computer",
    "Site Admins",
    "Site Techs")

$extension = "BD", "BR", "BT", "CA", "CB", "CT", "ET", "EX", "GL", "GR", "HO", "HO SS", "JO", "KK", "KL", "LS", "LV", "LX", "MI", "MP", "NW", "OH", "PB", "PD", "QB", "SB", "SC", "SG", "SH", "TR", "TT", "TU", "WA", "KP External" , "KP Shared", "PP SS", "KK SS", "RC SS"

Function Find-OU {
    param($site)
    switch ($site) {
        "BD" { $Extension = "Bedford"  ; $BusinessUnit = "Kruger Products"; $resp = "samuel.ponsot@kruger.com" }
        "BT" { $Extension = "BentonVille"  ; $BusinessUnit = "Kruger Products" ; $resp = "jeff.stark@kruger.com" }
        # "BA" { $Extension = "Brampton"  ; $BusinessUnit = "Kruger Products" ; $resp = "luis.cerda@kruger.com" }
        "BR" { $Extension = "Bromptonville"  ; $BusinessUnit = "Publication" ; $resp = "richard.perras@kruger.com" }
        "BF" { $Extension = "Brassfield" ; $BusinessUnit = "Energy" ; $resp = "" }
        "CA" { $Extension = "Calgary"  ; $BusinessUnit = "Kruger Products" ; $resp = "steven.yatar@kruger.com" }
        "EX" { $Extension = "External"; $BusinessUnit = "Kruger Products" ; $resp = "" }
        "CB" { $Extension = "Corner Brook"  ; $BusinessUnit = "Publication" ; $resp = "kent.pike@kruger.com" }
        "CT" { $Extension = "Crabtree"  ; $BusinessUnit = "Kruger Products" ; $resp = "tyna.fraser@krugerproducts.ca" }
        "ET" { $Extension = "Elizabethtown"  ; $BusinessUnit = "Packaging" ; $resp = "matthew.barnes@kruger.com" }
        "HO" { $Extension = ""  ; $BusinessUnit = "Head Office" ; $resp = "Samuel.ponsot@kruger.com" }
        "HO SS" { $Extension = "Shared Services"  ; $BusinessUnit = "Head Office" ; $resp = "Samuel.ponsot@kruger.com" }
        "KR" { $Extension = ""  ; $BusinessUnit = "Head Office" ; $resp = "Samuel.ponsot@kruger.com" }
        "JO" { $Extension = "Joliette"  ; $BusinessUnit = "Kruger Products" ; $resp = "tyna.fraser@krugerproducts.ca" }
        "KL" { $Extension = "Kamloops"  ; $BusinessUnit = "Publication" ; $resp = "andrej.kocak@kruger.com" }
        "KK" { $Extension = "Shared Services"  ; $BusinessUnit = "Packaging" ; $resp = "luis.cerda@kruger.com" }
        "LS" { $Extension = "Lasalle"  ; $BusinessUnit = "Packaging" ; $resp = "gabriel.lebreton@kruger.com" }
        "GL" { $Extension = "Laurier"  ; $BusinessUnit = "Kruger Products" ; $resp = "richard.perras@kruger.com" }
        "LV" { $Extension = "Laval"  ; $BusinessUnit = "Kruger Products" ; $resp = "Samuel.ponsot@kruger.com" }
        "LX" { $Extension = "Lennoxville"  ; $BusinessUnit = "Kruger Products" ; $resp = "richard.perras@kruger.com" }
        "LF" { $Extension = "Lions Falls"  ; $BusinessUnit = "Energy" ; $resp = "" }
        "MP" { $Extension = "Memphis"  ; $BusinessUnit = "Kruger Products" ; $resp = "jeff.stark@kruger.com" }
        "KT" { $Extension = "Memphis"  ; $BusinessUnit = "Kruger Products" ; $resp = "jeff.stark@kruger.com" } # old naming convention
        "KL" { $Extension = "Monteregie" ; $BusinessUnit = "Energy" ; $resp = "" }
        "MI" { $Extension = "Mississauga"  ; $BusinessUnit = "Kruger Products" ; $resp = "steven.yatar@kruger.com" }
        "NW" { $Extension = "New Westminster"  ; $BusinessUnit = "Kruger Products" ; $resp = "russell.longakit@kruger.com" }
        "OH" { $Extension = "Oshawa"  ; $BusinessUnit = "Kruger Products" ; $resp = "Eric.Matthews@krugerproducts.ca" }
        "PD" { $Extension = "Pedigree"  ; $BusinessUnit = "Packaging" ; $resp = "luis.cerda@kruger.com" }
        "PB" { $Extension = "Paperboard"  ; $BusinessUnit = "Packaging" ; $resp = "normand.charette@kruger.com" }
        "PM" { $Extension = "Port Alma" ; $BusinessUnit = "Energy" ; $resp = "" }
        "QB" { $Extension = "Queensborough"  ; $BusinessUnit = "Kruger Products" ; $resp = "russell.longakit@kruger.com" }
        "GR" { $Extension = "Richelieu"  ; $BusinessUnit = "Kruger Products" ; $resp = "richard.perras@kruger.com" }
        "SC" { $Extension = "Scarborough"  ; $BusinessUnit = "Kruger Products" ; $resp = "Eric.Matthews@krugerproducts.ca" }
        "KP" { $Extension = "Shared Services" ; $BusinessUnit = "Kruger Products" ; $resp = "" }
        "KP External" { $Extension = "External" ; $BusinessUnit = "Kruger Products" ; $resp = "" }
        "KP Shared" { $Extension = "Shared Services" ; $BusinessUnit = "Kruger Products" ; $resp = "" }
        "PP" { $Extension = "Shared Services" ; $BusinessUnit = "Publication" ; $resp = "" }
        "PP SS" { $Extension = "Shared Services" ; $BusinessUnit = "Publication" ; $resp = "" }
        "KK" { $Extension = "Shared Services" ; $BusinessUnit = "Packaging"; $resp = "" }
        "KK SS" { $Extension = "Shared Services" ; $BusinessUnit = "Packaging"; $resp = "" }
        "RC SS" { $Extension = "Shared Services" ; $BusinessUnit = "Recycling"; $resp = "" }
        "SH" { $Extension = "Sherbrooke"  ; $BusinessUnit = "Kruger Products" ; $resp = "richard.perras@kruger.com" }
        "SB" { $Extension = "Sherbrooke-LDC"  ; $BusinessUnit = "Kruger Products" ; $resp = "richard.perras@kruger.com" }
        "SG" { $Extension = "Sungard"  ; $BusinessUnit = "Kruger Products" ; $resp = "" }
        "TT" { $Extension = "Trenton"  ; $BusinessUnit = "Kruger Products" ; $resp = "Eric.Matthews@krugerproducts.ca" }
        "TR" { $Extension = "Trois-Rivieres"  ; $BusinessUnit = "Publication" ; $resp = "richard.beland@kruger.com" }
        "TU" { $Extension = "Turcal"  ; $BusinessUnit = "Recycling" ; $resp = "filippo.campo@kruger.com" }
        "WA" { $Extension = "Wayagamack"  ; $BusinessUnit = "Publication" ; $resp = "jean-sebastien.roy2@kruger.com" }
    }
    if ($BusinessUnit -in "head Office", "Energy", "Corporate") {
        $OU = "OU=$BusinessUnit,DC=kruger,DC=com"
    } `
        else {
        $OU = "OU=$Extension,OU=$BusinessUnit,DC=kruger,DC=com"
    }
    return $OU
}

"New GPO removal of Local Admins Rights"

$GPOName = "Test - Removal of Local Admins Rights - YG"
"If $GPOName exist, delete it"
if (Get-GPO -Name $GPOName -ErrorAction SilentlyContinue ) { Remove-GPO -Name $GPOName }
$newgpo = Copy-GPO -SourceName "KR Removal of Local Admins Rights" -TargetName $gponame
$guid = $newgpo.id.guid
$newgpo.description = "GPO to add groups to the local administrators group"
$GPP_Admin_XMLPath = "\\kruger.com\sccm$\Sources\scripts_Infra\data\Groups.xml"
$Admin = New-Object -TypeName XML
$Admin.load($GPP_Admin_XMLPath)
"Creating " + $newgpo.displayname + " from KR Removal of Local Admins Rights"
foreach ( $ext in $extension) {

    $OU = Find-OU -site $ext
    foreach ( $Action in "Append", "OverRide") {
        $NewEntry = $Admin.Groups.Group[0].Clone()
        # $clone = $NewEntry.Properties.Members.member[1].clone()
        # $NewEntry.Properties.Members.AppendChild($clone)
        $CurrentDateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $newguid = [System.Guid]::NewGuid().toString()
        $NewEntry.Changed = "$CurrentDateTime"
        $NewEntry.uid = "{ " + "$newguid" + " }"
        $NewEntry.SetAttribute("disabled", 1)
        $FilterName = $ext + " PRV Accounts"
        $NewEntry.filters.FilterGroup[0].name = ("KRUGERINC\" + $ext + " PRV Accounts" )
        $NewEntry.filters.FilterGroup[0].sid = ( Get-ADGroup -Filter { name -like $FilterName } ).sid.value
        $NewEntry.filters.FilterOrgUnit[0].name = "ou=desktop,ou=computers,$ou"
        $NewEntry.filters.FilterOrgUnit[1].name = "ou=Laptop,ou=computers,$ou"
        $NewEntry.filters.FilterGroup[1].name = ("KRUGERINC\" + $ext + " PRV Accounts" )
        $NewEntry.filters.FilterGroup[1].sid = ( Get-ADGroup -Filter { name -like $FilterName } ).sid.value

        if ( $Action -eq "Append") {
            $NewEntry.properties.description = "$ext Local Admins Append"
            $NewEntry.properties.deleteAllUsers = 0
            $NewEntry.properties.deleteAllGroups = 0
            $NewEntry.properties.removeAccounts = 0
            $NewEntry.filters.FilterGroup[0].not = 0
            $NewEntry.filters.FilterGroup[1].not = 0
        }
        if ( $Action -eq "OverRide") {
            $NewEntry.properties.description = "$ext Local Admins"
            $NewEntry.properties.deleteAllUsers = 1
            $NewEntry.properties.deleteAllGroups = 1
            $NewEntry.properties.removeAccounts = 1
            $NewEntry.filters.FilterGroup[0].not = 1
            $NewEntry.filters.FilterGroup[1].not = 1
        }
        $int = 1
        foreach ( $group in $groups) {
            $groupName = "$ext $group"
            $NewEntry.Properties.Members.member[$int].name = "KRUGERINC\$groupName"
            $NewEntry.Properties.Members.member[$int].Sid = ((Get-ADGroup -Filter { name -eq $GroupName }).sid.value)
            $int++
        }
        $Admin.DocumentElement.AppendChild($NewEntry)
    }

    $NewEntry = $Admin.Groups.Group[0].Clone()
    $clone = $Admin.Groups.Group.properties.Members.member[4].clone()
    $newentry.Properties.Members.AppendChild($clone)
    # $clone = $Admin.Groups.Group.properties.Members.member[4].clone()
    # $newentry.Properties.Members.AppendChild($clone)
    $CurrentDateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $newguid = [System.Guid]::NewGuid().toString()
    $NewEntry.Changed = "$CurrentDateTime"
    $NewEntry.uid = "{ " + "$newguid" + " }"
    $NewEntry.SetAttribute("disabled", 1)
    # $FilterName = $ext + " PRV Accounts"
    # $NewEntry.filters.FilterGroup[0].name = ("KRUGERINC\" + $ext + " PRV Accounts" )
    # $NewEntry.filters.FilterGroup[0].sid = ( Get-ADGroup -Filter { name -like $FilterName } ).sid.value
    $NewEntry.filters.FilterOrgUnit[0].name = "ou=Production,ou=computers,$ou"

    $NewEntry.properties.description = "$ext Local Admins Append"
    $NewEntry.properties.deleteAllUsers = 0
    $NewEntry.properties.deleteAllGroups = 0
    $NewEntry.properties.removeAccounts = 0
    $NewEntry.filters.FilterGroup[0].not = 0
    $NewEntry.filters.RemoveChild($NewEntry.filters.FilterGroup[1])
    $NewEntry.filters.RemoveChild($NewEntry.filters.FilterOrgUnit[1])
    $NewEntry.filters.RemoveChild($NewEntry.filters.FilterGroup)
    $int = 1
    foreach ( $group in ($groups + "Production Techs")) {
        $groupName = "$ext $group"
        $NewEntry.Properties.Members.member[$int].name = "KRUGERINC\$groupName"
        $NewEntry.Properties.Members.member[$int].Sid = ((Get-ADGroup -Filter { name -eq $GroupName }).sid.value)
        $int++
    }
    $Admin.DocumentElement.AppendChild($NewEntry)
}


$item = $Admin.Groups.Group[0]
$item | ForEach-Object { $Admin.DocumentElement.RemoveChild($item) }
$item = $Admin.Groups.Group[0]
$item | ForEach-Object { $Admin.DocumentElement.RemoveChild($item) }

$Admin.Save("\\kruger.com\sysvol\kruger.com\Policies\{$guid}\machine\Preferences\Groups\Groups.xml")
