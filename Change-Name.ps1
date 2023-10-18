Get-ADOrganizationalUnit -Filter { name -like "standard users" } | ForEach-Object {
    Get-ADUser -SearchBase $_.distinguishedName -Filter { enabled -eq $true -and Proxyaddresses -like "*" } -Properties proxyaddresses , displayname | Where-Object {
        $_.displayname -like ( "*,*") } | ForEach-Object {
        $a , $b, $c = $_.displayname.split(",").split("("); if ($c) { $c = " (" + $c } ; $b.trim() + " " + $a.trim()  + $c 
    }
}
