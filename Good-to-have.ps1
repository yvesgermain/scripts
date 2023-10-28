Remove-Variable case, oldcase, MapDrive, path, ismember
$spllogon = Get-Content \\kruger.com\NETLOGON\spllogon.vbs | Where-Object {
    $_ -notmatch "^'" -and ($_ -match "if isMember" -or $_ -match "MapDrive" -or $_ -match "case" -or $_ -match "End Select" )
} | ForEach-Object {
    if ($_ -match "End Select") { Remove-Variable case, oldcase, MapDrive, path, ismember; }
    if ($_ -match "Case " -and $_ -notlike "*Select Case network*") { $case = $_ }
    if ($_ -match "MapDrive ") { $MapDrive , $path = $_.split(",") }
    if ($_ -match "if isMember") { $isMember = $_.split('"')[1] } else { $isMember = $null }
    if ($case -and $case -eq $oldcase -and $IsMember -eq $null) {
        $_ | Select-Object @{name = "Subnet" ; e = { $case.split('"')[1] } },
        @{Name = "Location"  ; e = { $case.replace('"', "").split("'")[1] } },
        @{Name = "Letter" ; e = { $MapDrive.split('"')[1].replace(":", "") } },
        @{Name = "Path"; e = { $path.replace('"', "") } },
        @{Name = "Group"; e = { $OldIsMember } }
    } 
    $oldcase = $case; $oldIsMember = $isMember
}
$spllogon

