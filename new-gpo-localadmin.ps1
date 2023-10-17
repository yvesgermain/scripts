$groups = @(
    "Server Admins",
    "Service Accounts Computer",
    "Site Admins",
    "Site Techs")

$domainName = "Kruger.com"
$extension = "BD", "BR", "BT", "CA", "CB", "CT", "ET", "EX", "GL", "GR", "HO", "JO", "KK", "KL", "LS", "LV", "LX", "MI", "MP", "NR", "NW", "OH", "PB", "PD", "QB", "SB", "SC", "SG", "SH", "TR", "TT", "TU", "WA"
$gpoBackupFolderFullPath = "C:\GPO-backup\"

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
        "PP" { $Extension = "Shared Services" ; $BusinessUnit = "Publication" ; $resp = "" }
        "KK" { $Extension = "Shared Services" ; $BusinessUnit = "Packaging"; $resp = "" }
        "SH" { $Extension = "Sherbrooke"  ; $BusinessUnit = "Kruger Products" ; $resp = "richard.perras@kruger.com" }
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


Write-Output "Restore GPO GPP Print Server Template from Backup.  Give it time to replicate to all domain controllers."

Write-Output "Using COM objects. Restore-GPO won't restore a GPO if the GPO is deleted!"

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

"New GPO removal of Local Admins Rights"

$GPOName = "Test - Removal of Local Admins Rights - YG"
"If $GPOName exist, delete it"
if (Get-GPO -Name $GPOName -ErrorAction SilentlyContinue ) { Remove-GPO -Name $GPOName }
$newgpo = Copy-GPO -SourceName "KR Removal of Local Admins Rights" -TargetName $gponame
$newgpo.description = "GPO to add groups to the local administrators group"
$guid = $newgpo.id.guid
$GPP_Admin_XMLPath = "\\hospdc01\D`$\Windows\SYSVOL\sysvol\Kruger.com\Policies\{$guid}\machine\Preferences\Groups\Groups.xml"
$Admin = New-Object -TypeName XML
$Admin.load($GPP_Admin_XMLPath)
# [XML]$Admin = (Get-Content -Path $GPP_Admin_XMLPath)


"Creating " + $newgpo.displayname + " from KR Removal of Local Admins Rights"
foreach ( $ext in $extension) {

    $OU = Find-OU -site $ext
    foreach ( $Action in "Append", "OverRide") {
        $NewEntry = $Admin.Groups.Group[0].Clone()
#         $Newentry.filters.FilterGroup[1].RemoveAll()
        $CurrentDateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $newguid = [System.Guid]::NewGuid().toString()
        $NewEntry.Changed = "$CurrentDateTime"
        $NewEntry.uid = "{ " + "$newguid" + " }"
        $FilterName = $ext + " PRV Accounts"; 
        $NewEntry.filters.FilterGroup[0].name = ("KRUGERINC\" + $ext + " PRV Accounts" )
        $NewEntry.filters.FilterGroup[0].sid = ( get-adgroup -filter {name -like $FilterName} ).sid.value
        $NewEntry.filters.FilterOrgUnit[0].name = "ou=desktop,ou=computers,$ou"
        $NewEntry.filters.FilterOrgUnit[1].name = "ou=Laptop,ou=computers,$ou"
        $NewEntry.filters.FilterGroup[1].name = ("KRUGERINC\" + $ext + " PRV Accounts" )
        $NewEntry.filters.FilterGroup[1].sid = ( get-adgroup -filter {name -like $FilterName} ).sid.value
        if ( $Action -eq "Append") {
            $NewEntry.properties.description = "$ext Local Admins Append YG"
            $NewEntry.properties.deleteAllUsers = 0
            $NewEntry.properties.deleteAllGroups = 0
            $NewEntry.properties.removeAccounts = 0
            $NewEntry.filters.FilterGroup[0].not = 0
        }
        if ( $Action -eq "OverRide") {
            $NewEntry.properties.description = "$ext Local Admins YG"
            $NewEntry.properties.deleteAllUsers = 1
            $NewEntry.properties.deleteAllGroups = 1
            $NewEntry.properties.removeAccounts = 1
            $NewEntry.filters.FilterGroup[0].not = 1
            $NewEntry.filters.FilterGroup[1].not = 1
        }
        foreach ( $group in $groups) {
            $int = 1
            $groupName = "KRUGERINC\$ext $group"
            foreach ( $group in $groups) {
                $groupName = "$ext $group"
                $NewEntry.Properties.Members.member[$int].name = "KRUGERINC\$groupName"
                $NewEntry.Properties.Members.member[$int].Sid = ((Get-ADGroup -Filter { name -eq $GroupName }).sid.value)
                $int++
            }
        }
        $Admin.DocumentElement.AppendChild($NewEntry)
    }
}
$item = $Admin.Groups.Group | Where-Object {$_.Properties.description -notmatch "YG$"}
$item |ForEach-Object { $Admin.DocumentElement.RemoveChild($_)}
$Admin.Save($GPP_Admin_XMLPath)

$Admin.DocumentElement.RemoveChild($Admin.DocumentElement.SharedPrinter[0])
$Admin.Save($GPP_Admin_XMLPath)
$GPP_PRT_XMLPath = "\\hospdc01\D$\Windows\SYSVOL\sysvol\$domainName\Policies\{$guid}\machine\Preferences\Groups\Groups.xml"
[XML]$Admin = (Get-Content -Path $GPP_PRT_XMLPath)
$Admin.DocumentElement.RemoveChild($Admin.DocumentElement.SharedPrinter[0])
$Admin.Save($GPP_Admin_XMLPath)

# New-GPLink -Name $gponame -Target "ou=Standard Users, ou=Users, OU=$location, OU=$BusinessUnit, DC=kruger, DC=com" -LinkEnabled Yes


######################################################
# Document creation
[xml]$xmlDoc = New-Object system.Xml.XmlDocument
$xmlDoc.LoadXml("<?xml version=`"1.0`" encoding=`"utf-8`"?><Groups></Groups>")

#3 Creation of a node and its text
$xmlElt = $xmlDoc.CreateElement("Group")

# Creation of an attribute in the principal node
$xmlAtt = $xmlDoc.CreateAttribute("clsid")
$xmlAtt.Value = "{6D4A79E4-529C-4481-ABD0-F5BD7EA93BA7}"
$xmlElt.SetAttribute($xmlAtt)

$xmlElt.AppendChild($xmlText)
$xmlElt.Attributes.Append($xmlAtt)

# Store to a file 
$xmlDoc.Save("c:\Temp\Fic.xml")