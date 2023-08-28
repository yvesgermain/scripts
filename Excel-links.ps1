$path = "\\GRSVFP01\GROUPS\Serveur Richelieu (R)"
if (!( Get-PSDrive p)) { net use P: $path }
$files = Get-ChildItem P: -Directory | Select-Object name, fullname
foreach ( $file in $files) {
  $filepath = $file.name
  $folder = $file.fullname
  $excel = New-Object -ComObject Excel.Application
  $excel.visible = $true
  $excel.Application.DisplayAlerts = $False
  $Excel.AutomationSecurity = 3
  # $excelSheets = Get-ChildItem -Path P: -Include *.xls, *.xlsx -Recurse
  # foreach ( $excelSheet in $excelSheets) {
  Get-ChildItem -Path $folder -Include *.xls, *.xlsx -Recurse | ForEach-Object {
    $out = $false
    $excelSheet = $_.fullname
    try { $workbook = $excel.Workbooks.Open($excelSheet, $null, $true) } catch { Write-Warning $excelSheet ; $out = $true }
    if ($out -eq $false ) {
      # Write-Host $excelSheet
      if ($workbook.LinkSources(1).count -eq 1 ) {
        $excelSheet | Tee-Object -FilePath "c:\temp\excel-link\$filepath.txt" -Append
        "- " + $workbook.LinkSources(1) | Tee-Object -FilePath "c:\temp\excel-link\$filepath.txt" -Append
      }`
        else {
        if ($workbook.LinkSources(1).count -gt 1) {
          $excelSheet  | Tee-Object -FilePath "c:\temp\excel-link\$filepath.txt" -Append
          foreach ($link in $workbook.LinkSources(1)) {
            "- $link" | Tee-Object -FilePath "c:\temp\excel-link\$filepath.txt" -Append 
          }
        }
      }
      $workbook.close($null)
    }
  } 
  $excel.quit()
  $excel = $null
  [gc]::collect()
  [gc]::WaitForPendingFinalizers()
} #end foreach
$excel.quit()
$excel = $null
[gc]::collect()
[gc]::WaitForPendingFinalizers()


# broken excel links 

Set-Location C:\temp\excel-link
$x = (Get-ChildItem p:\ -Directory | Where-Object {$_.name -notin "Lettres service essentiel janvier 2021", "Portes et transporteurs", "INSPEK Expédition"}).basename
(
  $x | ForEach-Object {
  (Get-Content "$_.txt" | Select-String "^- P:") + (Get-Content "$_.txt" | Select-String "^-P:") + (Get-Content "$_.txt" | Select-String "^-G:") + (Get-Content "$_.txt" | Select-String "^- G:") | ForEach-Object -Parallel { 
      if (Test-Path -Path ($_ -replace ('^-' , "")).trim().replace("G:", "P:")  ) {
    ($_ -replace ('^-' , "")).trim().replace("G:", "P:")
      }
    }
  }
).count

$excel = New-Object -ComObject Excel.Application
$excel.visible = $true
$excel.Application.DisplayAlerts = $False
$Excel.AutomationSecurity = 3
$excelSheet = "C:\temp\test1.xlsx"
$workbook = $excel.Workbooks.Open($excelSheet, $null, $False)
$workbook.LinkSources(1)
$workbook.changeLink("c:\temp\test2.xlsx", "c:\temp\azure\test2.xlsx")
$workbook.changeLink("c:\temp\test3.xlsx", "c:\temp\azure\test3.xlsx")


$workbook.save()
$excel.quit()
$excel = $null
[gc]::collect()
[gc]::WaitForPendingFinalizers()