Function convert-kix2Drive {
    param($File) Get-Content $File | Where-Object {
        -not [String]::IsNullOrWhiteSpace($_) -and $_ -notlike "*;*" -and ($_ -like "Case *" -or $_ -like "If INGROUP*" -or $_ -like "*AddDisk(*")
    } | ForEach-Object {
        if ($_ -match "Case ") { if ($_ -eq "Case 1") { $case = "EveryOne" } else { $case = $_.split(",")[1].split('"')[1] } }
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

$HO = Get-Content \\kruger.com\NETLOGON\ho\kixtart.kix | Where-Object {
    -not [String]::IsNullOrWhiteSpace($_) -and $_ -notlike "*;*" -and ($_ -like "Case *" -or $_ -like "If INGROUP*" -or $_ -like "*AddDisk(*")
} | ForEach-Object {
    if ($_ -match "Case ") { if ($_ -eq "Case 1") { $case = "EveryOne" } else { $case = $_.split(",")[1].split('"')[1] } }
    if ($_ -match "AddDisk") { $letter, $MapDrive , $path = $_.replace('"', "").replace(')', "").split(","); $letter = $letter.split("(")[1] }
    if ($_ -match "If INGROUP") { $isMember = $_.split('"')[1] }  else { $isMember = $null }
    if ($case -and $case -eq $oldcase -and $IsMember -eq $null) {
        $_ | Select-Object @{name = "OU" ; e = { $case.trim() } },
        @{name = "Letter"; e = { $letter } },
        @{ name = "Path" ; e = { $path.trim() + "\" + $MapDrive.trim() } },
        @{ name = "Group"; e = { $OldIsMember } }
    }
    $oldcase = $case; $oldIsMember = $isMember
}
Remove-Variable letter, path, Ismember, oldismember, oldcase
$HO

$CB = Get-Content \\kruger.com\NETLOGON\cb\LoginCB.kix | Where-Object {
    -not [String]::IsNullOrWhiteSpace($_) -and $_ -notlike "*;*" } | ForEach-Object {
    if ($_ -match "use ") { $letter, $path = $_.replace('"', "").split(":"); $letter = $letter.replace("use " , "").trim() }
    if ($_ -match "If INGROUP") { $isMember = $_.split('"')[1] }  else { $isMember = $null }
    if ($IsMember -eq $null -and $oldIsMember -ne $null) {
        $_ | Select-Object  @{name = "Letter"; e = { $letter } },
        @{ name = "Path" ; e = { $path.trim() + "\" + $MapDrive.trim() } },
        @{ name = "Group"; e = { $OldIsMember } }
    }
    $oldIsMember = $isMember
}
Remove-Variable letter, path, Ismember, oldismember
$CB

$LS = Get-Content \\kruger.com\NETLOGON\kk\kkLogin_ls.kix | Where-Object {
    -not [String]::IsNullOrWhiteSpace($_) -and $_ -notlike "*;*" -and ($_ -like "Case *" -or $_ -like "If INGROUP*" -or $_ -like "*AddDisk(*")
} | ForEach-Object {
    if ($_ -match "Case ") { if ($_ -eq "Case 1") { $case = "EveryOne" } else { $case = $_.split(",")[1].split('"')[1] } }
    if ($_ -match "AddDisk") { $letter, $MapDrive , $path = $_.replace('"', "").replace(')', "").split(","); $letter = $letter.split("(")[1] }
    if ($_ -match "If INGROUP") { $isMember = $_.split('"')[1] }  else { $isMember = $null }
    if ($case -and $case -eq $oldcase -and $IsMember -eq $null) {
        $_ | Select-Object @{name = "OU" ; e = { $case.trim() } },
        @{name = "Letter"; e = { $letter } },
        @{ name = "Path" ; e = { '\\' + $path.trim() + "\" + $MapDrive.trim() } },
        @{ name = "Group"; e = { $OldIsMember } }
    }
    $oldcase = $case; $oldIsMember = $isMember
}
Remove-Variable letter, path, Ismember, oldismember, oldcase
$LS

$PD = Get-Content \\kruger.com\NETLOGON\kk\kkLogin_pd.kix | Where-Object {
    -not [String]::IsNullOrWhiteSpace($_) -and $_ -notlike "*;*" -and ($_ -like "Case *" -or $_ -like "If INGROUP*" -or $_ -like "*AddDisk(*")
} | ForEach-Object {
    if ($_ -match "Case ") { if ($_ -eq "Case 1") { $case = "EveryOne" } else { $case = $_.split(",")[1].split('"')[1] } }
    if ($_ -match "AddDisk") { $letter, $MapDrive , $path = $_.replace('"', "").replace(')', "").split(","); $letter = $letter.split("(")[1] }
    if ($_ -match "If INGROUP") { $isMember = $_.split('"')[1] }  else { $isMember = $null }
    if ($case -and $case -eq $oldcase -and $IsMember -eq $null) {
        $_ | Select-Object @{name = "OU" ; e = { $case.trim() } },
        @{name = "Letter"; e = { $letter } },
        @{ name = "Path" ; e = { '\\' + $path.trim() + "\" + $MapDrive.trim() } },
        @{ name = "Group"; e = { $OldIsMember } }
    }
    $oldcase = $case; $oldIsMember = $isMember
} 
Remove-Variable letter, path, Ismember, oldismember, oldcase
$PD

$ET = Get-Content \\kruger.com\NETLOGON\kk\kkLogin_et.kix | Where-Object {
    -not [String]::IsNullOrWhiteSpace($_) -and $_ -notlike "*;*" -and ($_ -like "Case *" -or $_ -like "If INGROUP*" -or $_ -like "*AddDisk(*")
} | ForEach-Object {
    if ($_ -match "Case ") { if ($_ -eq "Case 1") { $case = "EveryOne" } else { $case = $_.split(",")[1].split('"')[1] } }
    if ($_ -match "AddDisk") { $letter, $MapDrive , $path = $_.replace('"', "").replace(')', "").split(","); $letter = $letter.split("(")[1] }
    if ($_ -match "If INGROUP") { $isMember = $_.split('"')[1] }  else { $isMember = $null }
    if ($case -and $case -eq $oldcase -and $IsMember -eq $null) {
        $_ | Select-Object @{name = "OU" ; e = { $case.trim() } },
        @{name = "Letter"; e = { $letter } },
        @{ name = "Path" ; e = { '\\' + $path.trim() + "\" + $MapDrive.trim() } },
        @{ name = "Group"; e = { $OldIsMember } }
    }
    $oldcase = $case; $oldIsMember = $isMember
}
Remove-Variable letter, path, Ismember, oldismember, oldcase
$ET

$TU = Get-Content \\kruger.com\NETLOGON\kk\kkLogin_TU.kix | Where-Object {
    -not [String]::IsNullOrWhiteSpace($_) -and $_ -notlike "*;*" -and ($_ -like "Case *" -or $_ -like "If INGROUP*" -or $_ -like "*AddDisk(*")
} | ForEach-Object {
    if ($_ -match "Case ") { if ($_ -eq "Case 1") { $case = "EveryOne" } else { $case = $_.split(",")[1].split('"')[1] } }
    if ($_ -match "AddDisk") { $letter, $MapDrive , $path = $_.replace('"', "").replace(')', "").split(","); $letter = $letter.split("(")[1] }
    if ($_ -match "If INGROUP") { $isMember = $_.split('"')[1] }  else { $isMember = $null }
    if ($case -and $case -eq $oldcase -and $IsMember -eq $null) {
        $_ | Select-Object @{name = "OU" ; e = { $case.trim() } },
        @{name = "Letter"; e = { $letter } },
        @{ name = "Path" ; e = { '\\' + $path.trim() + "\" + $MapDrive.trim() } },
        @{ name = "Group"; e = { $OldIsMember } }
    }
    $oldcase = $case; $oldIsMember = $isMember
}
Remove-Variable letter, path, Ismember, oldismember, oldcase
$TU

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
