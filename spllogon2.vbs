' ***********************************************************
' 
' Scott Paper Logon Script
' Version 1.4, Feb 9, 2006
' Version 1.5, Sept 27, 2023
' Original Script by Paul Wood, EDS
' Carl Steele, EDS
' 
' Maps Network drives based on network location
' 
' Version Change control
'	Version 1.1 to 1.x Updates for server consolidation projects
'		1.1 [Carl Steele] Montreal mappings updated, G: mapping added
'		1.2 [Carl Steele] Montreal S: removed, using G:
'		1.3 [Carl Steele] Calgary G: \\kpsvwts02\calgrp changed to X:
'		1.4 [Carl Steele] Lennoxville mappings updated, G: mapping added
'     1.5 [Yves Germain] Cleanup of bad subnet 
'
' ***********************************************************


Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objNetwork = WScript.CreateObject("WScript.Network")
Set objShell = WScript.CreateObject("WScript.Shell")
Dim os, SearchText,strIP
SearchText = "Windows 7"

Set objWMIService = GetObject("winmgmts:\\.\root\cimv2")
Set colItems = objWMIService.ExecQuery("Select * from Win32_ComputerSystem",,48)
Set colOperatingSystems = objWMIService.ExecQuery("Select * from Win32_OperatingSystem")

For Each objOperatingSystem in colOperatingSystems
    os = objOperatingSystem.Caption
Next

WScript.Echo "SPL Logon Script is running..."

'get username to map homedrive
UserName = objNetwork.UserName
          
Set objExecObject = objShell.Exec("%comspec% /c ipconfig.exe")
Do Until objExecObject.StdOut.AtEndOfStream
    strLine = objExecObject.StdOut.ReadLine()
	if InStr(1,os,SearchText) > 0 then
		strIP = Instr(strLine,"IPv4 Address")
	Else
		strIP = Instr(strLine,"Adresse IPv4")
	End if
    		
    If strIP <> 0 Then
       'find the ipadress in the strline, start my looking for ":" 
       ipaddress = Split(Mid(strLine, (InStr(strLine, ":") + 2)), ".")
       'determine the network address from the first three octets of the ip address
       network = ipaddress(0) & "." & ipaddress(1) & "." & ipaddress(2)
    End If
Loop

Select Case network

'    Case "199.175.174" '"Kruger Term Serv"  ' scrap YG
'   If the login script is run from the terminal server, exit script. 
'   A script local to the Term Server is run for these users called TSMapping.vbs
'        wscript.quit  ' scrap YG

'    Case "192.168.2" '"test site"   ' scrap YG
'    Wscript.Echo "Mapping Test Drives..." ' scrap YG
'    MapDrive "H:","\\192.168.2" & UserName & "$" ' scrap YG
'    MapDrive "G:","\\win2003\groups"  ' scrap YG
'    MapDrive "P:","\\win2003\public"  ' scrap YG
    
'    Case "199.175.173" '"Annacis Island"    ' scrap YG
'    Wscript.Echo "Mapping Annacis Island Drives..."  ' scrap YG
'    MapDrive "H:","\\splnwfp\" & UserName & "$"  ' scrap YG
'    MapDrive "P:","\\splnwfp\public"  ' scrap YG
    
'   Case "192.6.1" '"Calgary"    ' scrap YG
'   Wscript.Echo "Mapping Calgary Drives..."  ' scrap YG
'   MapDrive "H:","\\kpsvwts02\" & UserName & "$"  ' scrap YG
'   MapDrive "X:","\\kpsvwts02\calgrp"  ' scrap YG
'   MapDrive "P:","\\kpsvwts02\calpub"  ' scrap YG
        
'    MapDrive "H:","\\calgary\" & UserName & "$"
'    MapDrive "P:","\\calgary\public"
    
    Case "198.168.18" '"Crabtree"
    Wscript.Echo "Mapping Crabtree Drives..."
    MapDrive "H:","\\splnwfp\" & UserName & "$"
    MapDrive "G:","\\splctfp\groups"
    MapDrive "P:","\\splctfp\public"
    
