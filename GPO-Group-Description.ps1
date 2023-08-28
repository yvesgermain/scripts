$gpo = Get-GPOReport -all -ReportType xml
$gpo.gpos.gpo | foreach-object {
    $name = $_.name ;
    $_.SecurityDescriptor | ForEach-Object {
        $_.permissions.TrusteePermissions | ForEach-Object {
            if ($_.standard.GPOGroupedAccessEnum -eq "Apply Group Policy" -and $_.trustee.sid."#text" -like "S-1-5-21-*") {
                $_ | Select-Object @{name = "Gpo"; e = { $name }},
                @{name = "Sid"; e = { $_.trustee.sid."#text" }},
                @{name = "Allow" ; e = { $_.type.PermissionType }}
            }
        }
    } | ForEach-Object {
        $name  = $_.gpo;
        $Sid   = $_.Sid;
        $allow = $_.allow;
        Get-ADObject -Filter { objectSid -eq $Sid } -Properties Description | ForEach-Object {
            $desc = $_.description
            if ( $_.description -notlike "* this GPO to be applied:*" -and $_.objectclass -eq "group" -and $_.name -notlike "Domain *") {
                Set-ADGroup -Identity $_.distinguishedname -Description ("$allow this GPO to be applied: $name. $Desc") -Confirm
            }
        }
    }
}
