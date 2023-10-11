$baseOU = "OU=Desktops,OU=Computers", "OU=Mobile,OU=Computers", "OU=Production,OU=Computers", "OU=Distribution,OU=Groups", "OU=GPO,OU=Groups", "OU=Printers,OU=Groups", "OU=Management,OU=Servers", "OU=Terminal Servers,OU=Servers", "OU=TS Users,OU=Users", "OU=Account Admins,OU=Users", "OU=Privileged,OU=Users", "OU=Production Techs,OU=Users", "OU=Resources,OU=Users", "OU=Server Admins,OU=Users", "OU=Service Accounts,OU=Users", "OU=Site Admins,OU=Users", "OU=Site Techs,OU=Users", "OU=Standard Users,OU=Users", "OU=LockDown Users,OU=Standard Users,OU=Users"  
$sites = "BD", "BT", "BA", "BR", "BF", "CA", "CB", "CT", "ET", "HO", "KR", "JO", "KL", "KK", "LS", "GL", "LV", "LX", "LF", "MP", "KT", "KL", "MI", "NW", "OH", "PD", "PB", "PM", "QB", "GR", "SC", "KP", "PP", "KK", "SH", "SG", "TT", "TR", "TU", "WA"
$ext = "BD", "BR", "BT", "CA", "CB", "CT", "ET", "EX", "GL", "GR", "HO", "JO", "KK", "KL", "LS", "LV", "LX", "MI", "MP", "NR", "NW", "OH", "PB", "PD", "QB", "SB", "SC", "SG", "SH", "TR", "TT", "TU", "WA"
$groups = "Account admins", "Site admins", "Site Techs", "production techs", "Server admins"

$sites | ForEach-Object { switch ($_) {
        "BD" { $Extension = "Bedford"  ; $BusinessUnit = "Kruger Products"; $resp = "samuel.ponsot@kruger.com" }
        "BT" { $Extension = "BentonVille"  ; $BusinessUnit = "Kruger Products" ; $resp = "jeff.stark@kruger.com" }
        # "BA" { $Extension = "Brampton"  ; $BusinessUnit = "Kruger Products" ; $resp = "luis.cerda@kruger.com" }
        "BR" { $Extension = "Bromptonville"  ; $BusinessUnit = "Publication" ; $resp = "richard.perras@kruger.com" }
        "BF" { $Extension = "Brassfield" ; $BusinessUnit = "Energy" ; $resp = "" }
        "CA" { $Extension = "Calgary"  ; $BusinessUnit = "Kruger Products" ; $resp = "steven.yatar@kruger.com" }
        "EX" { $Extension = "External";  $BusinessUnit = "Kruger Products" ; $resp = ""}
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
    } $baseOU | ForEach-Object {
        $NewOU = "$_,$ou"
        $base = $_;
        try { Get-ADOrganizationalUnit -Identity "$NewOU" > $null } catch { $base }
    }
} | Group-Object -NoElement | Format-Table -AutoSize

foreach ( $group in $groups) {
    foreach ($x in $ext) {
        $name = "$x $group" 
        Get-ADGroup -Filter { name -like $Name } | Where-Object {$_.distinguishedName -notlike "*ou=$group*"} | Select-Object name, distinguishedName
    }
}

Get-ADGroup -Filter { name -like "* bu admins" } | Select-Object distinguishedname

