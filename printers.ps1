Get-wmiobject Win32_Printer -Filter "shared = $true" | export-csv -Path \\Grsvfp01\temp\$env:username.txt