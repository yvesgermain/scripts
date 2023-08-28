$acl = import-csv '\\GRSVFP01\c$\temp\ntfs\GRSVFP01-D.csv'
$acl | Where-Object {
    $_.folder -like "D:\Groups\Serveur Richelieu (R)\*" -and $_.identityreference -like "*kpl*" -and $_.folder -notlike "*Transformation*"
} | Sort-Object  -Property  folder, identityreference, FileSystemRights -unique | Select-Object @{ name = "IdentityReference" ;e = {$_.identityreference.replace('KRUGERINC\',"")}}, @{ name = "Folder" ;e= { $_.folder.replace('D:\Groups\Serveur Richelieu (R)\',"")}}, @{name = "Depth" ;e = {$_.folder.replace('D:\Groups\Serveur Richelieu (R)\',"").split('\').count}}


$acl = Import-Csv '\\GRSVFP01\c$\temp\ntfs\GRSVFP01-D.csv'

$acl | Where-Object {
    $_.identityreference -like "*KPLR*" -and $_.Folder -like "D:\Groups\Serveur Richelieu (R)\*"
} | Select-Object @{ name = "IdentityReference" ; e = { $_.identityreference.replace('KRUGERINC\', "") } }, 
@{name = "Depth" ; e = { $_.folder.replace('D:\Groups\Serveur Richelieu (R)\', "").replace("D:\Groups\", "").replace("D:\Public\", "").split('\').count } },
@{ name = "Folder" ; e = { $_.folder.replace('D:\Groups\Serveur Richelieu (R)\', "").replace("D:\Groups\", "").replace("D:\Public\", "") }
} | Sort-Object -Unique folder | ForEach-Object { $folder = Remove-Diacritics $_.folder; $a = $folder.split("\").trim()
    $b = $a | ForEach-Object { if ($_.indexof(" ") -gt 1 ) { $length = $_.indexof(" ") } else { if ($_.length -lt 6 ) { $length = $_.length } else { $length = 6 } }; $_.substring(0, $length).trim() } ; "GRSVFP01_" + ($b -join ("_"))
}