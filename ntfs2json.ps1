$servers = (Get-ADComputer -Filter { OperatingSystem -like "*server*" } -Properties OperatingSystem ).name
foreach ( $server in $servers) {
    if ( Test-Path ("\\$server\c$\temp\ntfs\" )) {
        Get-ChildItem ("\\$server\c$\temp\ntfs\" + $server + "-*csv") | ForEach-Object -Parallel { 
            $base = $_.BaseName
            $ntfs = Import-Csv $_.fullname
            $x = $ntfs | ForEach-Object { 
                '{"id": "' + [guid]::NewGuid().guid + '","Server" :"' + $server + '","Folder" :"' + $_.Folder.replace('\', '\\') + '","IdentityReference" :"' + $_.IdentityReference.replace('\', '\\') + '","FileSystemRights" :"' + $_.FileSystemRights + '","AccessControlType" :"' + $_.AccessControlType + '","PropagationFlags" :"' + $_.PropagationFlags + '","IsInherited" :"' + $_.IsInherited + '","InheritanceFlags" :"' + $_.InheritanceFlags + '"}' 
            }
            ("[" + ( $x -join ",") + "]") | Out-File -Encoding utf8 -FilePath c:\temp\ntfs\$base.json
        }
    }
}
