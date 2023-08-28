$servers = Read-Host -Prompt "Computername ex: Server1 Server2"
Invoke-Command -ComputerName $servers.split() -ScriptBlock {
    $server = HOSTNAME.EXE
    $dism = (Get-WindowsOptionalFeature -FeatureName windows-defender -Online)
    if ($dism.enabled -eq "enabled") { "Windows-Defender feature is installed" }`
        else { Write-Warning "Windows-Defender feature is NOT installed" }
    Write-Host -ForegroundColor green "1- Verify AV Service installed and running on $server."
    $windefend = Get-Service WinDefend -ErrorAction SilentlyContinue
    if (!($WinDefend)) {
        Write-Warning "Service Windefend not installed"
    }`
        else {
        "Service Windefend is installed" 
        If ($windefend.status -eq "Running") { "Windefend is running" }`
            else { Write-Warning "Windefend is NOT running" }
    }
    Write-Host -ForegroundColor green "2- Check registries before onboarding $server."
    if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows Advanced Threat Protection') { "Registry keys for Windows advanced threat protection are installed" } `
        else { Write-Warning "Registry keys for Windows advanced threat protection are NOT installed" }
    if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows Defender' ) { "Registry keys for Windows Defender are installed" } `
        else { Write-Warning "Registry keys for Windows Defender are NOT are installed" }
    Write-Host -ForegroundColor green "3- Check the Event Logs on the Sense Folder."
    if ( Get-WinEvent -ListLog Microsoft-Windows-Sense/Operational -ErrorAction SilentlyContinue ) { "Event log for Microsoft-Windows-Sense/Operational found" }`
        else { Write-Warning "Event log for Microsoft-Windows-Sense/Operational missing" }
    if ( Get-WinEvent -ListLog Microsoft-Windows-SenseIR/Operational -ErrorAction SilentlyContinue ) { "Event log for Microsoft-Windows-SenseIR/Operational found" }`
        else { Write-Warning "Event log for Microsoft-Windows-SenseIR/Operational missing" }
    Write-Host -ForegroundColor green "4- Verify Windows Defender Advanced Threat protection Service installed and running on the machine."
    $Sense = Get-Service Sense -ErrorAction SilentlyContinue
    if (!($Sense)) {
        Write-Warning "Windows Defender Advanced Threat protection Service not installed"
    }`
        else {
        "Windows Defender Advanced Threat protection Service is installed" 
        If ($Sense.status -eq "Running") { "Windows Defender Advanced Threat protection Service is running" }`
            else { Write-Warning "Windows Defender Advanced Threat protection Service is NOT running" }
    }
    ""
}