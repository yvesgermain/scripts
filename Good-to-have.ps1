$dfs = @{} 
Get-DfsnRoot -Domain kruger.com | ForEach-Object {
    Get-DfsnFolder -Path ($_.path + "\*") | ForEach-Object { 
        Get-DfsnFolderTarget -Path $_.path | Where-Object { $_.state -eq "Online" }
    }
} | ForEach-Object { $dfs[$_.TargetPath] = $_.Path }

Remove-Variable case, oldcase, MapDrive, path, ismember
$spllogon = Get-Content C:\scripts\spllogon.vbs | Where-Object {
    $_ -notmatch "^'" -and ($_ -match "if isMember" -or $_ -match "MapDrive" -or $_ -match "case" -or $_ -match "End Select" )
} | ForEach-Object {
    if ($_ -match "End Select") { Remove-Variable case, oldcase, MapDrive, path, ismember; }
    if ($_ -match "Case " -and $_ -notlike "*Select Case network*") { $case = $_ }
    if ($_ -match "MapDrive ") { $MapDrive , $path = $_.split(",") }
    if ($_ -match "if isMember") { $isMember = $_.split('"')[1] } else { $isMember = $null }
    if ($case -and $case -eq $oldcase -and $IsMember -eq $null) {
        $_ | Select-Object @{Name = "Letter" ; e = { $MapDrive.split('"')[1].replace(":", "") } },
        @{Name = "Path"; e = { $path.replace('"', "") } },
        @{name = "Subnet" ; e = { $case.split('"')[1] } },
        @{Name = "OU"  ; e = { "OU=" + ($case.replace('"', "").split("'")[1]) } },
        @{Name = "Group"; e = { $OldIsMember } }
    }
    $oldcase = $case; $oldIsMember = $isMember
}

# $spllogon | Where-Object { $_.path -notlike "*\ & UserName & $" } | ForEach-Object {
#     $path = $_.path.replace(".kruger.com", "").tolower()  
#     if ( $dfs[$path]) { 
#         $_.path = $dfs[$path] 
#     }
# }

function Convert-kix2drive {
    param($File)
    # if ($case)  { Remove-Variable case }
    # if ($path ) { Remove-Variable path}
    # if ($group) { Remove-Variable path}
    Get-Content $file | Where-Object {
        -not [String]::IsNullOrWhiteSpace($_) -and $_ -notmatch "^;" } | ForEach-Object {
        if ($_ -like "Function*" -or $_ -like "EndFunction") {
            if ( $_ -like "Function*") { $Read = $False } else {
                if ($_ -like "EndFunction") { $Read = $true }
            }
        }
        if ($Read -ne $false -and $_ -notlike "EndFunction") {
            $_  | ForEach-Object {
                if ($_ -match "CASE ") {
                    if ($_ -like "*Case 1*") {
                        $OU = ""
                    }
                    else {
                        $OU = $_.split('"')[1].split(",")[0]
                    }
                }
            }
            if ($_ -match "InGroup") {
                $group = $_.split('"')[1, 3, 5]
                if ($group -is "array") { $group = [string]::join(",", $group) }
            }
            if ($_ -match "use ") {
                $string = $_.trim()
                $scrap, $letter, $path = $string.split(" "); $letter = ($letter -replace ("use " , "")).trim() -replace (":", "")
                if ($path -notlike "\\") { $Option1, $Option2 = $path.split(" ", [StringSplitOptions]::RemoveEmptyEntries); Remove-Variable Path }
                $_ | Select-Object @{ name = "OU" ; e = { $OU } }, @{name = "Group" ; e = { $group } }, @{name = "letter" ; e = { $letter } }, @{ name = "Path"; e = { $path } }, @{name = "Option1" ; e = { $option1 } }, @{name = "Option2" ; e = { $option2 } }
            }

            if ($_ -match 'AddDisk') {
                $string = $_.replace(')', "")
                $letter, $Share, $server = $string.split(",", [StringSplitOptions]::RemoveEmptyEntries)
                $Letter = $Letter.split('"')[1].trim()
                $Share = $Share.trim()
                $folder = '\\' + $Server.replace('"', "").trim() + '\' + $share.replace('"', "").trim()
                $letter = $letter.replace(":", "").replace('"', "").trim()
                $_ | Select-Object @{name = "Letter" ; e = { $letter } },
                @{name = "Group"; e = { $group } },
                @{name = "OU"; e = { $OU } },
                @{name = "Path" ; e = { $Folder.replace('"', "") } },
                @{name = "Action" ; e = { "" } }
                if ($letter) { Remove-Variable letter }
                If ($folder) { Remove-Variable folder }
                if ($group) { Remove-Variable group }
                # if ($path) { Remove-Variable path }
                if ($case) { Remove-Variable case }
                Remove-Variable String
            }
        }
    }
}

