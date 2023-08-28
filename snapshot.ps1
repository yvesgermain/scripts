<# 
.SYNOPSIS 
Crée un snapshot de l'AD.  Ouvre et saugegarde les fichiers NTDS.DIT avec logs pour utiliser avec DSAMAIN.EXE
.Description 
Ce script prend un snapshot du systemstate, ouvre le SystemState et extrait les fichiers sous Windows\NTDS et les copie sous c:\backup\[date-heure].  Puis il démonte le snapshot et efface tous les snashots.
Une fois le fichier NTDS.DIT sauvegardé avec ses logs, on utilise ESESNTUTL.exe pour réparer la base de données NTDS pour qu'elle soit prête à être utilisée avec DSAMAIN.exe
.EXAMPLE 
.\Snapshot.ps1
Cette commande sauvegardera sous c:\backup\[date_heure] le fichier NTDS.DIT avec ses logs. 
.EXAMPLE
.\Snapshot.ps1 -LeaveSnapshot
Cette commande sauvegardera sous c:\backup\[date_heure] le fichier NTDS.DIT avec ses logs.  Mais le ou les snapshots ne seront pas effacés.
.Notes 
        Créé par Yves Germain 
        Modifié:10 février 2013 
#> 
Param 
  ( 
    [parameter(Mandatory=$false)] 
    [switch]$LeaveSnapshot
  ) 
# Création du snapshot
$snap= ntdsutil snapshot 'Activate Instance ntds' create 'list all' quit quit 
$mount=$snap[($snap.count -4)].substring(9).trim() 

# On monte le snapshot
$Mount_Out=ntdsutil snapshot 'Activate Instance ntds' "mount $mount" 'list mounted' quit quit 
$dir =$Mount_Out[($mount_out.count -4)] 
# Le répertoire ou sera monté le snapshot est sauvegardé dans la variable $snap_dir
$snap_dir=$dir.substring($dir.lastindexof(' ') + 1) 
# On sauvegarde le répertoire d'où la commande a été lancé
Push-Location
# Le répertoire où on sauvegardera nos données sous c:\backup avec la date d'aujourd'hui
$dirName="c:\backup\$(get-date -format yyyy.MM.dd_hh.mm.ss)"
# on crée ce répertoire
mkdir $dirname 
# On copie nos données dans ce répertoire
xcopy $snap_dir\windows\ntds\*.* $dirName
Set-Location $dirName 
# Si la switch LeaveSnapshot à été utilisé, on n'efface pas les snapshots
if ($LeaveSnapshot) {ntdsutil snapshot 'activate instance ntds' 'unmount *' quit quit } else
	{ ntdsutil snapshot 'activate instance ntds' 'unmount *' 'delete *' quit quit }
# Réparation du fichier NTDS.DIT en utilisant ESENTUTL
esentutl /r edb 
esentutl /g ntds.dit 
esentutl /p ntds.dit /o 
# On retourne au répertoire original
Pop-Location