$password = Read-Host -AsSecureString -Prompt "Password"
$cred  = New-Object System.Management.Automation.PSCredential -ArgumentList "SherbrookeHuddleRoom", $password
New-RemoteMailbox -Name "Kim Akers" -Password $Credentials.Password -UserPrincipalName SherbrookeHuddleRoom@kruger.com -OnPremisesOrganizationalUnit "kruger.com/Kruger Products/Shared Services/SPL Resources"`
-RemoteRoutingAddress -room -
$splat = @{
    "name" = "Sherbrooke Huddle Room"
    "OnPremisesOrganizationalUnit" = 'kruger.com/Kruger Products/Shared Services/SPL Resources'
    "PrimarySmtpAddress" = 'SMTP:CORP--SherbrookeHuddle.Room@kruger.com'
    "RemoteRoutingAddress" = "smtp:SherbrookeHuddleRoom@KrugerADM.mail.onmicrosoft.com"
    "Password" = $cred.Password
    "Alias" = "SherbrookeHuddleRoom"
    "UserPrincipalName" = "SherbrookeHuddleRoom@kruger.com"
    "LastName" = "Room"
    "FirstName" = "CORP--Sherbrooke Huddle"
    "ResetPasswordOnNextLogon" = $false
    "room" = $true
}

New-RemoteMailbox @splat -whatif