if ($case) { Remove-Variable case }
$tr = Get-Content c:\scripts\TrLogon.kix | Where-Object {
    -not [String]::IsNullOrWhiteSpace($_) -and $_ -notmatch "^;" } | ForEach-Object {
    if ($_ -like "Function*" -or $_ -like "EndFunction") {
        if ( $_ -like "Function*") { $Read = $False } else {
            if ($_ -like "EndFunction") { $Read = $true }
        }
    }
    if ($Read -ne $false -and $_ -notlike "EndFunction") {
        $_  | ForEach-Object {
            if ($_ -match "InGroup") {
                $case = $_.split('"')[1]
            }
            if ($_ -match "AddNewDisk") {
                $string = $_.replace(')', "")
                $server, $share, $Share2, $letter, $option1 = $string.split(",", [StringSplitOptions]::RemoveEmptyEntries)
                $server = $server.replace('   AddNewDisk  ( "', "").replace('"', "").trim()
                $folder = '\\' + $Server + '\' + $share.trim() + '\' + $Share2.trim()
                $letter = $letter.replace('"', "")
                $option1 = $option1.replace('"', "")
                $_ | Select-Object @{name = "Letter" ; e = { $letter.replace(":", "").trim() } },
                @{name = "Group"; e = { $case } },
                @{name = "Path" ; e = { $Folder.replace('"', "") } },
                @{name = "User"; e = { $user.replace('/user:', "") } },
                @{name = "Password"; e = { $pwd.replace('/password:', "") } },
                @{name = "Option1"; e = { $option1.trim() } },
                @{name = "Option2"; e = { $option2 } },
                @{name = "Action" ; e = { "" } }
                if ($letter) { Remove-Variable letter }
                If ($folder) { Remove-Variable folder }
                if ($pwd) { Remove-Variable pwd }
                if ($user) { Remove-Variable user }
                if ($option1) { Remove-Variable Option1 }
                if ($OPtion2) { Remove-Variable option2 }
                if ($group) { Remove-Variable group }
                if ($path) { Remove-Variable path }
                if ($case) { Remove-Variable case }
                Remove-Variable String

            }
            if ($_ -match 'AddDisk') {
                $string = $_.replace(')', "")
                $Server, $Share, $letter, $option1 = $string.split(",", [StringSplitOptions]::RemoveEmptyEntries)
                $Server = $server.split('"')[1].trim()
                $Share = $Share.trim()
                $folder = '\\' + $Server + '\' + $share
                $letter = $letter.replace(":", "").replace('"', "").trim()
                $option1 = $option1.replace('"', "")
                $_ | Select-Object @{name = "Letter" ; e = { $letter.replace(":", "") } },
                @{name = "Group"; e = { $case } },
                @{name = "Path" ; e = { $Folder.replace('"', "") } },
                @{name = "User or Group"; e = { $user.replace('/user:', "") } },
                @{name = "Password"; e = { $pwd.replace('/password:', "") } },
                @{name = "Option1"; e = { $option1.trim() } },
                @{name = "Option2"; e = { $option2 } }
                if ($letter -or $path) { Remove-Variable letter }
                If ($folder) { Remove-Variable folder }
                if ($pwd) { Remove-Variable pwd }
                if ($user) { Remove-Variable user }
                if ($option1) { Remove-Variable Option1 }
                if ($OPtion2) { Remove-Variable option2 }
                if ($group) { Remove-Variable group }
                if ($path) { Remove-Variable path }
                if ($case) { Remove-Variable case }
                Remove-Variable String
            }
            if ($_ -match "CASE ") {
                $case = $_.Replace('CASE $USER = "', "").replace('"', "")
            }
            if ($_ -match "use ") {
                $string = $_.trim()
                $scrap, $letter, $path = $string.split(" "); $letter = ($letter -replace ("use " , "")).trim()
                if ($string -like "*\\*") { $folder , $user, $pwd = $Path.split(" ", [StringSplitOptions]::RemoveEmptyEntries) }
                if ($string -notlike "*\\*") { $option1, $option2 = $path.trim().split(" ", [StringSplitOptions]::RemoveEmptyEntries) }
                $_ | Select-Object @{name = "Letter" ; e = { $letter.replace(":", "") } },
                @{name = "Group"; e = { $case } },
                @{name = "Path" ; e = { $Folder.replace('"', "") } },
                @{name = "User"; e = { $user.replace('/user:', "") } },
                @{name = "Password"; e = { $pwd.replace('/password:', "") } },
                @{name = "Option1"; e = { $option1.trim() } },
                @{name = "Option2"; e = { $option2 } }
                if ($letter) { Remove-Variable letter }
                If ($folder) { Remove-Variable folder }
                if ($pwd) { Remove-Variable pwd }
                if ($user) { Remove-Variable user }
                if ($option1) { Remove-Variable Option1 }
                if ($OPtion2) { Remove-Variable option2 }
                if ($group) { Remove-Variable group }
                if ($path) { Remove-Variable path }
                if ($case) { Remove-Variable case }
                Remove-Variable String
            }
        }
    }
}
$tr | Format-Table -AutoSize

