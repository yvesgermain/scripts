Remove-Variable case, oldcase, MapDrive, path, ismember
$spllogon = Get-Content \\kruger.com\NETLOGON\spllogon.vbs | Where-Object {
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
        @{Name = "Location"  ; e = { $case.replace('"', "").split("'")[1] } },
        @{Name = "Group"; e = { $OldIsMember } }
    } 
    $oldcase = $case; $oldIsMember = $isMember
}
$spllogon | Format-Table -AutoSize

Function convert-kix2Drive {
    param($File) Get-Content $File | Where-Object {
        -not [String]::IsNullOrWhiteSpace($_) -and $_ -notlike "*;*" -and ($_ -like "Case *" -or $_ -like "If INGROUP*" -or $_ -like "*AddDisk(*")
    } | ForEach-Object {
        if ($_ -match "Case ") { if ($_ -eq "Case 1") { $case = "AnyOU" } else { $case = $_.split(",")[1].split('"')[1] } }
        if ($_ -match "AddDisk") { $letter, $MapDrive , $path = $_.replace('"', "").replace(')', "").split(","); $letter = $letter.split("(")[1] }
        if ($_ -match "If INGROUP") { $isMember = $_.split('"')[1] }  else { $isMember = $null }
        if ($case -and $case -eq $oldcase -and $null -eq $IsMember) {
            $_ | Select-Object @{name = "OU" ; e = { $case.trim() } },
            @{name = "Letter"; e = { $letter } },
            @{ name = "Path" ; e = { '\\' + $path.trim() + "\" + $MapDrive.trim() } },
            @{ name = "Group"; e = { $OldIsMember } }
        }
        $oldcase = $case; $oldIsMember = $isMember
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

Get-Content \\kruger.com\NETLOGON\tr\TrLogon.kix | Where-Object {
    -not [String]::IsNullOrWhiteSpace($_) -and $_ -notlike "*;*" } | ForEach-Object {
    if ($_ -match "use ") { $letter, $path = $_.replace('"', "").split(":"); $letter = $letter -replace ("use " , "").trim() }
    if ($_ -match "If INGROUP") { $isMember = $_.split('"')[1] }  else { $isMember = $null }

    if ($IsMember -eq $null -and $oldIsMember -ne $null) {
        $_ | Select-Object  @{name = "Letter"; e = { $letter } },
        @{ name = "Path" ; e = { $path.trim() + "\" + $MapDrive.trim() } },
        @{ name = "Group"; e = { $OldIsMember } }
    }
    $oldIsMember = $isMember
}

if ($case) {Remove-Variable case}
$tr = Get-Content \\kruger.com\NETLOGON\tr\TrLogon.kix | Where-Object {
    -not [String]::IsNullOrWhiteSpace($_) -and $_ -notlike "*;*" } | ForEach-Object {
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
            if ($_ -match "AddNewDisk"){
                $string = $_.replace(')',"")
                $server, $share, $scrap, $letter, $option1 = $string.split(",",  [StringSplitOptions]::RemoveEmptyEntries)
                $server =   $server.replace('   AddNewDisk  ( "',"").replace('"',"").trim()
                $folder = '\\' + $Server + '\' + $share.trim()
                $letter = $letter.replace('"',"")
                $option1= $option1.replace('"',"")
                $_ | Select-Object @{name = "Letter" ; e = { $letter.replace(":","").trim() }}, 
                @{name = "Case User or Group";e = {$case}},
                @{name = "Folder" ;e = {$Folder.replace('"',"")}},
                @{name = "User"; e = { $user.replace('/user:',"") }},
                @{name = "Password"; e = { $pwd.replace('/password:',"") }},
                @{name= "Option1";e ={$option1.trim()}},
                @{name ="Option2";e = {$option2}};
                if ($letter -or $path) { Remove-Variable letter } 
                If ($folder) { Remove-Variable folder }  
                if ($pwd) { Remove-Variable pwd }
                if ($user) { Remove-Variable user }
                if ($option1) {Remove-Variable Option1}
                if ($OPtion2) {Remove-Variable option2}
                remove-variable String

            }
            if ($_ -match 'AddDisk') {
                $string = $_.replace(')',"")
                $Server, $Share, $letter, $option1 = $string.split(",",  [StringSplitOptions]::RemoveEmptyEntries)
                $Server = $server.split('"')[1].trim()
                $Share = $Share.trim()
                $folder = '\\' + $Server + '\' + $share + '\$user'
                $letter = $letter.replace(":","").replace('"',"").trim()
                $option1= $option1.replace('"',"")
                $_ | Select-Object @{name = "Letter" ; e = { $letter.replace(":","") }}, 
                @{name = "Case User or Group";e = {$case}},
                @{name = "Folder" ;e = {$Folder.replace('"',"")}},
                @{name = "User or Group"; e = { $user.replace('/user:',"") }},
                @{name = "Password"; e = { $pwd.replace('/password:',"") }},
                @{name= "Option1";e ={$option1.trim()}},
                @{name ="Option2";e = {$option2}};
                if ($letter -or $path) { Remove-Variable letter } 
                If ($folder) { Remove-Variable folder }  
                if ($pwd) { Remove-Variable pwd }
                if ($user) { Remove-Variable user }
                if ($option1) {Remove-Variable Option1}
                if ($OPtion2) {Remove-Variable option2}
                remove-variable String
        }
            if ($_ -match "CASE ") {
                $case = $_.Replace('CASE $USER = "',"").replace('"',"")
            }
            if ($_ -match "use ") {
                $string = $_.trim();
                $scrap, $letter, $path = $string.split(" "); $letter = ($letter -replace ("use " , "")).trim() 
                if ($string -like "*\\*") {$folder , $user, $pwd = $Path.split(" ", [StringSplitOptions]::RemoveEmptyEntries)}
                if ($string -notlike "*\\*") {$option1, $option2  = $path.trim().split(" ", [StringSplitOptions]::RemoveEmptyEntries)}
                $_ | Select-Object @{name = "Letter" ; e = { $letter.replace(":","") }}, 
                @{name = "Case User or Group";e = {$case}},
                @{name = "Folder" ;e = {$Folder.replace('"',"")}},
                @{name = "User or Group"; e = { $user.replace('/user:',"") }},
                @{name = "Password"; e = { $pwd.replace('/password:',"") }},
                @{name= "Option1";e ={$option1.trim()}},
                @{name ="Option2";e = {$option2}};
                if ($letter -or $path) { Remove-Variable letter , path } 
                If ($folder) { Remove-Variable folder }  
                if ($pwd) { Remove-Variable pwd }
                if ($user) { Remove-Variable user }
                if ($option1) {Remove-Variable Option1}
                if ($OPtion2) {Remove-Variable option2}
                remove-variable String
            }
        }
    }
} 
$tr | Format-Table -AutoSize

$ho = convert-kix2Drive \\kruger.com\NETLOGON\ho\kixtart.kix

$CB = convert-kix2Drive \\kruger.com\NETLOGON\cb\LoginCB.kix

$LS = convert-kix2Drive \\kruger.com\NETLOGON\kk\kkLogin_ls.kix 

$PD = convert-kix2Drive \\kruger.com\NETLOGON\kk\kkLogin_pd.kix

$PB = convert-kix2Drive \\kruger.com\NETLOGON\kk\kkLogin_pb.kix

$ET = convert-kix2Drive \\kruger.com\NETLOGON\kk\kkLogin_et.kix

$TU = convert-kix2Drive \\kruger.com\NETLOGON\kk\kklogin_TU.kix

$ho + $CB + $ls + $PD + $PB + $ET + $TU | Format-Table -AutoSize