'    If objFSO.FolderExists("C:\Program Files\msaver8") Then     ' scrap YG files don't exist
'       Wscript.Echo "Executing MainSaver Update...."     ' scrap YG files don't exist
'       objShell.Run "%comspec%  /c \\splctfp\public\mainsaver\kix32.exe \\splctfp\public\mainsaver\mainsaver.kix", 1, true     ' scrap YG files don't exist
'    End If      ' scrap YG files don't exist
   
    Case "10.50.1" '"Crabtree"
    Wscript.Echo "Mapping Crabtree Drives..."
    MapDrive "H:","\\splctfp\" & UserName & "$"
    MapDrive "G:","\\splctfp\groups"
    MapDrive "P:","\\splctfp\public"
        
'    If objFSO.FolderExists("C:\Program Files\msaver8") Then      ' scrap YG files don't exist
'       Wscript.Echo "Executing MainSaver Update...."     ' scrap YG files don't exist
'       objShell.Run "%comspec%  /c \\splctfp\public\mainsaver\kix32.exe \\splctfp\public\mainsaver\mainsaver.kix", 1, true     ' scrap YG files don't exist
'    End If        ' scrap YG files don't exist
    
    Case "10.50.0" '"Crabtree"
    Wscript.Echo "Mapping Crabtree Drives..."
    MapDrive "H:","\\splctfp\" & UserName & "$"
    MapDrive "G:","\\splctfp\groups"
    MapDrive "P:","\\splctfp\public"
            
'    If objFSO.FolderExists("C:\Program Files\msaver8") Then ' scrap YG files don't exist
'       Wscript.Echo "Executing MainSaver Update...."  ' scrap YG files don't exist
'       objShell.Run "%comspec%  /c \\splctfp\public\mainsaver\kix32.exe \\splctfp\public\mainsaver\mainsaver.kix", 1, true  ' scrap YG files don't exist
'    End If  ' scrap YG files don't exist
       
'    Case "199.175.171" '"Dartmouth"    ' scrap YG
'    Wscript.Echo "Mapping Dartmouth Drives..."  ' scrap YG
'    MapDrive "H:","\\kpsvwts02\" & UserName & "$"  ' scrap YG
'    MapDrive "P:","\\kpsvwts02\public"  ' scrap YG


    Case "199.175.175" '"Joliette"
    Wscript.Echo "Mapping Joliette Drives..."
    MapDrive "H:","\\splctfp\" & UserName & "$"
    MapDrive "G:","\\splctfp\groups"
    MapDrive "P:","\\splctfp\public"

    Case "198.168.19" '"Laurier"
    Wscript.Echo "Mapping Laurier Drives..."
    MapDrive "H:","\\spllafp\" & UserName & "$"
    MapDrive "G:","\\spllafp\groups"
    MapDrive "P:","\\spllafp\public"
    
    Case "199.175.170" '"Lennoxville"
    Wscript.Echo "Mapping Lennoxville Drives..."
    MapDrive "H:","\\kpsvwts02\" & UserName & "$"
    MapDrive "G:","\\kpsvwts02\lengrp"
    MapDrive "P:","\\kpsvwts02\lenpub"
    MapDrive "X:","\\kpsvwts02\lenapp"
    
'    MapDrive "H:","\\lennoxville\" & UserName & "$"
'    MapDrive "P:","\\lennoxville\public"

    Case "172.16.4" '"Memphis"
    Wscript.Echo "Mapping Memphis Drives..."
    MapDrive "P:","\\memfps\public"

    Case "10.78.1" '"Memphis2"
    Wscript.Echo "Mapping Memphis Drives..."
    MapDrive "P:","\\memfps\public"

    Case "10.77.230" '"MemphisVLAN101"
    Wscript.Echo "Mapping Memphis Drives..."
    MapDrive "P:","\\memfps\public"

    Case "10.77.231" '"MemphisVLAN102"
    Wscript.Echo "Mapping Memphis Drives..."
    MapDrive "P:","\\memfps\public"

    Case "10.77.234" '"MemphisVLAN60"
    Wscript.Echo "Mapping Memphis Drives..."
    MapDrive "P:","\\memfps\public"

    Case "10.77.241" '"MemphisVLAN40"
    Wscript.Echo "Mapping Memphis Drives..."
    MapDrive "P:","\\memfps\public"

    Case "10.77.242" '"MemphisVLAN50"
    Wscript.Echo "Mapping Memphis Drives..."
    MapDrive "P:","\\memfps\public"

