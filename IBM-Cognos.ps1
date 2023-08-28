$EXCEL_ADDIN_PATH_BEFORE = "HKCU:\Software\Microsoft\Office\" 
$EXCEL_ADDIN_PATH_AFTER = "\Excel\Options\" 
$ADDIN_REG_VALUE = "C:\Program Files\ibm\cognos\IBM for Microsoft Office\IBM_PAfE_x64_2.0.87.3.xll"
$XLAddin_Version = "2.0.87.3"

"Excel Add-in $XLAddin_Version Registration Tool Begin!"

$versions = @("12.0", "14.0", "15.0", "16.0")

ForEach ($Officeval In $versions ) {
    $EXCEL_ADDIN_PATH = $EXCEL_ADDIN_PATH_BEFORE + $officeval + $EXCEL_ADDIN_PATH_AFTER 

    If (Test-Path $EXCEL_ADDIN_PATH) { 
        "Office Version - " + $officeval + " found. Checking for Office " + $officeval + " Installation"
        $value = (Get-ItemProperty -Path $EXCEL_ADDIN_PATH -Name "OPEN" -ErrorAction SilentlyContinue).OPEN
        if ($null -ne $value) {"OPEN registry key = " + $value} else {"OPEN registry key null"}
        if ($value -ne $ADDIN_REG_VALUE) {
            "Setting registry key OPEN to " + $ADDIN_REG_VALUE
            Set-ItemProperty -Path $EXCEL_ADDIN_PATH -Name "OPEN" -Value $ADDIN_REG_VALUE
        } else {"Nothing to do!"}
    } else {"Office version " + $Officeval + " and registry path " + $EXCEL_ADDIN_PATH +" not found!"}
}
