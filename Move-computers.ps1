$date = (get-date).AddMonths(-3)
$Scrap = Get-ADComputer -Searchbase 'CN=Computers,DC=kruger,DC=com' -Properties lastlogondate, operatingsystem, IPv4Address -filter { (enabled -eq $true) -and (Lastlogondate -gt $date) }  | Where-Object { $_.operatingsystem -like "Windows*" } | Select-Object name, operatingsystem, @{name = "site" ; e = { $_.name.substring(0, 2) } }, IPv4Address
$sites = get-adreplicationSubnet -Filter * | Select-Object name, site

$ok = $scrap| ForEach-Object {
        switch ( $_.site) {
            "BD" { $Extension = "Bedford"  ; $BusinessUnit = "Kruger Products"; $resp = "samuel.ponsot@kruger.com" }
            "BT" { $Extension = "BentonVille"  ; $BusinessUnit = "Kruger Products" ; $resp = "jeff.stark@kruger.com" }
            # "BA" { $Extension = "Brampton"  ; $BusinessUnit = "Kruger Products" ; $resp = "luis.cerda@kruger.com" }
            "BR" { $Extension = "Bromptonville"  ; $BusinessUnit = "Publication" ; $resp = "richard.perras@kruger.com" }
            "BF" { $Extension = "Brassfield" ; $BusinessUnit = "Energy" ; $resp = "" }
            "CA" { $Extension = "Calgary"  ; $BusinessUnit = "Kruger Products" ; $resp = "steven.yatar@kruger.com" }
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
            "KP" { $Extension = "Shared Services" ;$BusinessUnit = "Kruger Products" ; $resp = ""}
            "PP" { $Extension = "Shared Services" ;$BusinessUnit = "Publication" ; $resp= "" }
            "KK" { $Extension = "Shared Services" ;$BusinessUnit = "Packaging"; $resp= "" }
            "SH" { $Extension = "Sherbrooke"  ; $BusinessUnit = "Kruger Products" ; $resp = "richard.perras@kruger.com" }
            "SG" { $Extension = "Sungard"  ; $BusinessUnit = "Kruger Products" ; $resp = "" }
            "TT" { $Extension = "Trenton"  ; $BusinessUnit = "Kruger Products" ; $resp = "Eric.Matthews@krugerproducts.ca" }
            "TR" { $Extension = "Trois-Rivieres"  ; $BusinessUnit = "Publication" ; $resp = "richard.beland@kruger.com" }
            "TU" { $Extension = "Turcal"  ; $BusinessUnit = "Recycling" ; $resp = "filippo.campo@kruger.com" }
            "WA" { $Extension = "Wayagamack"  ; $BusinessUnit = "Publication" ; $resp = "jean-sebastien.roy2@kruger.com" }
            Default { $Extension = $null  ; $BusinessUnit = $null ; $resp = $null }
        }
        $ou = $null
        if ($null -ne $Extension) {
            if ( $BusinessUnit -eq "Head Office" ) { $insert = $Extension + ",DC=kruger,DC=com" } else { $insert = $Extension + ",OU=" + $BusinessUnit + ",DC=kruger,DC=com" }
            if ($_.operatingsystem -like "Windows Server*") { $ou = "OU=Servers,OU=" + $insert }
            if ( $_.name.substring(2, 1) -eq "D") { $ou = "OU=Desktop,OU=Computers,OU=" + $insert }
            if ( $_.name.substring(2, 1) -eq "L") { $ou = "OU=mobile,OU=computers,OU=" + $insert } 
        }
        foreach ( $site in $sites) {
        if ($_.ipv4address) {
            if ((Test-IPv4inSubnet -IP $_.ipv4address -SubnetCIDR $site.name ) -eq $true ) {
                $_ | Select-Object name , operatingsystem, Ipv4address , @{ name = "Distinguised Site Name"; e = { $site.Site } }, @{ name = "OU" ; e = { $ou } }, @{ name = "Resp"; e = { $resp } }
            }
        }
    }
}
$ok | Format-Table -AutoSize

Move-ADObject -Identity $_.DistinguishedName -TargetPath $ou

$sites = get-adreplicationSubnet -Filter * | Select-Object name, site
$siteip = $sites | Group-Object site | Select-Object @{ name = "Site" ; e ={ $_.name.replace(",CN=Sites,CN=Configuration,DC=kruger,DC=com", "").replace("CN=", "") }}, @{ name = "IP" ; e = { $_.group.name } }
$servers = get-adcomputer  -Properties lastlogondate, IPv4Address, operatingsystem -filter { operatingsystem -like "Windows server*" -and enabled -eq $true } | Where-Object { $null -ne $_.ipv4address } 
foreach ( $server in $servers) {
    $siteIP | ForEach-Object { $site = $_.site; $_.ip | ForEach-Object { if ( Test-IPinSubnet -IP ($server).IPv4Address  -SubnetCIDR $_) { $_ | Select-Object @{ name = "Server" ; e = { $server.name } }, @{name = "Site" ; e = { $site } } }
        }
    }
} 
$a = foreach ( $server in $servers) {
    $siteIP | ForEach-Object { $site = $_.site; $_.ip | ForEach-Object { 
            if ( Test-IPinSubnet -IP ($server).IPv4Address -SubnetCIDR $_) {
                $_ | Select-Object @{ name = "Server" ; e = { $server.name } }, @{name = "Site" ; e = { $site } } 
            }
        }
    }
}
$a | Group-Object site 