'    Case "198.96.7" '"Mississauga"    ' scrap YG
'    Wscript.Echo "Mapping Mississauga Drives..."    ' scrap YG
'    MapDrive "H:","\\splmifp\" & UserName & "$"    ' scrap YG
'    MapDrive "G:","\\splmifp\groups"    ' scrap YG
'    MapDrive "P:","\\splmifp\public"    ' scrap YG

'    Case "199.175.172" '"Montreal"    ' scrap YG
'    Wscript.Echo "Mapping Montreal Drives..."    ' scrap YG
'    MapDrive "H:","\\kpsvwts02\" & UserName & "$"    ' scrap YG
'    MapDrive "G:","\\kpsvwts02\mongrp"    ' scrap YG
'    MapDrive "P:","\\kpsvwts02\monpub"    ' scrap YG
    
'    MapDrive "H:","\\montreal\" & UserName & "$"
'    MapDrive "P:","\\montreal\public"
'    MapDrive "S:","\\montreal\shared"
          
    Case "192.120.136"  '"New Westminster"
    Wscript.Echo "Mapping New Westminster Drives..."
    MapDrive "H:","\\splnwfp\" & UserName & "$"
    MapDrive "G:","\\splnwfp\groups"
    MapDrive "P:","\\splnwfp\public"
    
'        wscript.echo "Mapping Additional Group Drives..."      ' scrap YG Group doesn't exist
'        if isMember("NWFP_Fjord") then    ' scrap YG
'           wscript.echo "Mapping Fjord Drive..."    ' scrap YG
'           MapDrive "G:","\\splnwfp\fjord"    ' scrap YG
'        end if    ' scrap YG
        
'        if isMember("NWFP_Fjord_Read") then      ' scrap YG Group doesn't exist
'           wscript.echo "Mapping Fjord Drive..."    ' scrap YG
'           MapDrive "G:","\\splnwfp\fjord"    ' scrap YG
'        end if
        
        if isMember("NWFP_TDPayroll") then
           wscript.echo "Mapping TDPayroll Drive..."
           MapDrive "T:","\\splnwfp\TDPayroll"
        end if
        
'        if isMember("NWFP_RS500") then     ' scrap YG Group exists but drive doesn't
'           wscript.echo "Mapping RS500 Drive..."    ' scrap YG
'           MapDrive "K:","\\splnwfp\RS500"    ' scrap YG
'        end if    ' scrap YG

'       if isMember("WMD-SAP_DOC_GLB") then       ' scrap YG Group exists but drive doesn't
'          wscript.echo "Mapping WMD Drive..."     ' scrap YG Group exists but drive doesn't
'          MapDrive "W:","\\splctiso\WMD SAP PM Documents"     ' scrap YG Group exists but drive doesn't
'        end if     ' scrap YG Group exists but drive doesn't

'	if isMember("WMD_ConformIT_Procedures") then      ' scrap YG Group exists but drive doesn't
'          wscript.echo "Mapping WMD Drive..."    ' scrap YG
'          MapDrive "V:","\\splctiso\WMD ConformIT Procedure"    ' scrap YG
'        end if    ' scrap YG
    
'    Case "192.64.208" '"New Westminster"     ' scrap YG
'    Wscript.Echo "Mapping New Westminster Drives..."    ' scrap YG
'    MapDrive "H:","\\splnwfp\" & UserName & "$"    ' scrap YG
'    MapDrive "G:","\\splnwfp\groups"    ' scrap YG
'    MapDrive "P:","\\splnwfp\public"    ' scrap YG
    
