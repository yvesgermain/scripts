$hmdirectory = (Dsquery user -samid $env:username | dsget user -hmdir )[1].trim()
$hmdrive = (Dsquery user -samid $env:username | dsget user -hmdrv )[1].trim()
if ($null -ne $hmdirectory -and $null -ne $hmdrive) {
    net use $hmdrive /delete
    net use $hmdrive $hmdirectory /persistent:YES
}
