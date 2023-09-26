@echo off
::
:: Delegation script for Krugerinc - KPLP
::
:: By Andre Dube - 2020-12-01
::

SET Dom=KRUGERINC

::SET Prefix=KP Shared
::SET OUName=Shared Services


SET Prefix=%~1
SET OUName=%~2

SET BaseOU=OU=%OUName%,OU=Kruger Products,DC=kruger,DC=com
@echo Starting Delegation for %BaseOU%


SET Grp=%Prefix% Server Admins
@echo Starting Delegation for %Grp%
call :GrantManageComputers "OU=Computers,%BaseOU%" "%Dom%\%Grp%"
call :GRantManageComputersBitlocker "OU=Computers,%BaseOU%" "%Dom%\%Grp%"
call :GrantManageComputers "OU=Servers,%BaseOU%" "%Dom%\%Grp%"
call :GrantManageContacts "OU=Contacts,%BaseOU%" "%Dom%\%Grp%"
call :GrantManageGroups "OU=Groups,%BaseOU%" "%Dom%\%Grp%"
call :GrantManageAccounts "OU=Resources,OU=Users,%BaseOU%" "%Dom%\%Grp%"
call :GrantManageAccounts "OU=Standard Users,OU=Users,%BaseOU%" "%Dom%\%Grp%"


::call :GrantManageAccounts "OU=Service Accounts,OU=Users,%BaseOU%" "%Dom%\%Grp%"
::call :GrantManageContacts "OU=Contacts,%BaseOU%" "%Dom%\%Grp%"
::call :GrantManageGroups "OU=Groups,%BaseOU%" "%Dom%\%Grp%"
::call :GrantManageGroups "OU=Users,%BaseOU%" "%Dom%\%Grp%"

::SET Grp=KPLP Account Admins
::call :RemovePermissions "OU=Users,%BaseOU%" "%Dom%\%Grp%"
::call :RemovePermissions "OU=Contacts,%BaseOU%" "%Dom%\%Grp%"
::call :RemovePermissions "OU=Groups,%BaseOU%" "%Dom%\%Grp%"
::call :RemovePermissions "OU=Users,%BaseOU%" "%Dom%\%Grp%"

::call :RemovePermissions "OU=Computers,%BaseOU%" "%Dom%\%Grp%" "%Dom%\%Grp%"

::call :GrantEditDescription "OU=Standard Users,OU=Users,%BaseOU%" "%Dom%\%Grp%"
::call :GrantEditEndDate "OU=Standard Users,OU=Users,%BaseOU%" "%Dom%\%Grp%"

::call :GrantManageContacts "OU=Contacts,%BaseOU%" "%Dom%\%Grp%"
::call :GrantManageGroups "OU=Groups,%BaseOU%" "%Dom%\%Grp%"
::call :GrantManageAccounts "OU=Resources,OU=Users,%BaseOU%" "%Dom%\%Grp%"
::call :GrantManageAccounts "OU=Standard Users,OU=Users,%BaseOU%" "%Dom%\%Grp%"


::SET Grp=%Prefix% Server Admins
::call :GrantManageComputers "OU=Computers,%BaseOU%" "%Dom%\%Grp%"
::call :GRantManageComputersBitlocker "OU=Computers,%BaseOU%" "%Dom%\%Grp%"
::call :GrantManageComputers "OU=Servers,%BaseOU%" "%Dom%\%Grp%"
::call :GrantManageContacts "OU=Contacts,%BaseOU%" "%Dom%\%Grp%"
::call :GrantManageGroups "OU=Groups,%BaseOU%" "%Dom%\%Grp%"
::call :GrantManageAccounts "OU=Resources,OU=Users,%BaseOU%" "%Dom%\%Grp%"
::call :GrantManageAccounts "OU=Standard Users,OU=Users,%BaseOU%" "%Dom%\%Grp%"

::SET Grp=%Prefix% Site Techs
::call :GrantManageComputers "OU=Computers,%BaseOU%" "%Dom%\%Grp%"
::call :GRantManageComputersBitlocker "OU=Computers,%BaseOU%" "%Dom%\%Grp%"
::call :GrantEditGroups "OU=Groups,%BaseOU%" "%Dom%\%Grp%"
::call :GrantResetPassword "OU=Standard Users,OU=Users,%BaseOU%" "%Dom%\%Grp%"

::SET Grp=%Prefix% Production Techs
::call :RemovePermissions "OU=Computers,%BaseOU%" "%Dom%\%Grp%"
::call :GrantManageComputers "OU=Production,OU=Computers,%BaseOU%" "%Dom%\%Grp%"
::call :GRantManageComputersBitlocker "OU=Production,OU=Computers,%BaseOU%" "%Dom%\%Grp%"

goto end

:GRantManageComputers
  REM the first argument is the OU
  REM the second argument is the User or Group
	dsacls "%~1" /I:T /G "%~2:CCDC;computer
	dsacls "%~1" /I:s /G "%~2:GA;;computer
Goto :EOF

:GRantManageComputersBitlocker
  REM the first argument is the OU
  REM the second argument is the User or Group
	dsacls "%~1" /I:s /G "%~2:GA;;msFVE-RecoveryInformation
Goto :EOF

:GrantManageContacts
  REM the first argument is the OU
  REM the second argument is the User or Group
	dsacls "%~1" /I:T /G "%~2:CCDC;contact"
	dsacls "%~1" /I:s /G "%~2:GA;;contact"
Goto :EOF


:GrantManageAccounts
  REM the first argument is the OU
  REM the second argument is the User or Group
	dsacls "%~1" /I:T /G "%~2:CCDC;user"
	dsacls "%~1" /I:s /G "%~2:GA;;user"
	dsacls "%~1" /I:T /G "%~2:CCDC;inetOrgPerson"
	dsacls "%~1" /I:s /G "%~2:GA;;inetOrgPerson"
Goto :EOF

:GrantManageGroups
  REM the first argument is the OU
  REM the second argument is the User or Group
	dsacls "%~1" /I:T /G "%~2:CCDC;group"
	dsacls "%~1" /I:s /G "%~2:GA;;group"
Goto :EOF

:GrantResetPassword
  REM the first argument is the OU
  REM the second argument is the User or Group
	dsacls "%~1" /I:s /G "%~2:rpwp;lockoutTime;user
	dsacls "%~1" /I:s /G "%~2:rpwp;pwdLastSet;user
	dsacls "%~1" /I:s /G "%~2:CA;Reset Password;user
Goto :EOF


:GrantEditGroups
  REM the first argument is the OU
  REM the second argument is the User or Group
	dsacls "%~1" /I:s /G "%~2:WP;member;group
Goto :EOF


:GrantFullControl
  REM the first argument is the OU
  REM the second argument is the User or Group
	dsacls "%~1" /I:s /G "%~2:GA
Goto :EOF

:RemovePermissions
  REM the first argument is the OU
  REM the second argument is the User or Group
	dsacls "%~1" /R "%~2
Goto :EOF

:GrantEditDescription
  REM the first argument is the OU
  REM the second argument is the User or Group
	dsacls "%~1" /I:s /G "%~2:rpwp;description;user
Goto :EOF

:GrantEditEndDate
  REM the first argument is the OU
  REM the second argument is the User or Group
	dsacls "%~1" /I:s /G "%~2:rpwp;accountexpires;user
Goto :EOF

:end


@echo Done Delegation for %OUName%