'       wscript.echo "Mapping Additional Group Drives..."      ' scrap YG Group doesn't exist
'       if isMember("NWFP_Fjord") then    ' scrap YG
'          wscript.echo "Mapping Fjord Drive..."    ' scrap YG
'          MapDrive "G:","\\splnwfp\fjord"    ' scrap YG
'       end if    ' scrap YG
            
'       if isMember("NWFP_Fjord_Read") then NWFP_Fjord      ' scrap YG Group doesn't exist
'          wscript.echo "Mapping Fjord Drive..."    ' scrap YG
'          MapDrive "G:","\\splnwfp\fjord"    ' scrap YG
'       end if    ' scrap YG
            
       if isMember("NWFP_TDPayroll") then
          wscript.echo "Mapping TDPayroll Drive..."
          MapDrive "T:","\\splnwfp\TDPayroll"
       end if
            
'       if isMember("NWFP_RS500") then      ' scrap YG Group exists but drive doesn't
'          wscript.echo "Mapping RS500 Drive..."    ' scrap YG
'          MapDrive "K:","\\splnwfp\RS500"    ' scrap YG
'        end if    ' scrap YG

'       if isMember("WMD-SAP_DOC_GLB") then      ' scrap YG Group exists but drive doesn't
'          wscript.echo "Mapping WMD Drive..."    ' scrap YG
'          MapDrive "W:","\\splctiso\WMD SAP PM Documents"    ' scrap YG
'        end if    ' scrap YG

'	if isMember("WMD_ConformIT_Procedures") then       ' scrap YG Group exists but drive doesn't
'          wscript.echo "Mapping WMD Drive..."    ' scrap YG
'          MapDrive "V:","\\splctiso\WMD ConformIT Procedure"    ' scrap YG
'        end if    ' scrap YG



    Case "198.162.8" '"Richelieu"
    Wscript.Echo "Mapping Richelieu Drives..."
    MapDrive "H:","\\kplrifp\" & UserName & "$"
    MapDrive "G:","\\spllafp\groups"
    MapDrive "P:","\\spllafp\public"

End Select

'see if c:\eds folder exists
If objFSO.FolderExists("c:\eds") Then
Else
  Set objFolder = objFSO.CreateFolder("c:\eds")
End If
        
'create a file used for logging
WScript.Echo "Logging User & Computer Information..."
Set objFile=objFSO.CreateTextFile("c:\eds\" & username & "." & objNetwork.ComputerName & ".wslogging.txt")
objFile.Close
Set objFile = objFSO.OpenTextFile("c:\eds\" & username & "." & objNetwork.ComputerName & ".wslogging.txt", 8)
        

For Each objItem in colItems
   objFile.Write objNetwork.UserName & "," & objNetwork.ComputerName & "," & network & "," & objItem.Manufacturer & "," & trim(objItem.Model) & "," & now
Next
objFile.Close

'objFSO.CopyFile "c:\eds\" & username & "." & objNetwork.ComputerName & ".wslogging.txt" , "p:\edslogs\"

On Error Resume Next
'rename "default user.original" profile back to "default user"
If objFSO.FolderExists("C:\Documents and Settings\Default User.Original") Then 
   objFSO.MoveFolder "C:\Documents and Settings\Default User" , "C:\Documents and Settings\Default User.Migrated"
   objFSO.MoveFolder "C:\Documents and Settings\Default User.Original" , "C:\Documents and Settings\Default User"
End if


WScript.Quit

Function MapDrive(sDrive,sShare)
     On Error Resume Next
     objNetwork.RemoveNetworkDrive sDrive
     Err.Clear
     objNetwork.MapNetworkDrive sDrive,sShare
End Function

Function IsMember(sGroup)
   IsMember = False
   Set objGroup = GetObject("WinNT://spl/" & sGroup & ",group")
   For each objMember In objGroup.Members
     If LCase(objMember.AdsPath) = LCase("WinNT://spl/" & UserName) Then
       IsMember = True 
     End If    
   Next
End Function