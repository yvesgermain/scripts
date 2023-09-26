Import-Module ActiveDirectory

$AllServers = Get-ADComputer -Filter { enabled -eq $true -and operatingsystem -like "Windows server 2012 R2*" } -Properties operatingsystem
$servers = $Allservers | ForEach-Object -Parallel {
    $server = $_
    Test-NetConnection -ComputerName $server.name -CommonTCPPort WINRM -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.TcpTestSucceeded -eq $true) { $Server }
    }
}

foreach ( $server in $servers) {
    Invoke-Command -ComputerName $Server.name -ArgumentList $Server.operatingsystem, $Server.name -ScriptBlock {
        param($OS, $server)
        if ($OS -like "Windows Server 2012*") {
            "checking $OS for windows-defender feature"
            $dism = (Get-WindowsOptionalFeature -FeatureName windows-defender -Online)
            if ($dism.enabled -eq "enabled") { "Windows-Defender feature is installed on $server" }`
                else { Write-Warning "Windows-Defender feature is NOT installed on $server" }
        }
        Write-Host -ForegroundColor green "1- Verify AV Service installed and running on $server."
        $windefend = Get-Service WinDefend -ErrorAction SilentlyContinue
        if (!($WinDefend)) {
            Write-Warning "Service Windefend not installed on $server"
        }`
            else {
            "Service Windefend is installed on $server" 
            If ($windefend.status -eq "running on $server") { "Windefend is running on $server" }`
                else { Write-Warning "Windefend is NOT running on $server" }
        }
        Write-Host -ForegroundColor green "2- Check registries before onboarding $server."
        if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows Advanced Threat Protection') { "Registry keys for Windows advanced threat protection are installed on $server" } `
            else { Write-Warning "Registry keys for Windows advanced threat protection are NOT installed on $server" }
        if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows Defender' ) { "Registry keys for Windows Defender are installed on $server" } `
            else { Write-Warning "Registry keys for Windows Defender are NOT are installed on $server" }
        Write-Host -ForegroundColor green "3- Check the Event Logs on the Sense Folder."
        if ( Get-WinEvent -ListLog Microsoft-Windows-Sense/Operational -ErrorAction SilentlyContinue ) { "Event log for Microsoft-Windows-Sense/Operational found" }`
            else { Write-Warning "Event log for Microsoft-Windows-Sense/Operational missing" }
        if ( Get-WinEvent -ListLog Microsoft-Windows-SenseIR/Operational -ErrorAction SilentlyContinue ) { "Event log for Microsoft-Windows-SenseIR/Operational found" }`
            else { Write-Warning "Event log for Microsoft-Windows-SenseIR/Operational missing" }
        Write-Host -ForegroundColor green "4- Verify Windows Defender Advanced Threat protection Service installed and running on $server."
        $Sense = Get-Service Sense -ErrorAction SilentlyContinue
        if (!($Sense)) {
            Write-Warning "Windows Defender Advanced Threat protection Service not installed on $server"
        }`
            else {
            "Windows Defender Advanced Threat protection Service is installed on $server" 
            If ($Sense.status -eq "running on $server") { "Windows Defender Advanced Threat protection Service is running on $server" }`
                else { Write-Warning "Windows Defender Advanced Threat protection Service is NOT running on $server" }
        }
        if ($os -like "Windows Server 2012*") {
        "Get hotfix bk3094199 on $server"
        Get-HotFix -Id bk3094199
        "Get hotfix KB2999226 on $server"
        Get-HotFix -Id KB2999226
        "Get hotfix KB3080149 on $server"
        Get-HotFix -Id KB3080149
        "Get hotfix KB5005292 on $server"
        Get-HotFix -Id KB5005292
        }
        if ($os -like "Windows Server 2016*") {
            "Get hotfix KB5005292 on $server"
            Get-HotFix -Id KB5005292
            "Get hotfix KB4457139 on $server"
            Get-HotFix -Id KB4457139
    }
}