$CB = Get-Content \\kruger.com\NETLOGON\cb\LoginCB.kix | Where-Object {
    -not [String]::IsNullOrWhiteSpace($_.group.OU) -and $_ -notlike "*;*" } | ForEach-Object {
    $case = ""
    if ($_ -match "use ") { $letter, $path = $_.replace('"', "").split(":"); $letter = $letter.replace("use " , "").trim() }
    if ($_ -match "If INGROUP") { $isMember = $_.split('"')[1] }  else { $isMember = $null }
    if ($IsMember -eq $null -and $oldIsMember -ne $null) {
        $_ | Select-Object @{name = "OU" ; e = { $case } },
        @{name = "Letter"; e = { $letter } },
        @{ name = "Path" ; e = { $path.trim() } },
        @{ name = "Group"; e = { $OldIsMember } },
        @{name = "OrgUnit" ; e = { "" } },
        @{name = "Filtergroup" ; e = { "" } },
        @{name = "Label" ; e = { "" } },
        @{name = "Action" ; e = { "" } }
        if ($letter) { Remove-Variable letter }
        If ($folder) { Remove-Variable folder }
        if ($pwd) { Remove-Variable pwd }
        if ($user) { Remove-Variable user }
        if ($option1) { Remove-Variable Option1 }
        if ($OPtion2) { Remove-Variable option2 }
        if ($group) { Remove-Variable group }
        if ($path) { Remove-Variable path }
        if ($case) { Remove-Variable case }
    }
    $oldIsMember = $isMember
}

$ho = convert-kix2Drive c:\scripts\kixtart.kix

$LS = convert-kix2Drive c:\scripts\kkLogin_ls.kix

$PD = convert-kix2Drive c:\scripts\kkLogin_pd.kix

$PB = convert-kix2Drive c:\scripts\kkLogin_pb.kix

$ET = convert-kix2Drive c:\scripts\kkLogin_et.kix

$TU = convert-kix2Drive c:\scripts\kklogin_TU.kix

$ho + $CB + $ls + $PD + $PB + $ET + $TU | Where-Object { $_.PATH -notlike "*\@userid+$" } | Select-Object Letter, Path, @{name = "OrgUnit" ; e = { "" } }, OU, @{name = "Filtergroup" ; e = { "" } }, @{name = "Label" ; e = { "" } }, Group | Sort-Object -Unique -Property Letter, Path, OU, Group | Format-Table

