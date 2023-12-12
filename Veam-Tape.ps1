##################################################################################################################
# Please Configure the following variables....
$smtpServer="mail.kruger.com"
$from =  "<hosvveeam02@kruger.com>"
$Recipient = "enzo.rodi@kruger.com"
#$Recipient = "HODCAdmins2@kruger.com", "Sysadmin.Operations@kruger.com", "Samuel.Ponsot@kruger.com"
$Subject = "Daily Tape LOAD & UNLOAD report"
###################################################################################################################


$vbrServer="hosvveeam02.kruger.com"
$veam = New-PSSession -ComputerName $vbrServer
Import-Module -Name Veeam.Backup.PowerShell -PSSession $veam

#Add-PSSnapIn -Name VeeamPSSnapIn
Connect-VBRServer


$date = (get-date -DisplayHint Date)
$barcode = Get-VBRTapeMedium -Vault EXTERNAL |  Where-Object {$_.IsExpired} | Sort-Object "Barcode"
$slot = Get-VBRTapeMedium |Where-Object { $_.IsExpired -eq $False -and $_.IsFree -eq $False -and ($_.Location -eq "slot" -and ($_.free -lt "10000000000")) } | Select-Object -Property @{N="Barcode";E={$_.Barcode}}, @{N="Protected Until";E={$_.ExpirationDate}}, @{N="Location";E={$_.Location}}, @{N="SlotNo";E={$_.Location.SlotAddress +1}},@{N="Free Space";E={$_.free}}| sort-object {$_.ExpirationDate}

  
# Email Body Set Here, Note You can use HTML, including Images.
$body ="
<p>Sysadmins,</p>
<p>This is a reminder. Can you please feed the backup library more tapes </br>"

$body+="<Table>"
$body+="<tr><th>Barcode:</th><th></th><th>Expiration Date:</th></tr>"
$barcode | ForEach-Object { $Body+="<tr><td>$($_.Barcode)</td><td>    </td><td>$($_.ExpirationDate)</td></tr></tr>" }
$body+="</Table>"

if($null -ne $slot)
{
    $body+="<p>"
    $body+="And pull these tapes out from the library and take to the vault"

    $body+="<Table>"
    $body+="<tr><th>Barcode:</th><th></th><th>Slot Number:</th><th>Expiration Date:</th><th>Free Space (GB):</th></tr>"
    $slot | ForEach-Object { $Body+=" <p align=""center""> <tr><td>$($_.Barcode)</td><td>  </td><td> $($_.Location.SlotAddress +1) </td><td>$($_."Protected Until")</td>  <td>$([math]::round($_."Free Space"/1GB,2))</td></tr></tr></p> " }
    $body+="</Table>"

}



$body+="
<p>&nbsp;</p>
<p>Thanks !, </p>

"
   
# Send Email Message
if ($null -ne $slot)
{
# Send Email Message
    Send-Mailmessage -smtpServer $smtpServer -from $from -to $Recipient -subject $subject -body $body -bodyasHTML -priority High  

} # End Send Message


Disconnect-VBRServer

