Get-ADOrganizationalUnit -Filter { name -like "standard users" } | ForEach-Object {
    Get-ADUser -SearchBase $_.distinguishedName -Filter { enabled -eq $true -and Proxyaddresses -like "*" } -Properties proxyaddresses , displayname | Where-Object {
        $_.displayname -like ( "*,*") } | Select-Object @{
            name = "New DisplayName"; e = { $a , $b, $c = $_.displayname.split(",").split("("); if ($c) {$c = " (" + $c.trim() }; $b.trim() + " " + $a.trim() + $c 
        }
    }, displayname
} | Format-Table -AutoSize

$date = (Get-Date).AddDays(-2)
Get-WinEvent -ComputerName grsvps01 -FilterHashtable @{ LogName='security'; StartTime=$Date; Id='4672','4648' ;data= "administrator" }