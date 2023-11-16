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
                        $ou = $_.split('"')[1].split(",")[0]
                    }
                }
            }
            if ($_ -match "InGroup") {
                $group = $_.split('"')[1,3,5]
                if ($group -is "array") {$group = [string]::join(",", $group)}
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
                @{name = "Path" ; e = { $Folder.replace('"', "") } }
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

