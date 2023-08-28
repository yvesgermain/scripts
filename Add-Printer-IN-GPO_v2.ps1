
########################################################################### Normal Printer adding to gpo #########################################################################################
$Inputlist = import-csv C:\temp\printersmaster.csv -delimiter ";"
#$e = import-csv C:\temp\test_prnt.csv -delimiter ";"
$FDRDatum = (Get-Date).tostring("yyyyMMdd")
# Provide Backup Folder path, the script will create a sub folder with current date.

$GPOBackupFDR = "C:\temp\$FDRDatum"

  $NewEntry = @()
        Backup-GPO "POC GPP Print Server HOSVPS02" -path $GPOBAckupFDR 
        # Provide the Network path of any DC to access the "Printer.xml" file. "Inly change the "\\DC01\d$\" as per your environment. Rest remains same.
        $GPP_PRT_XMLPath =  "\\hospdc01\D$\Windows\SYSVOL\sysvol\kruger.com\Policies\{6D8A0EEE-7DBA-40A6-9F54-C2FB378B9D03}\User\Preferences\Printers\Printers.xml"
        [XML]$PRNT = (Get-Content -Path $GPP_PRT_XMLPath) 
        
            foreach ($list in  $Inputlist)

                {
                 $CurrentDateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                 $newguid = [System.Guid]::NewGuid().toString()
                 $NewEntry = $PRNT.printers.SharedPrinter[1].Clone() 
                 $NewEntry.Name = $list.name
                 $NewEntry.Status = $list.name 
                 $NewEntry.Changed = "$CurrentDateTime"
                 $NewEntry.uid = "{" + "$newguid" + "}"
                 $NewEntry.userContext = $list.UserContext 
                 $NewEntry.properties.path = $list.Path
                 $NewEntry.properties.location = $list.location
                 $NewEntry.properties.action = $list.action
                 $NewEntry.filters.Filtergroup.Name = $list.GroupName 
                 $NewEntry.filters.Filtergroup.SID = $list.GroupSID 
                 $PRNT.DocumentElement.AppendChild($NewEntry) 
                    } 

            $PRNT.Save($GPP_PRT_XMLPath)
############################################################################ Default printer adding to gpo ################################################################################
$Inputlist = import-csv C:\temp\test_prnt.csv -delimiter ";"
#$e = import-csv C:\temp\test_prnt.csv -delimiter ";"
$FDRDatum = (Get-Date).tostring("yyyyMMdd")
# Provide Backup Folder path, the script will create a sub folder with current date.

$GPOBackupFDR = "C:\temp\$FDRDatum"

  $NewEntry = @()
        Backup-GPO "POC GPP Print Server HOSVPS02" -path $GPOBAckupFDR 
        # Provide the Network path of any DC to access the "Printer.xml" file. "Inly change the "\\DC01\d$\" as per your environment. Rest remains same.
        $GPP_PRT_XMLPath =  "\\hospdc01\D$\Windows\SYSVOL\sysvol\kruger.com\Policies\{6D8A0EEE-7DBA-40A6-9F54-C2FB378B9D03}\User\Preferences\Printers\Printers.xml"
        [XML]$PRNT = (Get-Content -Path $GPP_PRT_XMLPath) 
        
          foreach ($list in  $Inputlist)

                {
                 $CurrentDateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                 $newguid = [System.Guid]::NewGuid().toString()
                 $NewEntry = $PRNT.printers.SharedPrinter[2].Clone() 
                 $NewEntry.Name = $list.name
                 $NewEntry.Status = $list.name 
                 $NewEntry.Changed = "$CurrentDateTime"
                 $NewEntry.uid = "{" + "$newguid" + "}"
                 $NewEntry.userContext = $list.UserContext 
                 $NewEntry.properties.path = $list.Path
                 $NewEntry.properties.location = $list.location
                 $NewEntry.properties.action = $list.action
                 $NewEntry.filters.Filtergroup.Name = $list.GroupName_df 
                 $NewEntry.filters.Filtergroup.SID = $list.sid_df
                 $PRNT.DocumentElement.AppendChild($NewEntry) 
                    } 

            $PRNT.Save($GPP_PRT_XMLPath)
##########################################################################################################################################################################################
############################# Utility #################################################
$pr = import-csv C:\temp\test_prnt.csv -delimiter ";"
$name = "testjs123"

$grpsid  = @()
foreach($line in $pr){

$name = $line.groupname_df


try{

$grpsid += (Get-ADgroup $name -ErrorAction SilentlyContinue ).sid.value


}
catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]{

$grpsid += $name



}
}

##############################################################################################
