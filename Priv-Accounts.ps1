$computers = Get-ADOrganizationalUnit -Filter { name -eq "Computers" } | Where-Object {
    $_.Distinguishedname -like "ou=Computers,*,OU=Kruger Products,DC=kruger,DC=com" } | ForEach-Object {
    Get-ADComputer -SearchBase $_.distinguishedname -Filter { enabled -eq $true }  -Properties memberof | Where-Object { $_.distinguishedname -notlike "*OU=Production*" }
}

Invoke-Command -ComputerName $computers.name -ScriptBlock { try { Get-LocalGroupMember -Group administrators -ErrorAction Stop } catch { Get-LocalGroupMember -Group administrateurs } 
} | Tee-Object -Variable a

$kpextension = "BD", "BT", "CA", "CT", "EX", "GL", "GR", "JO", "KP External", "KP Shared", "LV", "LX", "MI", "MP", "NW", "OH", "QB", "SB", "SC", "SG", "SH", "TT"

$g = $kpextension | ForEach-Object {
(Get-ADGroup ($_ + " Server Admins" )).name 
(Get-ADGroup ($_ + " Site Admins" )).name 
(Get-ADGroup ($_ + " Site techs" )).name 
(Get-ADGroup ($_ + " Service Accounts Computer" )).name
    "Domain Admins"
    "Migration Admins-KP"
    "SPL\Domain Admins"
    "KP EUD Allowed Local Admins"
    "HO Server Admins"
    "HO Service Accounts Computer"
    "HO Site Admins"; "HO Site Techs"
}


function switch-location {
    param ($location) 
    switch ($location) {
        "OU=Bedford,OU=Kruger Products,DC=kruger,DC=com" { $extension = "BD" }
        "OU=Bentonville,OU=Kruger Products,DC=kruger,DC=com" { $extension = "BT" }
        "OU=Bromptonville,OU=Publication,DC=kruger,DC=com" { $extension = "BR" }
        "OU=Calgary,OU=Kruger Products,DC=kruger,DC=com" { $extension = "CA" }
        "OU=Corner Brook,OU=Publication,DC=kruger,DC=com" { $extension = "CB" }
        "OU=Crabtree,OU=Kruger Products,DC=kruger,DC=com" { $extension = "CT" }
        "OU=Elizabethtown,OU=Packaging,DC=kruger,DC=com" { $extension = "ET" }
        "OU=External,OU=Kruger Products,DC=kruger,DC=com" { $extension = "HO" }
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
    return $Extension
}

($a | Where-Object { $_.ObjectClass -EQ "group" -and $_.name.replace('KRUGERINC\', '') -notin $g } | Sort-Object -Unique pscomputername) | ForEach-Object {
    Get-ADComputer $_.PSComputerName | ForEach-Object {
        $ext = switch-location -location $_.distinguishedName.substring($_.distinguishedName.indexof("OU=Computers,") + 13) 
        Add-ADGroupMember -Identity ($ext + " prv accounts") -Members $_.Distinguishedname -WhatIf 
    }
}