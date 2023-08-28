$date = (Get-date).AddMonths(-3)
Get-ADComputer -Filter { 
    operatingsystem -like "*windows*" -and operatingsystem -notlike "*server*" -and lastlogondate -lt $date 
} -Properties operatingsystem, lastlogondate | Where-Object { 
    $_.distinguishedName -notlike "*OU=Production,*" -and $_.distinguishedName -notlike "*OU=DisabledComputers,DC=kruger,DC=com" 
} | ForEach-Object { $Computer = $_
    $location = try {
        $_.distinguishedname.substring($_.distinguishedname.indexof("OU=Computers,") + 13)
    }
    catch { $location = "Unknown" } 
    switch ($location) {
        "OU=Bedford,OU=Kruger Products,DC=kruger,DC=com" { $extension = "BD" }
        "OU=Bentonville,OU=Kruger Products,DC=kruger,DC=com" { $extension = "BT" }
        "OU=Bromptonville,OU=Publication,DC=kruger,DC=com" { $extension = "BR" }
        "OU=Calgary,OU=Kruger Products,DC=kruger,DC=com" { $extension = "CA" }
        "OU=Corner Brook,OU=Publication,DC=kruger,DC=com" { $extension = "CB" }
        "OU=Crabtree,OU=Kruger Products,DC=kruger,DC=com" { $extension = "CT" }
        "OU=Elizabethtown,OU=Packaging,DC=kruger,DC=com" { $extension = "ET" }
        "OU=External,OU=Kruger Products,DC=kruger,DC=com" { $extension = "HO" }
        "OU=Energy,DC=kruger,DC=com" { $extension = "NR"}
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
        "OU=Paperboard,OU=Packaging,DC=kruger,DC=com" {$extension = "PB" } 
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
        default { $extension = "Unknown" }
    }
    Disable-ADAccount -Identity $computer -Verbose -WhatIf
    Move-ADObject -Identity $computer -TargetPath ("ou=" + $extension + ",OU=DisabledComputers,DC=kruger,DC=com") -Verbose -WhatIf 
}