$xx = $spllogon + $ho + $CB + $ls + $PD + $PB + $ET + $TU | Where-Object { $_.PATH -notlike "*\@userid+$" } | Select-Object Letter,
Path,
@{name = "OrgUnit" ; e = { "" } },
OU,
@{name = "Filtergroup" ; e = { "" } },
@{name = "Label" ; e = { "" } },
Group | Sort-Object -Unique -Property Letter, Path, OU, Group | Group-Object Letter, Path | ForEach-Object { if ($_.count -gt 1) {
        if ($_.Group.ou -notlike "") { $ou = $_.group.OU } else { $ou = "" }
        if ($_.Group.group -notlike "") { $group = $_.group.group | Sort-Object -Property Group -Unique } else { $group = "" }
        $letter = $_.group.letter | Sort-Object -Unique
        $path = $_.group.path | Sort-Object -Unique
        $_ | Select-Object @{name = "Letter"; e = { $letter } },
        @{name = "OU"; e = { $ou } },
        @{name = "path"; e = { $path } },
        @{name = "Group" ; e = { $group } },
        @{name = "Action"; e = { "" } } | Sort-Object -Unique Letter, OU, Path
    }
    else { $_ | Select-Object -ExpandProperty Group }
} 

$xx | Where-Object { $_.ou } | ForEach-Object {
    $ous = $_.ou.split(",") | ForEach-Object {
        $ou = $_.replace("OU=", "")
        Try { (Get-ADOrganizationalUnit -Filter { Name -like $OU }).distinguishedname } catch {} } 
    $_.ou = $ous
}

$xx | Where-Object { -not [String]::IsNullOrWhiteSpace($_.group) } | ForEach-Object {
    $Groups = $_.Group.split(",")
    $_.Group = $Groups
}
$xx  | Where-Object { $_.group -like "" } | ForEach-Object {
    $_.Group = $null
}

# $xx | Export-Csv C:\temp\drives2gpo.csv -Delimiter "," -Encoding utf8
# $xx | Where-Object { $_.ou } | ForEach-Object { $orgs = $_.ou.split(";"); $_.ou = $orgs }
# $xx | Where-Object { $_.ou } | ForEach-Object {
#     $ous = $_.ou.split(",") | ForEach-Object {
#         $ou = $_.replace("OU=", "")
#         Try { (Get-ADOrganizationalUnit -Filter { Name -like $OU }).distinguishedname } catch {} } 
#     $orgs = [string]::join(";", $ous) ; $_.ou = $orgs
# }

