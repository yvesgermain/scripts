Write-host "Starting Delegation"
$Dom="Krugerinc"
#:
# DElegation for Montreal
#
$BaseOU= "OU=Sherbrooke-ldc,OU=Kruger Products,DC=kruger,DC=com"

call :GrantFullControl $BaseOU "$Dom\PRIV-U-MTLAdmin-Aero"
call :GrantManageAccounts "OU=Users,$BaseOU", "$Dom\PRIV-U-MTLAccAdmin-Aero"
call :GrantMAnageGroups "OU=Groups,$BaseOU", "$Dom\PRIV-U-MTLSecAdmin-Aero"
call :GrantResetPassword "OU=Users,$BaseOU", "$Dom\PRIV-U-MTLHelpDeskOps-Aero"
call :GRantManageComputers "OU=Workstations,$BaseOU", "$Dom\PRIV-U-MTLWksAdmin-Aero"
call :GRantManageComputers "OU=Servers_OPS,$BaseOU", "$Dom\PRIV-U-MTLServerAdmin-Aero"

goto end

:GrantFullControl
  # the first argument is the OU
  # the second argument is the User or Group
	dsacls "%~1" /I:s /G $~2:GA
Goto :EOF

:GrantManageAccounts
  # the first argument is the OU
  # the second argument is the User or Group
	dsacls "%~1" /I:s /G $~2:CCDC;user"
	dsacls "%~1" /I:s /G $~2:GA;;user"
	dsacls "%~1" /I:s /G $~2:CCDC;inetOrgPerson"
	dsacls "%~1" /I:s /G $~2:GA;;inetOrgPerson"
Goto :EOF

:GrantManageGroups
  # the first argument is the OU
  # the second argument is the User or Group
	dsacls "%~1" /I:s /G $~2:CCDC;group"
	dsacls "%~1" /I:s /G $~2:GA;;group"
Goto :EOF

:GRantManageComputers", "$
  # the first argument is the OU
  # the second argument is the User or Group
	dsacls "%~1" /I:s /G $~2:CCDC;computer
	dsacls "%~1" /I:s /G $~2:GA;;computer
Goto :EOF

:GrantResetPassword
  # the first argument is the OU
  # the second argument is the User or Group
	dsacls "%~1" /I:s /G $~2:rpwp;lockoutTime;user
	dsacls "%~1" /I:s /G $~2:rpwp;pwdLastSet;user
	dsacls "%~1" /I:s /G $~2:CA;"Re$Password";user
Goto :EOF

:RemovePermissions
  # the first argument is the OU
  # the second argument is the User or Group
	dsacls "%~1" /R "$~2
