## Original: https://gallery.technet.microsoft.com/How-to-remove-all-unknown-9d594f3a
## Author:   ALI TAJRAN
## Website: https://www.alitajran.com/remove-orphaned-sids/

param ($Action, $folder, $Opt)

$Forest = Get-ADRootDSE
$Domain = (Get-ADDomain).distinguishedname
$Conf = $Forest.configurationNamingContext
$Schema = $Forest.SchemaNamingContext
$ForestName = $Forest.rootDomainNamingContext
$DomainDNS = "DC=DomainDnsZones,$ForestName"
$ForestDNS = "DC=ForestDnsZones,$ForestName"

$domsid = (Get-ADDomain).domainsid.tostring()

if (($Action) -and ($Action.ToUpper() -like "/LIST")) { $Remove = $False; $OU = $False }
elseif (($Action) -and ($Action.ToUpper() -like "/LISTOU")) { $Remove = $False; $OU = $True }
elseif (($Action) -and ($Action.ToUpper() -like "/REMOVE")) { $Remove = $True; $OU = $False }
elseif (($Action) -and ($Action.ToUpper() -like "/REMOVEOU")) { $Remove = $True; $OU = $True }
else {
  Write-Host -Foregroundcolor 'Cyan' "SYNTAX: RemoveOrphanedSID-AD.ps1 [/LIST|/REMOVE|/LISTOU|/REMOVEOU[/DOMAIN|/CONF|/SCHEMA|/DOMAINDNS|/FORESTDNS|dn[/RO|/SP]"
  Write-Host -Foregroundcolor 'Cyan' "PARAM1: /LISTOU List only CNs&OUs /LIST List all objects, /REMOVE Clean all objects /REMOVEOU Clean only CNs&OUs"
  Write-Host -Foregroundcolor 'Cyan' "PARAM2: /DOMAIN Actual domain /CONF Conf. Part./SCHEMA /DOMAINDNS /FORESTDNS or a specific DN between double-quotes"
  Write-Host -Foregroundcolor 'Cyan' "OPTION1: /RO lists/Removes only objects with orphaned SIDs of the domain"
  Write-Host -Foregroundcolor 'Cyan' "OPTION2: /SP lists access permissions for all analyzed objects"
  Write-Host -Foregroundcolor 'Cyan' "If no DN is indicated, the current domain will be used"
  Write-Host -Foregroundcolor 'Cyan' "SAMPLE1 : RemoveOrphanedSID-AD.ps1 /REMOVEOU /DOMAIN /RO"
  Write-Host -Foregroundcolor 'Cyan' 'SAMPLE2 : RemoveOrphanedSID-AD.ps1 /LIST "OU=MySite,DC=Domain,DC=local"'
  Break
}

# Start transcript
$Logs = "C:\temp\RemoveOrphanedSID-AD.txt"
Start-Transcript $Logs -Append -Force

if (($Folder) -and ($Folder.ToUpper() -like "/CONF")) { $Folder = $Conf }
elseif (($Folder) -and ($Folder.ToUpper() -like "/SCHEMA")) { $Folder = $Schema }
elseif (($Folder) -and ($Folder.ToUpper() -like "/DOMAIN")) { $Folder = $Domain }
elseif (($Folder) -and ($Folder.ToUpper() -like "/DOMAINDNS")) { $Folder = $DomainDNS }
elseif (($Folder) -and ($Folder.ToUpper() -like "/FORESTDNS")) { $Folder = $ForestDNS }
elseif (($Folder) -and ($Folder.ToUpper() -match "DC=*")) { Write-Host "This DistinguishedName will be analyzed: $Folder" -ForegroundColor Cyan }
else { $folder = $domain; Write-Host "This current domain will be analyzed: $Domain" -ForegroundColor Cyan }

Write-Host "Analyzing the following object: $Folder" -ForegroundColor Cyan

if (($Opt) -and ($Opt.ToUpper() -like "/RO")) { $Show = $False } Else { $Show = $True }
if (($Opt) -and ($Opt.ToUpper() -like "/SP")) { $ShowPerms = $True } Else { $ShowPerms = $False }

# Functions list
function RemovePerms($fold) {
  $f = get-item "Microsoft.ActiveDirectory.Management.dll\ActiveDirectory:://RootDSE/$fold"
  $fName = $f.distinguishedname
  If ($Show) { Write-Host $fname }
  $x = [System.DirectoryServices.ActiveDirectorySecurity](get-ACL "Microsoft.ActiveDirectory.Management.dll\ActiveDirectory:://RootDSE/$f")
  if ($ShowPerms) { Write-Host $x.access | Sort-Object -property IdentityReference -unique | Format-Table -auto IdentityReference, IsInherited, AccessControlType, ActiveDirectoryRights }
  $mod = $false
  $OldSID = ""

  foreach ($i in $x.access) {
    if ($i.identityReference.value.tostring() -like "$domsid*") {
      $d = $i.identityReference.value.tostring()
      if ($OldSid -ne $d) { Write-Host "Orphaned SID $d on $fname" -ForegroundColor Yellow; $OldSid = $d }
      if ($Remove) { $x.RemoveAccessRuleSpecific($i) ; $Mod = $True }
    }
  }
  # Write-Host $x.access
  if ($mod) { Set-ACL -aclobject $x -path "Microsoft.ActiveDirectory.Management.dll\ActiveDirectory:://RootDSE/$f"; Write-Host "Orphaned SID removed on $fname" -ForegroundColor Red }
}

Function RecurseFolder($fold) {
  $f = $fold
  # If ($Show) { Write-Host $f }
  If ($OU) { $ListFold = get-childitem "Microsoft.ActiveDirectory.Management.dll\ActiveDirectory:://RootDSE/$f" -force | Where-Object { ($_.ObjectClass -like "container") -or ($_.ObjectClass -like "OrganizationalUnit") } }
  Else { $ListFold = get-childitem "Microsoft.ActiveDirectory.Management.dll\ActiveDirectory:://RootDSE/$f" -force }
  foreach ($e in $ListFold) {
    $FD = $e.Distinguishedname
    # Write-Host $FD
    RemovePerms $FD     
  }
  foreach ($e in $ListFold) { RecurseFolder($e.Distinguishedname) }
}

# Start
RemovePerms($Folder)
RecurseFolder($Folder)

Stop-Transcript