$GPO = New-Object -TypeName XML
$GPO.load("c:\temp\gporeport-2023-11-10.xml")
$drives = $gpo.report.GPO | Where-Object { $_.name -notlike "Test - DriveMap - YG" -and $_.name -notlike "SH Drives Mapping - TEST" } |  ForEach-Object {
    $_.User.ExtensionData.extension.DriveMapSettings.drive | 
    Select-Object @{ name = "Letter" ; e = { $_.properties.Letter } },
    @{ name = "Path" ; e = { $_.properties.path } },
    @{ name = "Action" ; e = { $_.properties.action } },
    @{ name = "ThisDrive"; e = { $_.properties.ThisDrive } },
    @{ name = "Filtergroup" ; e = { $_.filters.filtergroup.bool } },
    @{ name = "Label" ; e = { $_.properties.label } },
    @{ name = "Group"; e = { $_.filters.filtergroup.name.replace("KRUGERINC\", "") } },
    @{ name = "OrgUnit" ; e = { $_.filters.FilterOrgUnit.bool } },
    @{ name = "OU"; e = { [string]::join(",", $_.filters.FilterOrgUnit.name) } }
}

$drives | Export-Csv -Path C:\temp\drives2gpo.csv -Encoding utf8 -Delimiter "," -Append

$spllogon | Where-Object { $_.path -notlike "* & UserName & $" }  | Group-Object -Property Letter, Path | ForEach-Object {
    $x = $_.group.ou | Sort-Object -Unique ; $_ | Select-Object @{ name = "Letter" ; e = { $_.name[0] } },
    @{name = "Path" ; e = { $_.name.split()[1] } },
    @{ name = "OU" ; e = { $x = $_.group.ou | Sort-Object -Unique; [string]::join("," , $x) } },
    @{name = "OrgUnit" ; e = { "" } },
    @{name = "Filtergroup" ; e = { "" } },
    @{name = "Label" ; e = { "" } },
    @{name = "group" ; e = { [string]::join(",", $_.group.group.trim()) } },
    @{name = "Action" ; e = { "" } }
}  | Export-Csv -Path  "c:\temp\drives2gpo.csv" -Delimiter "," -Encoding utf8 -Append

####################  PRINTER STUFF ********************
Get-ADGroupMember "KR Print Spooler Disable Exceptions" | ForEach-Object -Parallel {
    $filter = @{LogName = "Microsoft-Windows-PrintService/Operational"; id = "307", "310" }
    $name = $_.name
    (Get-WinEvent -ComputerName $name -FilterHashtable $filter) | Select-Object @{name = "Server"; e = { $name } },
    @{name = "User"; e = { $_.Properties[2].value } },
    @{name = "Printer"; e = { $_.Properties[3].value } }
}


######################## Enabled Printer Logging ###################################
Get-ADGroupMember "KR Print Spooler Disable Exceptions" | ForEach-Object {
    Invoke-Command -ComputerName $_.name -ScriptBlock { 
        $log = New-Object System.Diagnostics.Eventing.Reader.EventLogConfiguration "Microsoft-Windows-PrintService/Operational" 
        $log.IsEnabled = $True
        $log.SaveChanges()
    }
}
######################## Logon of administrator's account ##########################
$servers = Get-ADComputer -Filter { enabled -eq $true -and operatingsystem -like "*server*" } -Properties operatingsystem
$servers | ForEach-Object -Parallel {
    $date = (Get-Date).AddMonths(-1) 
    Get-WinEvent -ComputerName $_.name -FilterHashtable @{ LogName = 'security'; StartTime = $Date; Id = '4672', '4648'; data = "administrator" }
} | Tee-Object -Variable out

Get-ADOrganizationalUnit -Filter { name -like "Disabled *" } | ForEach-Object {
    $dist = $_.distinguishedname
    $gpo.report.gpo | ForEach-Object {
        $name = $_.name 
        if ($_.linksto.sompath  ) {
            $all = @()
            $all = $_.linksto.sompath
            $all | ForEach-Object { 
                $x = $_.split("/") 
                [array]::Reverse($x) 
                if ($x -ne "kruger.com") {
                    $prefix = "OU="
                } `
                    else {
                    $prefix = $null
                } 
                $dn = $prefix + [string]::join( ",", $x).replace(",", ",OU=").replace(",OU=kruger.com" , ",DC=Kruger,DC=COM").replace("kruger.com" , "DC=Kruger,DC=COM")  
                if ($dn -in $dist) { $name }
            }
        }
    }
}



$Functions = @()
Get-Content \\kruger.com\NETLOGON\tr\TrLogon.kix | Where-Object {
    -not [String]::IsNullOrWhiteSpace($_) -and $_ -notlike "*;*" } | Where-Object { $_ -like "Function *" } | ForEach-Object {
    $name = $_.split("(")[0].replace("Function", "").trim()
    if ($_ -like '*(*') {
        $properties = $_.split("(")[1].replace(')', "").replace('$', "").split(",").trim()
        Remove-Variable var
        $var = [psCustomObject]@{ "function" = $name }
        $properties | ForEach-Object {
            $var | Add-Member -MemberType NoteProperty $_ -Value "scrap"
        }
    }
    $functions += $var
}

$Functions | ForEach-Object {
    Remove-Variable -Name $_.function
    New-Variable -Name $_.function -PassThru $_
}

Get-ADUser -Filter { enabled -eq $true -and scriptpath -eq "spllogon.bat" -and homedirectory -like "*" -and homedirectory -notlike "\\kruger.com\users$\*" } -Properties scriptpath, 
homedrive, homedirectory | Select-Object scriptpath, homedrive, homedirectory,
@{name = "DFS" ; e = { if ($null -ne $dfs[$_.homedirectory.substring(0, $_.homedirectory.lastindexof('\'))]) { $dfs[$_.homedirectory.substring(0, $_.homedirectory.lastindexof('\'))] + "\" + $_.homedirectory.substring( $_.homedirectory.lastindexof('\') + 1) } else { $_.homedirectory } }
}