Import-Module -name iPv4Calc
$sites = get-adreplicationSubnet -Filter * | Select-Object name, site

$result = foreach ( $inc in 0..($sites.count - 1)) {
    foreach ($count in (0..($sites.count - 1))) {
        if (Test-IPv4SubnetOverlap @($sites[$count].name , $sites[$inc].name)) { 
            $sites[$inc] | Select-Object @{ name = "IncSubnet"; e = { $_.name } },
            @{name = "Inc" ; e = { $inc } }, 
            @{name = "IncSite" ; e = { $sites[$inc].site.replace("CN=", "").split(",")[0] } }, 
            @{name = "CountSubnet" ; e = { $sites[$count].name } }, 
            @{name = "Count" ; e = { $Count } }, 
            @{name = "CountSite" ; e = { $Sites[$count].site.replace("CN=", "").split(",")[0] } }
        } 
    } 
} 

$result = $result | Where-Object { $_.inc -lt $_.count }
$result | Format-Table

$DC = (Get-ADDOMAINCONtroller -filter { name -notlike "GRSVDC01" }).name
$DC | Where-Object { $_ -notlike "169.254.*" } | ForEach-Object -Parallel { 
    Get-Content \\$_\admin$\debug\netlogon.log -tail 200 | ForEach-Object {
        $start = $_.lastindexof(" ") + 1; 
        $end = $_.lastindexof("."); 
        $_.substring( $start, ($end - $start))
    }
} | Group-Object -NoElement

$DC | ForEach-Object -Parallel {
    Get-Content \\$_\admin$\debug\netlogon.log -tail 200 | Where-Object { $_ -notlike "*169.254.*" } | ForEach-Object {
        $start = $_.lastindexof(" ") + 1;
        $end = $_.lastindexof(".");
        $short = $_.substring( $start, ($end - $start)) ; $long = $_.substring( $start, ($_.length - $start)) ;
        $_ | Select-Object @{name = "Short" ; e = { $short } }, @{ name = "Long" ; e = { $long } }
    } 
} | Sort-Object long -Unique | Group-Object Short