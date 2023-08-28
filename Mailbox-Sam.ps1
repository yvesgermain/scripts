$localsession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://hosvexch01/PowerShell/ -Authentication Kerberos
import-pssession $localSession
$lrooms= Get-mailbox –ResultSize Unlimited –RecipientTypeDetails RoomMailbox | ForEach-Object {$p = $_.primarysmtpaddress; ( get-aduser -Filter {emailaddress -eq $p} ).SamAccountName }
$lshared = Get-mailbox –ResultSize Unlimited –RecipientTypeDetails SharedMailbox | ForEach-Object {$p = $_.primarysmtpaddress; ( get-aduser -Filter {emailaddress -eq $p}).SamAccountName }
$Lmonitor = Get-Mailbox -ResultSize unlimited -Monitoring |ForEach-Object { $p = $_.primarysmtpaddress; ( get-aduser -Filter {emailaddress -eq $p}  ).SamAccountName }
$lMigration = get-mailbox -ResultSize unlimited -Migration |ForEach-Object { $p = $_.primarysmtpaddress; ( get-aduser -Filter {emailaddress -eq $p} ).SamAccountName }
$lArbitration = get-mailbox -ResultSize unlimited -Arbitration |ForEach-Object { $p = $_.primarysmtpaddress; ( get-aduser -Filter {emailaddress -eq $p} ).SamAccountName }

Remove-pssession -Session $localSession
Connect-exchangeOnline -UserPrincipalName yves.germainadm@kruger.com
$rooms= Get-mailbox –ResultSize Unlimited –RecipientTypeDetails RoomMailbox | ForEach-Object {$p = $_.primarysmtpaddress; ( get-aduser -Filter {emailaddress -eq $p} -Properties lastlogondate ).SamAccountName }
$Shared = Get-mailbox –ResultSize Unlimited –RecipientTypeDetails SharedMailbox | ForEach-Object {$p = $_.primarysmtpaddress; ( get-aduser -Filter {emailaddress -eq $p} -Properties lastlogondate ).SamAccountName }
Disconnect-ExchangeOnline -Confirm:$false
$mailbox = $lrooms + $lshared + $Lmonitor + $lMigration + $lArbitration + $rooms + $Shared
$date = ( get-date).AddYears(-1)
get-aduser -filter {Enabled -eq $false -or Lastlogondate -lt $date} -Properties lastlogondate,description | Where-Object {$_.SamAccountName -notin $mailbox -and $_.distinguishedname -notlike "*OU=DisabledUsers,DC=kruger,DC=com"} | Select-Object name, enabled, @{ name = "Lastlogondate" ;e= { "{0:MM/dd/yyyy}" -f $_.lastlogondate}}, Description, @{ name = "OU";e = {$_.distinguishedname.substring($_.distinguishedname.indexofany("=", 3) -2 )}} | Format-Table

Get-Mailbox -ResultSize unlimited -IncludeInactiveMailbox -Filter { LitigationHoldEnabled -eq $true} | Select-Object name, *litigationHold*, *HoldApplied, inplaceholds, IsInactiveMailbox | Group-Object -Property LitigationHoldOwner -NoElement