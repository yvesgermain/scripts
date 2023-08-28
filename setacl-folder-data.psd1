@{
    grsvfp01  =
    @( 
        @{    
            folder = "\groups\Serveur Richelieu (R)\AIM Project\" 
            ACL  = @(
                @{"Group" = "GRSVFP01_AimProject-RW"; "Perms" = @("Modify", "Synchronize") } , 
                @{"Group" = "GRSVFP01_AimProject-RO"; "Perms" = @("ReadAndExecute", "Synchronize") }
            )
        },
        @{
            folder = "\groups\Serveur Richelieu (R)\Qualité\"
            ACL  = @(
                @{"Group" = "GRSVFP01_Qualite-RW"  ; "Perms" = @("Modify", "Synchronize") } , 
                @{"Group" = "GRSVFP01_Qualite-RO"; "Perms" = @("ReadAndExecute", "Synchronize") }
            )
        }
    )
    GeneralData =
    @{
        server = "grsvfp01"
    }
}